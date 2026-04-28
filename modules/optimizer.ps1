# optimizer.ps1 - Windows system optimization

function Disable-Telemetry {
    param([switch]$DryRun)
    Write-Log 'Disabling Telemetry (data collection)...'
    if ($DryRun) { Write-Log '[DryRun] Disable-Telemetry - skipped' 'WARN'; return }
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -Type DWord -Force
    Write-Log 'Telemetry: DISABLED' 'OK'
}

function Disable-Cortana {
    param([switch]$DryRun)
    Write-Log 'Disabling Cortana...'
    if ($DryRun) { Write-Log '[DryRun] Disable-Cortana - skipped' 'WARN'; return }
    $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    Set-ItemProperty -Path $key -Name 'AllowCortana' -Value 0 -Type DWord -Force
    Write-Log 'Cortana: DISABLED' 'OK'
}

function Set-PowerPlan {
    param([switch]$DryRun)
    Write-Log 'Switching to High Performance power plan...'
    if ($DryRun) { Write-Log '[DryRun] Set-PowerPlan - skipped' 'WARN'; return }
    powercfg /setactive SCHEME_MIN 2>&1 | Out-Null
    Write-Log 'Power Plan: HIGH PERFORMANCE' 'OK'
}

function Clear-TempFiles {
    param([switch]$DryRun)
    Write-Log 'Clearing temporary files...'
    if ($DryRun) { Write-Log '[DryRun] Clear-TempFiles - skipped' 'WARN'; return }
    $paths = @($env:TEMP, 'C:\Windows\Temp')
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log 'Temp files: CLEARED' 'OK'
}

function Enable-DarkMode {
    param([switch]$DryRun)
    Write-Log 'Enabling Dark Mode...'
    if ($DryRun) { Write-Log '[DryRun] Enable-DarkMode - skipped' 'WARN'; return }
    $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    Set-ItemProperty -Path $key -Name 'AppsUseLightTheme'   -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $key -Name 'SystemUsesLightTheme' -Value 0 -Type DWord -Force
    Write-Log 'Dark Mode: ENABLED' 'OK'
}

function Set-ExplorerSettings {
    param([switch]$DryRun)
    Write-Log 'Configuring Explorer: show hidden files, show extensions...'
    if ($DryRun) { Write-Log '[DryRun] Set-ExplorerSettings - skipped' 'WARN'; return }
    $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty -Path $key -Name 'Hidden'            -Value 1 -Type DWord -Force  # Show hidden files
    Set-ItemProperty -Path $key -Name 'HideFileExt'       -Value 0 -Type DWord -Force  # Show extensions
    Set-ItemProperty -Path $key -Name 'ShowSuperHidden'   -Value 1 -Type DWord -Force  # Show system files
    Write-Log 'Explorer Settings: APPLIED' 'OK'
}

function Disable-Bloatware {
    param([switch]$DryRun)
    Write-Log 'Removing Bloatware (Xbox, Candy Crush...)...' 'WARN'
    if ($DryRun) { Write-Log '[DryRun] Disable-Bloatware - skipped' 'WARN'; return }
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
        Write-Log "Removed: $app" 'OK'
    }
}

function Disable-StartupApps {
    param([switch]$DryRun)
    Write-Log 'Disabling startup apps...' 'WARN'
    if ($DryRun) { Write-Log '[DryRun] Disable-StartupApps - skipped' 'WARN'; return }
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
                    Write-Log "Disabled startup: $($_.Name)" 'OK'
                }
        }
    }
}

# Run all safe optimizations (excludes Bloatware and Startup)
function Invoke-SafeOptimize {
    param([switch]$DryRun)
    Write-Log '=== Starting system optimization (Safe) ==='
    Disable-Telemetry    @PSBoundParameters
    Disable-Cortana      @PSBoundParameters
    Set-PowerPlan        @PSBoundParameters
    Clear-TempFiles      @PSBoundParameters
    Enable-DarkMode      @PSBoundParameters
    Set-ExplorerSettings @PSBoundParameters
    Write-Log '=== System optimization complete ===' 'OK'
}