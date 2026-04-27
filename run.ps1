# run.ps1 - Script chay nhanh de test GUI (local)
# Chay: powershell -ExecutionPolicy Bypass -File run.ps1

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

. "$here\modules\logger.ps1"
Initialize-Log
. "$here\modules\installer.ps1"
. "$here\modules\activation.ps1"
. "$here\modules\optimizer.ps1"
. "$here\main.ps1"
