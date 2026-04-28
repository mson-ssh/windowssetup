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

# --- Download URL app (returns temp path or $null) ---
function Get-UrlAppDownload {
    param($App)
    
    $url = $App.url
    if (-not $url) { return $null }
    
    $fileName = [System.IO.Path]::GetFileName(([uri]$url).LocalPath)
    if (-not $fileName -or $fileName -eq '') { $fileName = $App.name -replace '[^a-zA-Z0-9]','_' }
    $tmpPath = Join-Path $env:TEMP $fileName
    
    Write-Log "Downloading: $($App.name) <- $url"
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $tmpPath -UseBasicParsing
        Write-Log "Downloaded: $($App.name)" 'OK'
        return $tmpPath
    } catch {
        Write-Log "Download error: $_" 'ERROR'
        return $null
    }
}

# --- Install URL app (after download) ---
function Install-UrlApp {
    param($App, $TmpPath)
    
    if (-not $TmpPath -or -not (Test-Path $TmpPath)) {
        Write-Log "Downloaded file not found for $($App.name)" 'ERROR'
        return $false
    }
    
    $args = $App.args
    $type = $App.type
    
    # Handle ZIP
    if ($type -eq 'zip') {
        $destDir = Join-Path $env:LOCALAPPDATA "Programs\$($App.name -replace '[^a-zA-Z0-9]','_')"
        Write-Log "Extracting ZIP: $TmpPath -> $destDir"
        try {
            Expand-Archive -Path $TmpPath -DestinationPath $destDir -Force
            Remove-Item $TmpPath -Force
            Write-Log "Installed (ZIP): $($App.name)" 'OK'
            return $true
        } catch {
            Write-Log "ZIP extraction error: $_" 'ERROR'
            return $false
        }
    }
    
    # Run installer
    Write-Log "Installing: $($App.name) (args: '$args')"
    try {
        if ($args -and $args.Trim() -ne '') {
            $proc = Start-Process $TmpPath -ArgumentList $args -Wait -NoNewWindow -PassThru
        } else {
            $proc = Start-Process $TmpPath -Wait -PassThru
        }
        Write-Log "Installed (URL): $($App.name) (Exit code: $($proc.ExitCode))" 'OK'
    } catch {
        Write-Log "Installer error: $_" 'ERROR'
        return $false
    } finally {
        Remove-Item $TmpPath -Force -ErrorAction SilentlyContinue
    }
    
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

# --- Main function: install list of apps (parallel) ---
function Install-Apps {
    param([array]$Apps)
    
    $pm = Get-PackageManager
    Write-Log "Package manager: $pm"
    Write-Log "Starting parallel installation of $($Apps.Count) apps..."
    
    # Phase 1: Download all URL apps in parallel
    $urlApps = $Apps | Where-Object { $_.url }
    $downloadedPaths = @{}
    
    if ($urlApps.Count -gt 0) {
        Write-Log "Phase 1: Downloading $($urlApps.Count) URL apps in parallel..."
        
        $downloadJobs = @()
        foreach ($app in $urlApps) {
            $job = Start-Job -ScriptBlock {
                param($App)
                
                $url = $App.url
                $fileName = [System.IO.Path]::GetFileName(([uri]$url).LocalPath)
                if (-not $fileName -or $fileName -eq '') { $fileName = $App.name -replace '[^a-zA-Z0-9]','_' }
                $tmpPath = Join-Path $env:TEMP $fileName
                
                try {
                    $ProgressPreference = 'SilentlyContinue'
                    Invoke-WebRequest -Uri $url -OutFile $tmpPath -UseBasicParsing
                    return @{ Success = $true; Path = $tmpPath; AppName = $App.name }
                } catch {
                    return @{ Success = $false; AppName = $App.name; Error = $_ }
                }
            } -ArgumentList $app
            $downloadJobs += $job
        }
        
        # Wait for all downloads
        foreach ($job in $downloadJobs) {
            $result = $job | Wait-Job | Receive-Job
            if ($result.Success) {
                $downloadedPaths[$result.AppName] = $result.Path
                Write-Log "Downloaded: $($result.AppName) -> $($result.Path)" 'OK'
            } else {
                Write-Log "Download failed: $($result.AppName) - $($result.Error)" 'ERROR'
            }
        }
        $downloadJobs | Remove-Job
        Write-Log "Phase 1 complete: All downloads finished"
    }
    
    # Phase 2: Install all apps in parallel
    Write-Log "Phase 2: Installing all apps in parallel..."
    
    $installJobs = @()
    foreach ($app in $Apps) {
        $job = Start-Job -ScriptBlock {
            param($App, $PM, $TmpPath)
            
            # Helper for logging inside job
            function Log {
                param($Message)
                Write-Output "[$(Get-Date -Format 'HH:mm:ss')] $Message"
            }
            
            $type = $App.type
            
            # URL app
            if ($App.url) {
                if (-not $TmpPath -or -not (Test-Path $TmpPath)) {
                    Log "ERROR: Downloaded file not found for $($App.name)"
                    return @{ Success = $false; AppName = $App.name; Error = "Downloaded file not found" }
                }
                
                # Handle ZIP
                if ($type -eq 'zip') {
                    $destDir = Join-Path $env:LOCALAPPDATA "Programs\$($App.name -replace '[^a-zA-Z0-9]','_')"
                    try {
                        Expand-Archive -Path $TmpPath -DestinationPath $destDir -Force
                        Remove-Item $TmpPath -Force
                        Log "OK: Installed (ZIP): $($App.name)"
                        return @{ Success = $true; AppName = $App.name; Method = 'URL-ZIP' }
                    } catch {
                        Log "ERROR: ZIP extraction failed for $($App.name): $_"
                        return @{ Success = $false; AppName = $App.name; Method = 'URL-ZIP'; Error = $_ }
                    }
                }
                
                # Run installer
                $args = $App.args
                try {
                    if ($args -and $args.Trim() -ne '') {
                        $proc = Start-Process $TmpPath -ArgumentList $args -Wait -NoNewWindow -PassThru
                    } else {
                        $proc = Start-Process $TmpPath -Wait -PassThru
                    }
                    Remove-Item $TmpPath -Force -ErrorAction SilentlyContinue
                    Log "OK: Installed (URL): $($App.name) (Exit code: $($proc.ExitCode))"
                    return @{ Success = $true; AppName = $App.name; Method = 'URL' }
                } catch {
                    Remove-Item $TmpPath -Force -ErrorAction SilentlyContinue
                    Log "ERROR: Installer failed for $($App.name): $_"
                    return @{ Success = $false; AppName = $App.name; Method = 'URL'; Error = $_ }
                }
            }
            
            # Package manager app
            try {
                switch ($PM) {
                    'winget' {
                        if ($App.winget) {
                            winget install $App.winget --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                            Log "OK: Installed (winget): $($App.name)"
                            return @{ Success = $true; AppName = $App.name; Method = 'winget' }
                        }
                    }
                    'choco' {
                        if ($App.choco) {
                            choco install $App.choco -y 2>&1 | Out-Null
                            Log "OK: Installed (choco): $($App.name)"
                            return @{ Success = $true; AppName = $App.name; Method = 'choco' }
                        }
                    }
                    'scoop' {
                        if ($App.scoop) {
                            scoop install $App.scoop 2>&1 | Out-Null
                            Log "OK: Installed (scoop): $($App.name)"
                            return @{ Success = $true; AppName = $App.name; Method = 'scoop' }
                        }
                    }
                }
                Log "ERROR: No valid package manager ID for $($App.name)"
                return @{ Success = $false; AppName = $App.name; Method = $PM; Error = "No valid package manager ID" }
            } catch {
                Log "ERROR: Install failed for $($App.name): $_"
                return @{ Success = $false; AppName = $App.name; Method = $PM; Error = $_ }
            }
        } -ArgumentList $app, $pm, $downloadedPaths[$app.name]
        
        $installJobs += $job
    }
    
    # Wait for all installs and collect results
    foreach ($job in $installJobs) {
        $result = $job | Wait-Job | Receive-Job
        if ($result.Success) {
            Write-Log "Installed ($($result.Method)): $($result.AppName)" 'OK'
        } else {
            Write-Log "FAILED ($($result.Method)): $($result.AppName) - $($result.Error)" 'ERROR'
        }
    }
    $installJobs | Remove-Job
    
    Write-Log "Phase 2 complete: All installations finished"
}