param([string]$Context = "devops-homework")
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force evidence | Out-Null
Start-Transcript -Path evidence/run.txt -Force
function K { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ }; if ($LASTEXITCODE -ne 0) { throw "kubectl failed: $args" } }
function TryK { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ } }
K apply -f configmap.yaml
# Generate a disposable lab token. Never echo or write it to the transcript.
$token = [guid]::NewGuid().ToString('N')
& kubectl --context $Context -n hw12 create secret generic demo-secret --from-literal="DEMO_TOKEN=$token" --dry-run=client -o yaml | & kubectl --context $Context apply -f -
if ($LASTEXITCODE -ne 0) { throw "Could not create lab Secret" }
K apply -f app.yaml
K -n hw12 rollout restart deployment/web
K apply -f ingress.yaml
K -n hw12 rollout status deployment/web --timeout=120s
Start-Sleep -Seconds 3
K -n hw12 exec deployment/web '--' printenv APP_ENV WELCOME
$actual = & kubectl --context $Context -n hw12 exec deployment/web '--' printenv DEMO_TOKEN
if ($actual -ne $token) { throw "Secret environment injection failed" }
Write-Host "Secret injection verified: runtime value matches; value redacted."
$token=$null; $actual=$null
Start-Sleep -Seconds 5
K -n hw12 get 'ingress,svc,pods'
K -n hw12 exec deployment/web '--' wget -qO- --header=Host:homework.local http://ingress-nginx-controller.ingress-nginx.svc.cluster.local
Write-Host "Injecting broken Service targetPort 81"
K -n hw12 patch service web --type=merge --patch-file broken-port.json
TryK -n hw12 exec deployment/web '--' wget -T 3 -qO- http://web
K -n hw12 describe service web
K -n hw12 get endpointslices -o wide
K -n hw12 exec deployment/web '--' wget -qO- http://127.0.0.1:80
K apply -f app.yaml
Start-Sleep -Seconds 3
K -n hw12 exec deployment/web '--' wget -qO- http://web
K -n hw12 exec deployment/web '--' wget -qO- --header=Host:homework.local http://ingress-nginx-controller.ingress-nginx.svc.cluster.local

Stop-Transcript
