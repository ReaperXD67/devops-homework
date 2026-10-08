param([string]$Context = "devops-homework")
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force evidence | Out-Null
Start-Transcript -Path evidence/run.txt -Force
function K { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ }; if ($LASTEXITCODE -ne 0) { throw "kubectl failed: $args" } }
function TryK { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ } }
K apply -f 01-rolling.yaml
K -n hw10 rollout status deployment/rolling --timeout=180s
Start-Sleep -Seconds 3
K -n hw10 set env deployment/rolling VERSION=rolling-v2
K -n hw10 get pods -o wide
K -n hw10 rollout status deployment/rolling --timeout=120s
Start-Sleep -Seconds 3
K -n hw10 get rs
K -n hw10 exec deployment/rolling '--' wget -qO- http://rolling
K apply -f 02-blue-green.yaml
K -n hw10 rollout status deployment/blue --timeout=120s
Start-Sleep -Seconds 3
K -n hw10 rollout status deployment/green --timeout=120s
Start-Sleep -Seconds 3
K -n hw10 exec deployment/blue '--' wget -qO- http://color
K -n hw10 patch service color --type=merge --patch-file green-patch.json
Start-Sleep -Seconds 3
K -n hw10 exec deployment/green '--' wget -qO- http://color
K apply -f 03-canary.yaml
K -n hw10 rollout status deployment/stable --timeout=120s
Start-Sleep -Seconds 3
K -n hw10 rollout status deployment/canary --timeout=120s
Start-Sleep -Seconds 3
K -n hw10 get endpointslices -l kubernetes.io/service-name=canary-demo -o wide
K -n hw10 exec deployment/stable '--' sh -c 'for i in $(seq 1 100); do wget -qO- http://canary-demo; done'
K apply -f 04-recreate.yaml
K -n hw10 rollout status deployment/recreate --timeout=120s
Start-Sleep -Seconds 3
K -n hw10 set env deployment/recreate VERSION=recreate-v2
K -n hw10 get pods -l app=recreate -o wide
K -n hw10 rollout status deployment/recreate --timeout=120s
Start-Sleep -Seconds 3
K -n hw10 describe deployment recreate
K -n hw10 get events --sort-by=.metadata.creationTimestamp
K apply -f 05-lifecycle.yaml
Start-Sleep -Seconds 8
K -n hw10 get pods -o wide
foreach ($pod in @('life-running','life-succeeded','life-failed','life-pending')) { K -n hw10 describe pod $pod }
K -n hw10 logs life-succeeded
K -n hw10 logs life-failed
K -n hw10 delete pod life-pending life-running

Stop-Transcript
