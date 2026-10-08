param(
    [string]$Context = 'devops-homework',
    [string]$Flux = 'flux'
)
$ErrorActionPreference = 'Stop'
function Invoke-Recorded {
    param([string]$Program, [string[]]$Arguments)
    Write-Output ('$ ' + $Program + ' ' + ($Arguments -join ' '))
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed: $Program" }
}
Write-Output ('Captured at ' + (Get-Date).ToUniversalTime().ToString('o'))
Invoke-Recorded $Flux @('get', 'sources', 'git', '--context', $Context)
Invoke-Recorded $Flux @('get', 'kustomizations', '--context', $Context)
Invoke-Recorded 'kubectl' @('--context', $Context, '-n', 'devops-gitops', 'get', 'configmap', 'gitops-demo', '-o', 'yaml')

# Change only the disposable demo ConfigMap, not the Git source.
# Replace establishes kubectl's field ownership; Flux should still restore Git.
$demo = kubectl --context $Context -n devops-gitops get configmap gitops-demo -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Could not read demo ConfigMap' }
$demo.data.message = 'MANUAL DRIFT - should be reverted by Flux'
$patchPath = Join-Path ([IO.Path]::GetTempPath()) ('gitops-drift-' + [guid]::NewGuid().ToString('N') + '.json')
$demo | ConvertTo-Json -Depth 20 | Set-Content -Encoding utf8 -LiteralPath $patchPath
try {
    Write-Output '$ kubectl replace -f <temporary ConfigMap with manual drift>'
    kubectl --context $Context replace -f $patchPath
    if ($LASTEXITCODE -ne 0) { throw 'Drift injection failed' }
} finally {
    Remove-Item -LiteralPath $patchPath -Force
}
Invoke-Recorded 'kubectl' @('--context', $Context, '-n', 'devops-gitops', 'get', 'configmap', 'gitops-demo', '-o', 'jsonpath={.data.message}')
Write-Output ''
Write-Output 'Waiting for automatic reconciliation; no kubectl apply or manual flux reconcile is run.'
$deadline = (Get-Date).AddSeconds(90)
do {
    Start-Sleep -Seconds 5
    $value = kubectl --context $Context -n devops-gitops get configmap gitops-demo -o jsonpath='{.data.message}'
    if ($LASTEXITCODE -ne 0) { throw 'Could not query ConfigMap' }
    Write-Output ((Get-Date).ToUniversalTime().ToString('o') + ' observed message: ' + $value)
} until ($value -eq 'Git is the source of truth' -or (Get-Date) -gt $deadline)
if ($value -ne 'Git is the source of truth') { throw 'Flux did not restore the Git value before timeout' }
Invoke-Recorded $Flux @('get', 'kustomizations', '--context', $Context)
Invoke-Recorded 'kubectl' @('--context', $Context, '-n', 'flux-system', 'logs', 'deployment/kustomize-controller', '--since=3m', '--tail=30')
Write-Output 'PASS: Flux automatically corrected manual drift to the value in Git.'
