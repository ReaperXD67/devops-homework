param(
    [string]$Helm = 'helm',
    [string]$Context = 'devops-homework',
    [string]$ImageRepository = 'devops-final',
    [string]$ImageTag = 'local'
)
$ErrorActionPreference = 'Stop'
$labNamespace = 'devops-final-helm'
$evidenceDir = Join-Path $PSScriptRoot 'evidence'
New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
$logFile = Join-Path $evidenceDir 'deployment.txt'
@(
    'Actual final Helm deployment evidence',
    "UTC: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "Context: $Context; Namespace: $labNamespace",
    "Image: ${ImageRepository}:${ImageTag}; locally built and loaded into Minikube",
    'The runtime Secret value is never written to this log.'
) | Set-Content -LiteralPath $logFile -Encoding utf8

function Invoke-Recorded([string]$Label, [scriptblock]$Command) {
    Add-Content -LiteralPath $logFile -Value "`n> $Label" -Encoding utf8
    $captured = & $Command 2>&1
    $commandExit = $LASTEXITCODE
    $captured | Out-String | Add-Content -LiteralPath $logFile -Encoding utf8
    Add-Content -LiteralPath $logFile -Value "Exit code: $commandExit" -Encoding utf8
    $captured | Write-Output
    if ($commandExit -ne 0) { throw "$Label failed; see $logFile" }
}

Invoke-Recorded 'helm version --short' { & $Helm version --short }
Invoke-Recorded 'helm lint --strict' { & $Helm lint $PSScriptRoot --strict }
Invoke-Recorded "kubectl create namespace $labNamespace (idempotent apply)" {
    kubectl --context $Context create namespace $labNamespace --dry-run=client -o yaml | kubectl --context $Context apply -f -
}
$labSecretBytes = New-Object byte[] 32
$labRandom = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$labRandom.GetBytes($labSecretBytes)
$labRandom.Dispose()
$labSecretValue = [Convert]::ToBase64String($labSecretBytes)
Invoke-Recorded 'Create app-secret from a generated runtime token (value omitted)' {
    kubectl --context $Context -n $labNamespace create secret generic app-secret "--from-literal=token=$labSecretValue" --dry-run=client -o yaml | kubectl --context $Context apply -f -
}
$labSecretValue = $null
Invoke-Recorded 'helm upgrade --install final-app (APP_VERSION 1.0.0)' {
    & $Helm upgrade --install final-app $PSScriptRoot --namespace $labNamespace --kube-context $Context --set "image.repository=$ImageRepository" --set "image.tag=$ImageTag" --set-string appVersion=1.0.0 --wait --timeout 3m --atomic
}
Invoke-Recorded 'helm test final-app --logs' {
    & $Helm test final-app --namespace $labNamespace --kube-context $Context --logs --timeout 2m
}
Invoke-Recorded 'kubectl get deployment,pods,service' {
    kubectl --context $Context -n $labNamespace get deployment,pods,service -o wide
}
Invoke-Recorded 'HTTP /api/info through ClusterIP Service at version 1.0.0' {
    kubectl --context $Context -n $labNamespace exec deployment/final-app -- node -e 'require("http").get("http://final-app/api/info",r=>{r.pipe(process.stdout);r.on("end",()=>process.exit(r.statusCode===200?0:1));}).on("error",()=>process.exit(1))'
}
Invoke-Recorded 'helm upgrade final-app (APP_VERSION 1.1.0)' {
    & $Helm upgrade final-app $PSScriptRoot --namespace $labNamespace --kube-context $Context --reuse-values --set-string appVersion=1.1.0 --wait --timeout 3m --atomic
}
Invoke-Recorded 'HTTP /api/info after version 1.1.0 upgrade' {
    kubectl --context $Context -n $labNamespace exec deployment/final-app -- node -e 'require("http").get("http://final-app/api/info",r=>{r.pipe(process.stdout);r.on("end",()=>process.exit(r.statusCode===200?0:1));}).on("error",()=>process.exit(1))'
}
Invoke-Recorded 'helm rollback final-app 1' {
    & $Helm rollback final-app 1 --namespace $labNamespace --kube-context $Context --wait --timeout 3m
}
Invoke-Recorded 'HTTP /api/info after rollback to revision 1' {
    kubectl --context $Context -n $labNamespace exec deployment/final-app -- node -e 'require("http").get("http://final-app/api/info",r=>{r.pipe(process.stdout);r.on("end",()=>process.exit(r.statusCode===200?0:1));}).on("error",()=>process.exit(1))'
}
Invoke-Recorded 'helm history final-app' {
    & $Helm history final-app --namespace $labNamespace --kube-context $Context
}
Invoke-Recorded 'helm test final-app --logs after rollback' {
    & $Helm test final-app --namespace $labNamespace --kube-context $Context --logs --timeout 2m
}
Invoke-Recorded 'kubectl get deployment,pods,service after rollback' {
    kubectl --context $Context -n $labNamespace get deployment,pods,service
}
