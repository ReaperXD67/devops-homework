param([string]$Context = "devops-homework")
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force evidence | Out-Null
Start-Transcript -Path evidence/run.txt -Force
function K { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ }; if ($LASTEXITCODE -ne 0) { throw "kubectl failed: $args" } }
function TryK { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ } }
K apply -f services.yaml
K -n hw11 rollout status deployment/web --timeout=120s
Start-Sleep -Seconds 3
K -n hw11 wait --for=condition=Ready pod/dns-client --timeout=120s
K -n hw11 get services -o wide
K -n hw11 get endpointslices -o wide
K -n hw11 exec dns-client '--' nslookup clusterip.hw11.svc.cluster.local
K -n hw11 exec dns-client '--' nslookup headless.hw11.svc.cluster.local
K -n hw11 exec dns-client '--' nslookup externalname.hw11.svc.cluster.local
K -n hw11 exec dns-client '--' wget -qO- http://clusterip
K -n hw11 exec dns-client '--' wget -qO- http://headless
K -n hw11 exec dns-client '--' wget -qO- http://loadbalancer
$nodeIP = & kubectl --context $Context get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'
$nodePort = & kubectl --context $Context -n hw11 get service nodeport -o jsonpath='{.spec.ports[0].nodePort}'
K -n hw11 exec dns-client '--' wget -qO- "http://${nodeIP}:$nodePort"
K -n hw11 exec dns-client '--' cat /etc/resolv.conf
K -n kube-system get pods -l k8s-app=kube-dns -o wide
K -n kube-system get configmap coredns -o yaml
K -n kube-system logs deployment/coredns --tail=15

Stop-Transcript
