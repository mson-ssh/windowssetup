# install.ps1 - WinSetup Pro Installer
# Usage: irm https://raw.githubusercontent.com/mson-ssh/windowssetup/main/install.ps1 | iex

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# Colors
$c = @{
    Info  = 'Cyan'
    OK    = 'Green'
    Warn  = 'Yellow'
    Error = 'Red'
}

Write-Host "`n=== WinSetup Pro Installer ===" -ForegroundColor $c.Info
Write-Host "Downloading and extracting..." -ForegroundColor $c.Info

# URLs
$repoUrl = 'https://github.com/mson-ssh/windowssetup'
$zipUrl  = "$repoUrl/archive/refs/heads/main.zip"
$tempDir = Join-Path $env:TEMP 'WinSetupPro'
$zipFile = Join-Path $tempDir 'winsetup.zip'
$extractDir = Join-Path $tempDir 'extracted'

# Clean up old files
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Download ZIP
Write-Host "> Downloading from GitHub..." -ForegroundColor $c.Info
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing
    Write-Host "  [OK] Downloaded: $('{0:N2}' -f ((Get-Item $zipFile).Length / 1MB)) MB" -ForegroundColor $c.OK
} catch {
    Write-Host "  [ERROR] Failed to download: $_" -ForegroundColor $c.Error
    exit 1
}

# Extract ZIP
Write-Host "> Extracting archive..." -ForegroundColor $c.Info
try {
    Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force
    $projectDir = Get-ChildItem $extractDir -Directory | Select-Object -First 1 -ExpandProperty FullName
    Write-Host "  [OK] Extracted to: $projectDir" -ForegroundColor $c.OK
} catch {
    Write-Host "  [ERROR] Failed to extract: $_" -ForegroundColor $c.Error
    exit 1
}

# Run the main script
Write-Host "> Launching WinSetup Pro..." -ForegroundColor $c.Info
Set-Location $projectDir
& "$projectDir\run.ps1"

# Cleanup
Write-Host "`n> Cleaning up temporary files..." -ForegroundColor $c.Info
Set-Location $env:TEMP
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] Done!`n" -ForegroundColor $c.OK
