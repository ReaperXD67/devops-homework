param([string]$Minikube = 'minikube')
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$context = 'devops-homework'
New-Item -ItemType Directory evidence -Force | Out-Null
Start-Transcript -Path evidence/run.txt -Force
& $Minikube -p $context image load devops-final:local
if ($LASTEXITCODE -ne 0) { throw 'Could not load the local image; check Minikube path/profile' }
kubectl --context $context apply -f namespace.yaml
# Random demonstration token generated in memory; do not echo or save the value.
$demoBytes = New-Object byte[] 24
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($demoBytes)
$demoToken = [Convert]::ToBase64String($demoBytes)
kubectl --context $context -n devops-final create secret generic app-secret --from-literal="token=$demoToken" --dry-run=client -o yaml | kubectl --context $context apply -f -
$demoToken = $null
kubectl --context $context apply -k .
kubectl --context $context -n devops-final set image deployment/devops-app app=devops-final:local
kubectl --context $context -n devops-final rollout status deployment/devops-app --timeout=120s
if ($LASTEXITCODE -ne 0) { throw 'Deployment not ready' }
kubectl --context $context -n devops-final get pods,svc,ingress,hpa -o wide
kubectl --context $context -n devops-final exec deployment/devops-app -- node -e "fetch('http://localhost:8080/api/info').then(r=>r.text()).then(console.log)"
kubectl --context $context -n devops-final exec deployment/devops-app -- node -e "console.log('Secret injection verified:', Boolean(process.env.DEMO_TOKEN))"
kubectl --context $context -n devops-final logs deployment/devops-app --tail=10
Stop-Transcript
