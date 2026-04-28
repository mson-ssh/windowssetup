# installer.ps1 - Install software via URL -> winget -> choco -> scoop
#
# INSTALL LOGIC (priority order):
# 1. URL    - Download from official source, run silent installer
# 2. winget - Windows Package Manager (Win10 1809+)
# 3. choco  - Chocolatey
# 4. scoop  - Scoop (auto-install if needed)
# Special: type=zip -> extract to %LOCALAPPDATA%\Programs\

function Get-PackageManager {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return 'winget' }
    if (Get-Command choco  -ErrorAction SilentlyContinue) { return 'choco'  }
    Write-Log 'winget/choco not found. Installing Scoop...' 'WARN'
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    return 'scoop'
}

function Get-AppList {
    param([string]$ConfigPath)
    if (-not (Test-Path $ConfigPath)) {
        Write-Log "apps.json not found: $ConfigPath" 'ERROR'
        return @()
    }
    $json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    return $json.groups
}

# --- Install via URL ---
function Install-ViaUrl {
    param($App)
    $url  = $App.url
    $args = $App.args
    $type = $App.type

    # Get filename from URL
    $fileName = [System.IO.Path]::GetFileName(([uri]$url).LocalPath)
    if (-not $fileName -or $fileName -eq '') { $fileName = $App.name -replace '[^a-zA-Z0-9]','_' }
    $tmpPath = Join-Path $env:TEMP $fileName

    Write-Log "Downloading: $($App.name) <- $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmpPath -UseBasicParsing
    } catch {
        Write-Log "Download error: $_" 'ERROR'
        return $false
    }

    # Handle ZIP (e.g. EV Key)
    if ($type -eq 'zip') {
        $destDir = Join-Path $env:LOCALAPPDATA "Programs\$($App.name -replace '[^a-zA-Z0-9]','_')"
        Write-Log "Extracting ZIP: $tmpPath -> $destDir"
        Expand-Archive -Path $tmpPath -DestinationPath $destDir -Force
        Remove-Item $tmpPath -Force
        Write-Log "Installed (ZIP): $($App.name)" 'OK'
        return $true
    }

    # Run installer
    Write-Log "Installing: $($App.name) (args: '$args')"
    try {
        if ($args -and $args.Trim() -ne '') {
            Start-Process $tmpPath -ArgumentList $args -Wait -NoNewWindow
        } else {
            Start-Process $tmpPath -Wait
        }
        Write-Log "Installed (URL): $($App.name)" 'OK'
    } catch {
        Write-Log "Installer error: $_" 'ERROR'
        Remove-Item $tmpPath -Force -ErrorAction SilentlyContinue
        return $false
    }

    Remove-Item $tmpPath -Force -ErrorAction SilentlyContinue
    return $true
}

# --- Install via Package Manager ---
function Install-ViaPackageManager {
    param($App, [string]$PM)
    try {
        switch ($PM) {
            'winget' {
                if (-not $App.winget) { return $false }
                winget install $App.winget --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            }
            'choco' {
                if (-not $App.choco) { return $false }
                choco install $App.choco -y 2>&1 | Out-Null
            }
            'scoop' {
                if (-not $App.scoop) { return $false }
                scoop install $App.scoop 2>&1 | Out-Null
            }
        }
        Write-Log "Installed ($PM): $($App.name)" 'OK'
        return $true
    } catch {
        Write-Log "Error ($PM): $($App.name) - $_" 'ERROR'
        return $false
    }
}

# --- Main function: install list of apps ---
function Install-Apps {
    param([array]$Apps)
    $pm = Get-PackageManager
    Write-Log "Package manager: $pm"

    foreach ($app in $Apps) {
        Write-Log "--- Installing: $($app.name) ---"
        $ok = $false

        # Priority 1: URL
        if ($app.url) {
            $ok = Install-ViaUrl -App $app
        }

        # Priority 2: winget
        if (-not $ok -and $app.winget) {
            Write-Log "Fallback winget: $($app.name)"
            $ok = Install-ViaPackageManager -App $app -PM 'winget'
        }

        # Priority 3: choco
        if (-not $ok -and $app.choco) {
            Write-Log "Fallback choco: $($app.name)"
            $ok = Install-ViaPackageManager -App $app -PM 'choco'
        }

        # Priority 4: scoop
        if (-not $ok -and $app.scoop) {
            Write-Log "Fallback scoop: $($app.name)"
            $ok = Install-ViaPackageManager -App $app -PM 'scoop'
        }

        if (-not $ok) {
            Write-Log "FAILED: Cannot install $($app.name)" 'ERROR'
        }
    }
}