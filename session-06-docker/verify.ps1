$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
New-Item -ItemType Directory evidence -Force | Out-Null
Start-Transcript -Path evidence/run.txt -Force
docker compose build
if ($LASTEXITCODE -ne 0) { throw 'Image build failed' }
docker compose up -d
if ($LASTEXITCODE -ne 0) { throw 'Container startup failed' }
Start-Sleep -Seconds 3
docker compose ps
foreach ($port in 8101..8106) {
    Write-Output "GET http://localhost:$port"
    $response = Invoke-WebRequest "http://127.0.0.1:$port" -UseBasicParsing
    Write-Output "HTTP $($response.StatusCode)"
    Write-Output $response.Content
}
docker images --filter 'reference=devops-hello-*'
Stop-Transcript
