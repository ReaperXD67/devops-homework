param([string]$Context = "devops-homework")
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force evidence | Out-Null
Start-Transcript -Path evidence/run.txt -Force
function K { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ }; if ($LASTEXITCODE -ne 0) { throw "kubectl failed: $args" } }
function TryK { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ } }
TryK -n hw14 delete pod crash bad-image pending bad-dns missing-volume bad-config --ignore-not-found
TryK -n hw14 delete configmap missing-config --ignore-not-found
K apply -f broken.yaml
K -n hw14 rollout status deployment/web --timeout=120s
Start-Sleep -Seconds 3
Start-Sleep -Seconds 35
K -n hw14 get pods -o wide
foreach ($pod in @('crash','bad-image','pending','missing-volume','bad-config','bad-dns')) { K -n hw14 describe pod $pod }
TryK -n hw14 logs crash --previous
K -n hw14 events
K explain pod.spec.containers.resources
TryK -n hw14 top pods
K -n hw14 get 'svc,endpointslices' -o wide
TryK -n hw14 exec deployment/web '--' wget -T 3 -qO- http://web
TryK -n hw14 exec bad-dns '--' nslookup kubernetes.default.svc.cluster.local
K -n hw14 exec bad-dns '--' cat /etc/resolv.conf
K -n hw14 exec deployment/web '--' wget -qO- http://127.0.0.1
# Direct Pod IP works even while the Service selector is wrong.
$podIP = & kubectl --context $Context -n hw14 get pods -l app=web -o jsonpath='{.items[0].status.podIP}'
K -n hw14 exec bad-dns '--' wget -T 3 -qO- "http://$podIP"
# A wrong port reproduces a Pod connectivity failure without breaking the node network.
TryK -n hw14 exec bad-dns '--' wget -T 3 -qO- "http://${podIP}:81"
K -n hw14 delete pod crash bad-image pending bad-dns
K apply -f fixed.yaml
K -n hw14 wait --for=condition=Ready pod --all --timeout=180s
K -n hw14 get 'pods,svc,endpointslices' -o wide
K -n hw14 logs crash
K -n hw14 exec bad-config '--' printenv APP_ENV
K -n hw14 exec bad-dns '--' nslookup web.hw14.svc.cluster.local
K -n hw14 exec bad-dns '--' wget -qO- http://web
K -n hw14 exec bad-dns '--' wget -qO- "http://${podIP}:80"
K -n hw14 events

Stop-Transcript
