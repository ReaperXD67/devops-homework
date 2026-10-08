$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
New-Item -ItemType Directory evidence -Force | Out-Null
Start-Transcript -Path evidence/run.txt -Force
docker compose up -d
if ($LASTEXITCODE -ne 0) { throw 'Monitoring startup failed' }
Start-Sleep -Seconds 15
foreach ($i in 1..10) { Invoke-RestMethod http://127.0.0.1:8200/healthz | ConvertTo-Json -Compress }
Write-Output 'Application metrics'
Write-Output (Invoke-WebRequest http://127.0.0.1:8200/metrics -UseBasicParsing).Content
Write-Output 'Prometheus targets'
(Invoke-RestMethod http://127.0.0.1:9090/api/v1/targets).data.activeTargets | Select-Object labels,health,scrapeUrl | Format-Table
Write-Output 'CPU rate and resident memory queries'
foreach ($q in @('rate(process_cpu_seconds_total{job="devops-app"}[1m])','process_resident_memory_bytes{job="devops-app"}','up{job="devops-app"}')) {
    Write-Output $q
    Invoke-RestMethod ('http://127.0.0.1:9090/api/v1/query?query=' + [uri]::EscapeDataString($q)) | ConvertTo-Json -Depth 10
}
docker compose logs --tail 12 app
docker compose stop app
Start-Sleep -Seconds 25
Write-Output 'Outage alert after stopping the application'
Invoke-RestMethod http://127.0.0.1:9090/api/v1/alerts | ConvertTo-Json -Depth 10
docker compose start app
Start-Sleep -Seconds 15
Write-Output 'Recovery alert state'
Invoke-RestMethod http://127.0.0.1:9090/api/v1/alerts | ConvertTo-Json -Depth 10
docker stats --no-stream $(docker compose ps -q)
Stop-Transcript
