param([string]$Context = "devops-homework")
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force evidence | Out-Null
Start-Transcript -Path evidence/run.txt -Force
function K { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ }; if ($LASTEXITCODE -ne 0) { throw "kubectl failed: $args" } }
function TryK { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ } }
K cluster-info
K version
K get nodes -o wide
K get pods -n kube-system -o wide
K apply -f basics.yaml
K -n hw9 rollout status deployment/web --timeout=180s
Start-Sleep -Seconds 3
K -n hw9 get 'deployments,replicasets,pods,services' -o wide
K -n hw9 describe deployment web
K -n hw9 logs deployment/web --tail=10
K -n hw9 exec deployment/web '--' wget -qO- http://127.0.0.1
K -n hw9 scale deployment web --replicas=3
K -n hw9 rollout status deployment/web --timeout=120s
Start-Sleep -Seconds 3
K -n hw9 get pods
K -n hw9 set env deployment/web VERSION="Hello Kubernetes v2"
K -n hw9 rollout status deployment/web --timeout=120s
Start-Sleep -Seconds 3
K -n hw9 rollout history deployment/web
K -n hw9 exec deployment/web '--' wget -qO- http://web.hw9.svc.cluster.local
K -n hw9 rollout undo deployment/web
K -n hw9 rollout status deployment/web --timeout=120s
Start-Sleep -Seconds 3
K -n hw9 exec deployment/web '--' wget -qO- http://web
K -n hw9 scale deployment web --replicas=1

Stop-Transcript
