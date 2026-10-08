param(
    [string]$Context = 'devops-homework',
    [string]$Flux = 'flux'
)
$ErrorActionPreference = 'Stop'
& $Flux check --pre --context $Context
if ($LASTEXITCODE -ne 0) { throw 'Flux prerequisites failed' }
& $Flux install --context $Context --components=source-controller,kustomize-controller --version=v2.9.6 --timeout=5m
if ($LASTEXITCODE -ne 0) { throw 'Flux installation failed' }
kubectl --context $Context apply -f (Join-Path $PSScriptRoot 'source.yaml')
if ($LASTEXITCODE -ne 0) { throw 'Source creation failed' }
kubectl --context $Context apply -f (Join-Path $PSScriptRoot 'reconcile.yaml')
if ($LASTEXITCODE -ne 0) { throw 'Kustomization creation failed' }
& $Flux reconcile kustomization homework-demo --with-source --context $Context --timeout=3m
if ($LASTEXITCODE -ne 0) { throw 'Reconciliation failed; inspect the Git revision and desired path' }
