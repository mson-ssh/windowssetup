# installer.ps1 - Cai phan mem qua URL -> winget -> choco -> scoop
#
# LOGIC CAI DAT (theo thu tu uu tien):
# 1. URL    - Tai file tu trang chu, chay silent
# 2. winget - Windows Package Manager (Win10 1809+)
# 3. choco  - Chocolatey
# 4. scoop  - Scoop (tu dong cai neu can)
# Dac biet: type=zip -> giai nen vao %LOCALAPPDATA%\Programs\

function Get-PackageManager {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return 'winget' }
    if (Get-Command choco  -ErrorAction SilentlyContinue) { return 'choco'  }
    Write-Log 'Khong tim thay winget/choco. Dang cai Scoop...' 'WARN'
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    return 'scoop'
}

function Get-AppList {
    param([string]$ConfigPath)
    if (-not (Test-Path $ConfigPath)) {
        Write-Log "Khong tim thay apps.json: $ConfigPath" 'ERROR'
        return @()
    }
    $json = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    return $json.groups
}

# --- Cai qua URL ---
function Install-ViaUrl {
    param($App)
    $url  = $App.url
    $args = $App.args
    $type = $App.type

    # Lay ten file tu URL
    $fileName = [System.IO.Path]::GetFileName(([uri]$url).LocalPath)
    if (-not $fileName -or $fileName -eq '') { $fileName = $App.name -replace '[^a-zA-Z0-9]','_' }
    $tmpPath = Join-Path $env:TEMP $fileName

    Write-Log "Dang tai: $($App.name) <- $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmpPath -UseBasicParsing
    } catch {
        Write-Log "Loi tai file: $_" 'ERROR'
        return $false
    }

    # Xu ly ZIP (vi du EV Key)
    if ($type -eq 'zip') {
        $destDir = Join-Path $env:LOCALAPPDATA "Programs\$($App.name -replace '[^a-zA-Z0-9]','_')"
        Write-Log "Giai nen ZIP: $tmpPath -> $destDir"
        Expand-Archive -Path $tmpPath -DestinationPath $destDir -Force
        Remove-Item $tmpPath -Force
        Write-Log "Cai thanh cong (ZIP): $($App.name)" 'OK'
        return $true
    }

    # Chay installer
    Write-Log "Dang cai: $($App.name) (args: '$args')"
    try {
        if ($args -and $args.Trim() -ne '') {
            Start-Process $tmpPath -ArgumentList $args -Wait -NoNewWindow
        } else {
            Start-Process $tmpPath -Wait
        }
        Write-Log "Cai thanh cong (URL): $($App.name)" 'OK'
    } catch {
        Write-Log "Loi khi chay installer: $_" 'ERROR'
        Remove-Item $tmpPath -Force -ErrorAction SilentlyContinue
        return $false
    }

    Remove-Item $tmpPath -Force -ErrorAction SilentlyContinue
    return $true
}

# --- Cai qua Package Manager ---
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
        Write-Log "Cai thanh cong ($PM): $($App.name)" 'OK'
        return $true
    } catch {
        Write-Log "Loi ($PM): $($App.name) - $_" 'ERROR'
        return $false
    }
}

# --- Ham chinh: cai danh sach app ---
function Install-Apps {
    param([array]$Apps)
    $pm = Get-PackageManager
    Write-Log "Package manager: $pm"

    foreach ($app in $Apps) {
        Write-Log "--- Bat dau cai: $($app.name) ---"
        $ok = $false

        # Uu tien 1: URL
        if ($app.url) {
            $ok = Install-ViaUrl -App $app
        }

        # Uu tien 2: winget
        if (-not $ok -and $app.winget) {
            Write-Log "Fallback winget: $($app.name)"
            $ok = Install-ViaPackageManager -App $app -PM 'winget'
        }

        # Uu tien 3: choco
        if (-not $ok -and $app.choco) {
            Write-Log "Fallback choco: $($app.name)"
            $ok = Install-ViaPackageManager -App $app -PM 'choco'
        }

        # Uu tien 4: scoop
        if (-not $ok -and $app.scoop) {
            Write-Log "Fallback scoop: $($app.name)"
            $ok = Install-ViaPackageManager -App $app -PM 'scoop'
        }

        if (-not $ok) {
            Write-Log "THAT BAI: Khong the cai $($app.name)" 'ERROR'
        }
    }
}
