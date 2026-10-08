param([string]$Context = "devops-homework")
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force evidence | Out-Null
Start-Transcript -Path evidence/run.txt -Force
function K { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ }; if ($LASTEXITCODE -ne 0) { throw "kubectl failed: $args" } }
function TryK { Write-Host ("$ kubectl --context " + $Context + " " + ($args -join " ")); & kubectl --context $Context @args 2>&1 | ForEach-Object { Write-Host $_ } }
K apply -f volumes.yaml
K -n hw13 wait --for=condition=Ready pod/volume-demo --timeout=120s
K -n hw13 get pvc
K get 'pv,storageclasses'
K -n hw13 exec volume-demo '--' cat /data/proof.txt /scratch/proof.txt
K -n hw13 exec volume-demo '--' sh -c 'echo survives-pod-deletion > /data/sentinel.txt'
K -n hw13 delete pod volume-demo
K apply -f volumes.yaml
K -n hw13 wait --for=condition=Ready pod/volume-demo --timeout=120s
K -n hw13 exec volume-demo '--' cat /data/sentinel.txt
K apply -f hostpath.yaml
Start-Sleep -Seconds 5
K -n hw13 logs hostpath-demo
K apply -f hpa.yml
K -n hw13 rollout status deployment/php-apache --timeout=180s
Start-Sleep -Seconds 3
K -n hw13 get hpa
K apply -f load-generator.yaml
for ($i=0; $i -lt 12; $i++) {
  Start-Sleep -Seconds 15
  K -n hw13 get hpa
  K -n hw13 get pods
  TryK -n hw13 top pods
}
$peak = & kubectl --context $Context -n hw13 get deployment php-apache -o jsonpath='{.spec.replicas}'
if ([int]$peak -lt 2) { throw 'Expected HPA to scale above one replica under load' }
Write-Host "Verified HPA scale-up: $peak replicas"
K -n hw13 describe hpa php-apache
K -n hw13 describe deployment php-apache
K -n hw13 delete pod load-generator --ignore-not-found
for ($i=0; $i -lt 16; $i++) {
  Start-Sleep -Seconds 15; K -n hw13 get hpa
  $current = & kubectl --context $Context -n hw13 get deployment php-apache -o jsonpath='{.spec.replicas}'
  if ([int]$current -eq 1) { break }
}
if ([int]$current -ne 1) { throw 'HPA did not scale down to one within the observation window' }
K -n hw13 get pods
K -n hw13 describe hpa php-apache
K -n hw13 rollout status deployment/php-apache --timeout=120s
Start-Sleep -Seconds 20
K -n hw13 get hpa
K -n hw13 get deployment php-apache
Write-Host 'Verified HPA scale-down to one replica after load removal'

Stop-Transcript
