# logger.ps1 - Ghi log cho WinSetup Pro

$logDir  = 'C:\WinSetupPro\Logs'
$logPath = Join-Path $logDir ('setup_' + (Get-Date -Format 'yyyy-MM-dd') + '.log')

function Initialize-Log {
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Write-Host 'Ready to Install :)' -ForegroundColor Green
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logPath -Value $line
    Write-Host $line
}
