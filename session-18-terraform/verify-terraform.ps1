param([string]$Terraform = 'terraform')
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$projects = @(
    @{ Path = 'session-18-terraform/terraform-s3-demo'; Log = 'session-18-terraform/evidence/validation.txt' },
    @{ Path = 'session-19-cloud'; Log = 'session-19-cloud/evidence/validation.txt' },
    @{ Path = 'session-19-cloud/modules/infrastructure'; Log = 'session-19-cloud/evidence/module-validation.txt' },
    @{ Path = 'final-devops-project/terraform'; Log = 'final-devops-project/terraform/evidence/validation.txt' }
)
foreach ($project in $projects) {
    $projectPath = Join-Path $repoRoot $project.Path
    $logPath = Join-Path $repoRoot $project.Log
    New-Item -ItemType Directory -Path (Split-Path -Parent $logPath) -Force | Out-Null
    @(
        'Terraform local validation: actual captured command output',
        "Project: $($project.Path)",
        "UTC: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))",
        'AWS execution: NONE. terraform test uses mock_provider aws.',
        ''
    ) | Set-Content -LiteralPath $logPath -Encoding utf8
    foreach ($arguments in @(@('version'), @('init', '-no-color'), @('fmt', '-check', '-recursive'), @('validate', '-no-color'), @('test', '-no-color'))) {
        $commandDisplay = "terraform $($arguments -join ' ')"
        Add-Content -LiteralPath $logPath -Value "> $commandDisplay" -Encoding utf8
        $captured = & $Terraform "-chdir=$projectPath" @arguments 2>&1
        $commandExit = $LASTEXITCODE
        $captured | Out-String | Add-Content -LiteralPath $logPath -Encoding utf8
        Add-Content -LiteralPath $logPath -Value "Exit code: $commandExit`n" -Encoding utf8
        Write-Output "$($project.Path): $commandDisplay => $commandExit"
        if ($commandExit -ne 0) { throw "Validation failed. See $logPath" }
    }
}
