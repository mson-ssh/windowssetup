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

# Download and extract
Write-Host "Downloading..." -ForegroundColor $c.Info -NoNewline
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing
    Write-Host " OK" -ForegroundColor $c.OK
    
    Write-Host "Extracting..." -ForegroundColor $c.Info -NoNewline
    Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force
    $repoRoot = Get-ChildItem $extractDir -Directory | Select-Object -First 1 -ExpandProperty FullName

    if (Test-Path (Join-Path $repoRoot 'run.ps1')) {
        $projectDir = $repoRoot
    } else {
        $projectDir = Join-Path $repoRoot 'winsetup-pro'
    }

    if (-not (Test-Path (Join-Path $projectDir 'run.ps1'))) {
        throw "run.ps1 not found in extracted project. Checked: $repoRoot and $projectDir"
    }
    Write-Host " OK" -ForegroundColor $c.OK
} catch {
    Write-Host " FAILED" -ForegroundColor $c.Error
    Write-Host "Error: $_" -ForegroundColor $c.Error
    exit 1
}

# Run
Write-Host "Launching GUI..." -ForegroundColor $c.Info
Set-Location $projectDir
$powershellExe = if (Get-Command 'powershell.exe' -ErrorAction SilentlyContinue) { 'powershell.exe' } else { 'pwsh.exe' }
& $powershellExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectDir 'run.ps1')

# Cleanup
Set-Location $env:TEMP
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
