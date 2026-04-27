# optimizer.ps1 - Toi uu he thong Windows

function Disable-Telemetry {
    param([switch]$DryRun)
    Write-Log 'Tat thu thap du lieu (Telemetry)...'
    if ($DryRun) { Write-Log '[DryRun] Disable-Telemetry - bo qua thuc thi' 'WARN'; return }
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -Type DWord -Force
    Write-Log 'Telemetry: DA TAT' 'OK'
}

function Disable-Cortana {
    param([switch]$DryRun)
    Write-Log 'Tat Cortana...'
    if ($DryRun) { Write-Log '[DryRun] Disable-Cortana - bo qua thuc thi' 'WARN'; return }
    $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    Set-ItemProperty -Path $key -Name 'AllowCortana' -Value 0 -Type DWord -Force
    Write-Log 'Cortana: DA TAT' 'OK'
}

function Set-PowerPlan {
    param([switch]$DryRun)
    Write-Log 'Chuyen sang High Performance power plan...'
    if ($DryRun) { Write-Log '[DryRun] Set-PowerPlan - bo qua thuc thi' 'WARN'; return }
    powercfg /setactive SCHEME_MIN 2>&1 | Out-Null
    Write-Log 'Power Plan: HIGH PERFORMANCE' 'OK'
}

function Clear-TempFiles {
    param([switch]$DryRun)
    Write-Log 'Xoa file tam...'
    if ($DryRun) { Write-Log '[DryRun] Clear-TempFiles - bo qua thuc thi' 'WARN'; return }
    $paths = @($env:TEMP, 'C:\Windows\Temp')
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log 'File tam: DA XOA' 'OK'
}

function Enable-DarkMode {
    param([switch]$DryRun)
    Write-Log 'Bat Dark Mode...'
    if ($DryRun) { Write-Log '[DryRun] Enable-DarkMode - bo qua thuc thi' 'WARN'; return }
    $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    Set-ItemProperty -Path $key -Name 'AppsUseLightTheme'   -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $key -Name 'SystemUsesLightTheme' -Value 0 -Type DWord -Force
    Write-Log 'Dark Mode: DA BAT' 'OK'
}

function Set-ExplorerSettings {
    param([switch]$DryRun)
    Write-Log 'Cai dat Explorer: hien file an, hien extension...'
    if ($DryRun) { Write-Log '[DryRun] Set-ExplorerSettings - bo qua thuc thi' 'WARN'; return }
    $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty -Path $key -Name 'Hidden'            -Value 1 -Type DWord -Force  # Hien file an
    Set-ItemProperty -Path $key -Name 'HideFileExt'       -Value 0 -Type DWord -Force  # Hien extension
    Set-ItemProperty -Path $key -Name 'ShowSuperHidden'   -Value 1 -Type DWord -Force  # Hien file he thong
    Write-Log 'Explorer Settings: DA CAI DAT' 'OK'
}

function Disable-Bloatware {
    param([switch]$DryRun)
    Write-Log 'Go bo Bloatware (Xbox, Candy Crush...)...' 'WARN'
    if ($DryRun) { Write-Log '[DryRun] Disable-Bloatware - bo qua thuc thi' 'WARN'; return }
    $bloatware = @(
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'king.com.CandyCrushSaga',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.BingWeather',
        'Microsoft.GetHelp'
    )
    foreach ($app in $bloatware) {
        Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue |
            Remove-AppxPackage -ErrorAction SilentlyContinue
        Write-Log "Go bo: $app" 'OK'
    }
}

function Disable-StartupApps {
    param([switch]$DryRun)
    Write-Log 'Tat app khoi dong cung Windows...' 'WARN'
    if ($DryRun) { Write-Log '[DryRun] Disable-StartupApps - bo qua thuc thi' 'WARN'; return }
    $keys = @(
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    )
    foreach ($key in $keys) {
        $items = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        if ($items) {
            $items.PSObject.Properties |
                Where-Object { $_.Name -notmatch '^PS' } |
                ForEach-Object {
                    Remove-ItemProperty -Path $key -Name $_.Name -ErrorAction SilentlyContinue
                    Write-Log "Tat startup: $($_.Name)" 'OK'
                }
        }
    }
}

# Chay tat ca cac toi uu an toan (khong bao gom Bloatware va Startup)
function Invoke-SafeOptimize {
    param([switch]$DryRun)
    Write-Log '=== Bat dau toi uu he thong (Safe) ==='
    Disable-Telemetry   @PSBoundParameters
    Disable-Cortana     @PSBoundParameters
    Set-PowerPlan       @PSBoundParameters
    Clear-TempFiles     @PSBoundParameters
    Enable-DarkMode     @PSBoundParameters
    Set-ExplorerSettings @PSBoundParameters
    Write-Log '=== Hoan thanh toi uu he thong ===' 'OK'
}
