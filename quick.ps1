# quick.ps1 - WinSetup Pro Quick Launcher
# Usage: & ([scriptblock]::Create((irm "https://raw.githubusercontent.com/mson-ssh/windowssetup/main/quick.ps1")))

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host "`n=== WinSetup Pro ===" -ForegroundColor Cyan
Write-Host "Loading modules from GitHub..." -ForegroundColor Cyan

# Base URL
$base = 'https://raw.githubusercontent.com/mson-ssh/windowssetup/main'

# Load modules directly into memory
try {
    . ([scriptblock]::Create((irm "$base/modules/logger.ps1")))
    . ([scriptblock]::Create((irm "$base/modules/installer.ps1")))
    . ([scriptblock]::Create((irm "$base/modules/activation.ps1")))
    . ([scriptblock]::Create((irm "$base/modules/optimizer.ps1")))
    
    # Initialize logger
    Initialize-Log
    Write-Log 'WinSetup Pro started (quick mode)'
    
    # Load and execute main GUI
    . ([scriptblock]::Create((irm "$base/main.ps1")))
    
} catch {
    Write-Host "[ERROR] Failed to load: $_" -ForegroundColor Red
    exit 1
}
