# setup.ps1 - Entry point cua WinSetup Pro
# Nguoi dung chay: irm https://raw.githubusercontent.com/<user>/winsetup-pro/main/setup.ps1 | iex

#region --- Kiem tra quyen Admin ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '[!] Can quyen Administrator. Dang khoi dong lai...' -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
#endregion

#region --- Set Execution Policy cho session nay ---
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
#endregion

#region --- Kiem tra ket noi Internet ---
Write-Host '[*] Kiem tra ket noi Internet...' -ForegroundColor Cyan
if (-not (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet)) {
    Write-Host '[!] Khong co ket noi Internet. Vui long kiem tra lai.' -ForegroundColor Red
    exit 1
}
Write-Host '[OK] Ket noi Internet: OK' -ForegroundColor Green
#endregion

#region --- Tai modules tu GitHub vao RAM ---
$baseUrl = 'https://raw.githubusercontent.com/<user>/winsetup-pro/main'

# Khi chay local (test), load tu duong dan tuong doi
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($scriptDir -and (Test-Path (Join-Path $scriptDir 'modules\logger.ps1'))) {
    Write-Host '[*] Che do LOCAL: Load modules tu dia...' -ForegroundColor Magenta
    . (Join-Path $scriptDir 'modules\logger.ps1')
    . (Join-Path $scriptDir 'modules\installer.ps1')
    . (Join-Path $scriptDir 'modules\activation.ps1')
    . (Join-Path $scriptDir 'modules\optimizer.ps1')
} else {
    Write-Host '[*] Che do ONLINE: Tai modules tu GitHub...' -ForegroundColor Cyan
    Invoke-Expression (Invoke-RestMethod "$baseUrl/modules/logger.ps1")
    Invoke-Expression (Invoke-RestMethod "$baseUrl/modules/installer.ps1")
    Invoke-Expression (Invoke-RestMethod "$baseUrl/modules/activation.ps1")
    Invoke-Expression (Invoke-RestMethod "$baseUrl/modules/optimizer.ps1")
}
#endregion

#region --- Khoi dong ---
Initialize-Log
Write-Log 'setup.ps1 da load xong tat ca modules'

# Load va chay main.ps1
$mainPath = Join-Path $scriptDir 'main.ps1'
if (Test-Path $mainPath) {
    . $mainPath
} else {
    Invoke-Expression (Invoke-RestMethod "$baseUrl/main.ps1")
}
#endregion
