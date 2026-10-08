param([string]$Context = 'devops-homework', [string]$Namespace = 'devops-final')
$ErrorActionPreference = 'Stop'
$baseArgs = @('--context', $Context, '-n', $Namespace)
function Invoke-K {
    param([string[]]$Arguments, [switch]$AllowFailure)
    Write-Output ('$ kubectl ' + (($baseArgs + $Arguments) -join ' '))
    & kubectl @baseArgs @Arguments 2>&1 | ForEach-Object { Write-Output "$_" }
    $exitCode = $LASTEXITCODE
    Write-Output "[exit status: $exitCode]"
    if ($exitCode -ne 0 -and -not $AllowFailure) { throw 'kubectl command failed' }
}
function Set-JsonPatch {
    param([string]$Kind, [object[]]$Operations)
    $patchFile = Join-Path ([IO.Path]::GetTempPath()) ('devops-drill-' + [guid]::NewGuid().ToString('N') + '.json')
    $patchJson = ConvertTo-Json -InputObject @($Operations) -Depth 30 -Compress
    Write-Output ('Patch: ' + $patchJson)
    [IO.File]::WriteAllText($patchFile, $patchJson)
    try {
        Invoke-K @('patch', $Kind, 'devops-app', '--type=json', '--patch-file', $patchFile)
    } finally {
        Remove-Item -LiteralPath $patchFile -Force
    }
}
function Show-ServiceRequest {
    param([switch]$AllowFailure)
    $js = "fetch('http://devops-app/healthz',{signal:AbortSignal.timeout(5000)}).then(async r=>{console.log('HTTP '+r.status);console.log(await r.text());if(!r.ok)process.exitCode=1}).catch(e=>{console.error(e.message);console.error(e.cause?.code||'');process.exitCode=1})"
    Invoke-K -Arguments @('exec', 'deployment/devops-app', '--', 'node', '-e', $js) -AllowFailure:$AllowFailure
}

Write-Output ('Captured at ' + (Get-Date).ToUniversalTime().ToString('o'))
$originalDeployment = & kubectl @baseArgs get deployment devops-app -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Could not read initial deployment' }
$originalService = & kubectl @baseArgs get service devops-app -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Could not read initial service' }
$originalImage = $originalDeployment.spec.template.spec.containers[0].image
$originalProbe = $originalDeployment.spec.template.spec.containers[0].readinessProbe
$originalSelector = $originalService.spec.selector

try {
    Write-Output '=== BASELINE ==='
    Invoke-K @('get', 'deployment,service,pods', '-o', 'wide')
    Show-ServiceRequest

    Write-Output '=== DRILL 1: NONEXISTENT CONTAINER IMAGE ==='
    Set-JsonPatch 'deployment' @(@{op='replace'; path='/spec/template/spec/containers/0/image'; value='ghcr.io/reaperxd67/devops-homework:nonexistent-troubleshooting-drill'})
    Invoke-K -Arguments @('rollout', 'status', 'deployment/devops-app', '--timeout=35s') -AllowFailure
    Invoke-K @('get', 'pods', '-o', 'wide')
    $pods = & kubectl @baseArgs get pods -l app=devops-app -o json | ConvertFrom-Json
    $badImagePod = @($pods.items | Where-Object { $_.spec.containers[0].image -like '*nonexistent-troubleshooting-drill' })[0].metadata.name
    if (-not $badImagePod) { throw 'No pod was created for the image drill' }
    Invoke-K @('describe', 'pod', $badImagePod)
    Invoke-K @('events', '--for', "pod/$badImagePod")
    Write-Output 'FIX: restore the original, previously healthy image.'
    Set-JsonPatch 'deployment' @(@{op='replace'; path='/spec/template/spec/containers/0/image'; value=$originalImage})
    Invoke-K @('rollout', 'status', 'deployment/devops-app', '--timeout=90s')
    Show-ServiceRequest

    Write-Output '=== DRILL 2: SERVICE SELECTOR MISMATCH ==='
    Set-JsonPatch 'service' @(@{op='replace'; path='/spec/selector'; value=@{app='intentionally-unmatched-drill'}})
    Start-Sleep -Seconds 3
    Invoke-K @('describe', 'service', 'devops-app')
    Invoke-K @('get', 'pods', '--show-labels')
    Invoke-K @('get', 'endpointslices', '-l', 'kubernetes.io/service-name=devops-app', '-o', 'yaml')
    Show-ServiceRequest -AllowFailure
    Write-Output 'FIX: restore the Service selector to match the Pod label.'
    Set-JsonPatch 'service' @(@{op='replace'; path='/spec/selector'; value=$originalSelector})
    Start-Sleep -Seconds 3
    Invoke-K @('get', 'endpointslices', '-l', 'kubernetes.io/service-name=devops-app', '-o', 'wide')
    Show-ServiceRequest

    Write-Output '=== DRILL 3: INCORRECT READINESS PROBE ==='
    Set-JsonPatch 'deployment' @(
        @{op='replace'; path='/spec/template/spec/containers/0/readinessProbe/httpGet/path'; value='/missing-readiness-drill'},
        @{op='replace'; path='/spec/template/spec/containers/0/readinessProbe/periodSeconds'; value=2},
        @{op='replace'; path='/spec/template/spec/containers/0/readinessProbe/failureThreshold'; value=1}
    )
    Invoke-K -Arguments @('rollout', 'status', 'deployment/devops-app', '--timeout=30s') -AllowFailure
    Invoke-K @('get', 'pods', '-o', 'wide')
    $pods = & kubectl @baseArgs get pods -l app=devops-app -o json | ConvertFrom-Json
    $badProbePod = @($pods.items | Where-Object { $_.spec.containers[0].readinessProbe.httpGet.path -eq '/missing-readiness-drill' })[0].metadata.name
    if (-not $badProbePod) { throw 'No pod was created for the probe drill' }
    Invoke-K @('describe', 'pod', $badProbePod)
    Invoke-K @('logs', $badProbePod, '--tail=15')
    Invoke-K @('events', '--for', "pod/$badProbePod")
    Write-Output 'FIX: restore the original /readyz readiness probe and timings.'
    Set-JsonPatch 'deployment' @(@{op='replace'; path='/spec/template/spec/containers/0/readinessProbe'; value=$originalProbe})
    Invoke-K @('rollout', 'status', 'deployment/devops-app', '--timeout=90s')
    Show-ServiceRequest
    Write-Output 'PASS: all three faults were diagnosed, repaired, and verified.'
} finally {
    Write-Output '=== FINAL RESTORATION (also runs on an error) ==='
    Set-JsonPatch 'service' @(@{op='replace'; path='/spec/selector'; value=$originalSelector})
    Set-JsonPatch 'deployment' @(
        @{op='replace'; path='/spec/template/spec/containers/0/image'; value=$originalImage},
        @{op='replace'; path='/spec/template/spec/containers/0/readinessProbe'; value=$originalProbe}
    )
    Invoke-K @('rollout', 'status', 'deployment/devops-app', '--timeout=90s')
    Invoke-K @('get', 'deployment,pods', '-o', 'wide')
    Show-ServiceRequest
}
Invoke-K @('exec', 'deployment/devops-app', '--', 'node', '-e', "fetch('http://devops-app/api/info').then(async r=>{console.log('HTTP '+r.status);console.log(await r.text());if(!r.ok)process.exitCode=1})")
