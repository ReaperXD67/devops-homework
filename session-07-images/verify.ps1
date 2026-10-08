$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
New-Item -ItemType Directory evidence -Force | Out-Null
Start-Transcript -Path evidence/run.txt -Force
docker build -t devops-multistage:1 .
if ($LASTEXITCODE -ne 0) { throw 'Image build failed' }
docker run -d --name devops-multistage -p 127.0.0.2:8080:8080 devops-multistage:1
if ($LASTEXITCODE -ne 0) { throw 'Container startup failed' }
Start-Sleep -Seconds 2
docker ps --filter name=devops-multistage
Write-Output (Invoke-WebRequest http://127.0.0.2:8080 -UseBasicParsing).Content
docker image inspect devops-multistage:1 --format 'Final image size: {{.Size}} bytes; user: {{.Config.User}}'
docker history devops-multistage:1
docker compose -f ../session-06-docker/compose.yaml ps nodejs python java
Stop-Transcript
