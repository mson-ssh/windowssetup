# run.ps1 - Quick launch script for local testing
# Usage: powershell -ExecutionPolicy Bypass -File run.ps1

#Requires -RunAsAdministrator

# Set execution policy to bypass
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

. "$here\modules\logger.ps1"
Initialize-Log
. "$here\modules\installer.ps1"
. "$here\modules\activation.ps1"
. "$here\modules\optimizer.ps1"
. "$here\main.ps1"
