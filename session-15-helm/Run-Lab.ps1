param([string]$Context="devops-homework", [string]$Helm="helm")
$ErrorActionPreference="Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force evidence | Out-Null
Start-Transcript -Path evidence/run.txt -Force
function RunHelm { Write-Host ("$ helm --kube-context " + $Context + " " + ($args -join " ")); & $Helm --kube-context $Context @args 2>&1 | ForEach-Object { Write-Host $_ }; if ($LASTEXITCODE -ne 0) { throw "helm failed: $args" } }
function K { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ }; if ($LASTEXITCODE -ne 0) { throw "kubectl failed: $args" } }
RunHelm version --short
$scaffold=Join-Path $env:TEMP ("helm-homework-scaffold-"+[guid]::NewGuid().ToString('N'))
RunHelm create $scaffold
RunHelm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
RunHelm repo update
RunHelm repo list
RunHelm search repo prometheus-community/prometheus
RunHelm lint ./chart
RunHelm template homework ./chart --namespace hw15
RunHelm install homework ./chart --namespace hw15 --create-namespace --wait --timeout 180s
RunHelm list --namespace hw15
RunHelm status homework --namespace hw15
RunHelm get all homework --namespace hw15
K -n hw15 exec deployment/homework '--' wget -qO- http://homework
RunHelm upgrade homework ./chart --namespace hw15 -f values-v2.yaml --wait --timeout 180s
K -n hw15 get pods
K -n hw15 exec deployment/homework '--' wget -qO- http://homework
RunHelm upgrade homework ./chart --namespace hw15 -f values-v3.yaml --wait --timeout 180s
K -n hw15 exec deployment/homework '--' wget -qO- http://homework
RunHelm history homework --namespace hw15
RunHelm rollback homework 1 --namespace hw15 --wait --timeout 180s
RunHelm history homework --namespace hw15
RunHelm get values homework --namespace hw15 --all
K -n hw15 get 'deployment,pods,svc'
K -n hw15 exec deployment/homework '--' wget -qO- http://homework
RunHelm uninstall homework --namespace hw15 --wait
RunHelm list --namespace hw15
K -n hw15 wait --for=delete pod -l app.kubernetes.io/instance=homework --timeout=60s
K -n hw15 get 'deployments,services,pods'
Stop-Transcript
