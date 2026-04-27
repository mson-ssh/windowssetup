# main.ps1 - WPF GUI for WinSetup Pro

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# --- Config path ---
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue
if (-not $scriptDir) {
    # When running via irm | iex, use temp directory
    $scriptDir = $env:TEMP
    $configPath = Join-Path $scriptDir 'winsetup-config.json'
    # Download apps.json from GitHub
    $configUrl = 'https://raw.githubusercontent.com/mson-ssh/windowssetup/main/config/apps.json'
    try {
        Invoke-RestMethod $configUrl | Set-Content $configPath -Encoding UTF8
    } catch {
        Write-Host "[!] Cannot download config from GitHub: $_" -ForegroundColor Red
        exit 1
    }
} else {
    $configPath = Join-Path $scriptDir 'config\apps.json'
}

# =====================================================================
# XAML
# =====================================================================
[xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="MiniApp"
    Width="780" Height="580"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanMinimize"
    Background="#F5F5F5"
    Foreground="#1A1A1A"
    FontFamily="Segoe UI">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#0078D4"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="4"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Opacity" Value="0.7"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#1A1A1A"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="0,4,0,4"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>

        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="#1A1A1A"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="0,6,0,6"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>

        <Style TargetType="TabItem">
            <Setter Property="Background" Value="#E0E0E0"/>
            <Setter Property="Foreground" Value="#444444"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border Name="Border" Background="{TemplateBinding Background}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter ContentSource="Header"
                                             HorizontalAlignment="Center"
                                             VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#0078D4"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#C8E0F4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TabControl Grid.Row="0" Background="#FFFFFF" BorderThickness="1" BorderBrush="#DDDDDD" x:Name="tabMain">

            <TabItem Header="Install Apps">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
                        <StackPanel x:Name="panelApps" Margin="0,4,0,4"/>
                    </ScrollViewer>
                    <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button x:Name="btnSelectAll" Content="Select All" Width="100" Margin="0,0,8,0" Background="#0078D4"/>
                        <Button x:Name="btnDeselectAll" Content="Deselect" Width="90" Margin="0,0,8,0" Background="#6C757D"/>
                        <Button x:Name="btnDefault" Content="Default" Width="90" Background="#107C10"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="Activation">
                <StackPanel Margin="20,16,20,16">
                    <TextBlock x:Name="lblActStatus" FontSize="14" Margin="0,0,0,20"
                               Foreground="#444444" Text="Checking status..."/>
                    <TextBlock Text="Select method:" Foreground="#666666" FontSize="12" Margin="0,0,0,8"/>
                    <RadioButton x:Name="rbHWID"   Content="HWID  —  Permanent, hardware-based (Windows 10/11)" IsChecked="True"/>
                    <RadioButton x:Name="rbKMS38"  Content="KMS38  —  Until 2038, auto-renew"/>
                    <RadioButton x:Name="rbOhook"  Content="Ohook  —  Microsoft 365, offline"/>
                    <Button x:Name="btnActivate" Content="Activate Now"
                            Width="140" HorizontalAlignment="Left" Margin="0,20,0,0"
                            Background="#0078D4" Foreground="White"/>
                </StackPanel>
            </TabItem>

            <TabItem Header="Optimize">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <StackPanel Grid.Row="0" x:Name="panelOptimize" Margin="8,8,8,8"/>
                    <Button Grid.Row="1" x:Name="btnDryRun"
                            Content="Dry Run (Test — no system changes)"
                            HorizontalAlignment="Left" Margin="8,8,0,0"
                            Background="#6C757D" Width="260"/>
                </Grid>
            </TabItem>

            <TabItem Header="Specifications">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel x:Name="panelSpecs" Margin="16"/>
                </ScrollViewer>
            </TabItem>

        </TabControl>

        <ProgressBar Grid.Row="1" x:Name="progressBar"
                     Height="6" Margin="0,12,0,4"
                     Background="#D0D0D0" Foreground="#0078D4"
                     BorderThickness="0" Value="0" Maximum="100"/>

        <Grid Grid.Row="2" Margin="0,4,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" x:Name="lblStatus"
                       Text="Ready." Foreground="#666666"
                       FontSize="12" VerticalAlignment="Center"/>
            <Button Grid.Column="1" x:Name="btnLog"
                    Content="View Log" Width="80" Margin="8,0,8,0"
                    Background="#6C757D"/>
            <Button Grid.Column="2" x:Name="btnRun"
                    Content="Run All" Width="90"
                    Background="#107C10" Foreground="White"
                    FontWeight="SemiBold"/>
        </Grid>
    </Grid>
</Window>
'@

# =====================================================================
# LOAD XAML
# =====================================================================
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$panelApps    = $window.FindName('panelApps')
$panelOpt     = $window.FindName('panelOptimize')
$panelSpecs   = $window.FindName('panelSpecs')
$lblActStatus = $window.FindName('lblActStatus')
$rbHWID       = $window.FindName('rbHWID')
$rbKMS38      = $window.FindName('rbKMS38')
$rbOhook      = $window.FindName('rbOhook')
$btnActivate  = $window.FindName('btnActivate')
$btnSelectAll = $window.FindName('btnSelectAll')
$btnDeselect  = $window.FindName('btnDeselectAll')
$btnDefault   = $window.FindName('btnDefault')
$btnDryRun    = $window.FindName('btnDryRun')
$progressBar  = $window.FindName('progressBar')
$lblStatus    = $window.FindName('lblStatus')
$btnRun       = $window.FindName('btnRun')
$btnLog       = $window.FindName('btnLog')

# =====================================================================
# HELPER: create group header
# =====================================================================
function New-GroupHeader([string]$text) {
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text       = $text
    $tb.FontSize   = 13
    $tb.FontWeight = 'SemiBold'
    $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#0078D4')
    $tb.Margin     = [System.Windows.Thickness]::new(0, 12, 0, 4)
    return $tb
}

# =====================================================================
# TAB 1: Load apps from apps.json
# =====================================================================
$appCheckboxes = @{}
if (Test-Path $configPath) {
    $groups = (Get-Content $configPath -Raw | ConvertFrom-Json).groups
    foreach ($group in $groups) {
        $panelApps.Children.Add((New-GroupHeader $group.name)) | Out-Null

        $groupWrap = New-Object System.Windows.Controls.WrapPanel
        $groupWrap.Orientation = 'Horizontal'
        $groupWrap.Margin      = [System.Windows.Thickness]::new(0, 0, 0, 8)
        $panelApps.Children.Add($groupWrap) | Out-Null

        foreach ($app in $group.apps) {
            $cb           = New-Object System.Windows.Controls.CheckBox
            $cb.Content   = $app.name
            $cb.Tag       = $app
            $cb.IsChecked = $false
            $cb.Width     = 340
            $groupWrap.Children.Add($cb) | Out-Null
            $appCheckboxes[$app.name] = $cb
        }
    }
}

$btnSelectAll.Add_Click({ foreach ($cb in $appCheckboxes.Values) { $cb.IsChecked = $true  } })
$btnDeselect.Add_Click({  foreach ($cb in $appCheckboxes.Values) { $cb.IsChecked = $false } })

# Default button - select recommended apps
$btnDefault.Add_Click({
    # First deselect all
    foreach ($cb in $appCheckboxes.Values) { $cb.IsChecked = $false }
    
    # Then select default apps
    $defaultApps = @(
        'Google Chrome', 'Zoom', 'Telegram', 'Zalo', 
        'Foxit PDF Reader', 'EV Key', '7-Zip', 'WinRAR', 
        'K-Lite Codec Pack', 'UltraViewer', 
        'VC++ Redist 2015-2022 x64', 'VC++ Redist 2015-2022 x86'
    )
    
    foreach ($appName in $defaultApps) {
        if ($appCheckboxes.ContainsKey($appName)) {
            $appCheckboxes[$appName].IsChecked = $true
        }
    }
})

# =====================================================================
# TAB 2: Activation status
# =====================================================================
try {
    $actStatus = Get-ActivationStatus
    $lblActStatus.Text       = "Status: $actStatus"
    $lblActStatus.Foreground = if ($actStatus -eq 'Activated') {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#107C10')
    } else {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#D83B01')
    }
} catch {
    $lblActStatus.Text = 'Status: Unknown'
}

$btnActivate.Add_Click({
    $method = if ($rbHWID.IsChecked) { 'HWID' } elseif ($rbKMS38.IsChecked) { 'KMS38' } else { 'Ohook' }
    $r = [System.Windows.MessageBox]::Show(
        "Confirm activation with $method?", 'MiniApp',
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question)
    if ($r -eq 'Yes') {
        $lblStatus.Text = "Activating ($method)..."
        Invoke-Activation -Method $method
        $lblStatus.Text = 'Activation complete!'
    }
})

# =====================================================================
# TAB 3: System optimization
# =====================================================================
$optimizeTasks = @(
    @{ Name='Disable Telemetry';      Func='Disable-Telemetry';    Safe=$true  }
    @{ Name='Disable Cortana';        Func='Disable-Cortana';      Safe=$true  }
    @{ Name='High Performance Plan';  Func='Set-PowerPlan';        Safe=$true  }
    @{ Name='Clear Temp Files';       Func='Clear-TempFiles';      Safe=$true  }
    @{ Name='Enable Dark Mode';       Func='Enable-DarkMode';      Safe=$true  }
    @{ Name='Explorer Settings';      Func='Set-ExplorerSettings'; Safe=$true  }
    @{ Name='Remove Bloatware';       Func='Disable-Bloatware';    Safe=$false }
    @{ Name='Disable Startup Apps';   Func='Disable-StartupApps';  Safe=$false }
)

$optCheckboxes = @{}
foreach ($task in $optimizeTasks) {
    $cb           = New-Object System.Windows.Controls.CheckBox
    $cb.Content   = $task.Name
    $cb.Tag       = $task.Func
    $cb.IsChecked = $task.Safe
    if (-not $task.Safe) {
        $cb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#D83B01')
    }
    $panelOpt.Children.Add($cb) | Out-Null
    $optCheckboxes[$task.Func] = $cb
}

$btnDryRun.Add_Click({
    $lblStatus.Text = 'Running Dry Run...'
    foreach ($task in $optimizeTasks) {
        if ($optCheckboxes[$task.Func].IsChecked) { & $task.Func -DryRun }
    }
    $lblStatus.Text = 'Dry Run complete. Check log for details.'
})

# =====================================================================
# RUN ALL BUTTON
# =====================================================================
$btnRun.Add_Click({
    $selectedApps = @()
    foreach ($cb in $appCheckboxes.Values) {
        if ($cb.IsChecked) { $selectedApps += $cb.Tag }
    }
    $selectedOpts = @($optimizeTasks | Where-Object { $optCheckboxes[$_.Func].IsChecked })
    $total = $selectedApps.Count + $selectedOpts.Count

    if ($total -eq 0) {
        [System.Windows.MessageBox]::Show('Nothing selected!', 'MiniApp') | Out-Null
        return
    }

    $progressBar.Maximum = $total
    $progressBar.Value   = 0
    $done = 0

    if ($selectedApps.Count -gt 0) {
        $lblStatus.Text = 'Installing apps...'
        Install-Apps -Apps $selectedApps
        $done += $selectedApps.Count
        $progressBar.Value = $done
    }

    foreach ($task in $selectedOpts) {
        $lblStatus.Text = "Running: $($task.Name)..."
        & $task.Func
        $done++
        $progressBar.Value = $done
        $window.Dispatcher.Invoke([action]{}, 'Background')
    }

    $lblStatus.Text = 'Complete!'
    [System.Windows.MessageBox]::Show('All tasks completed!', 'MiniApp',
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information) | Out-Null
})

# =====================================================================
# VIEW LOG BUTTON
# =====================================================================
$btnLog.Add_Click({
    if (Test-Path $logPath) {
        Start-Process notepad $logPath
    } else {
        [System.Windows.MessageBox]::Show('No log file found.', 'MiniApp') | Out-Null
    }
})

# =====================================================================
# TAB 4: SPECIFICATIONS - Hardware Information
# =====================================================================

# Helper function to add spec item
function Add-SpecItem($label, $value, $color = '#1A1A1A') {
    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Orientation = 'Horizontal'
    $sp.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)
    
    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = "$label"
    $lbl.FontWeight = 'SemiBold'
    $lbl.Width = 180
    $lbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#666666')
    
    $val = New-Object System.Windows.Controls.TextBlock
    $val.Text = $value
    $val.TextWrapping = 'Wrap'
    $val.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
    
    $sp.Children.Add($lbl) | Out-Null
    $sp.Children.Add($val) | Out-Null
    
    return $sp
}

# 1. GENERAL INFORMATION
$panelSpecs.Children.Add((New-GroupHeader 'General Information')) | Out-Null

try {
    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    
    $panelSpecs.Children.Add((Add-SpecItem 'Model:' "$($cs.Manufacturer) $($cs.Model)")) | Out-Null
    $panelSpecs.Children.Add((Add-SpecItem 'Serial Number:' $bios.SerialNumber)) | Out-Null
} catch {
    $panelSpecs.Children.Add((Add-SpecItem 'Model:' 'Unable to retrieve')) | Out-Null
}

# 2. OPERATING SYSTEM
$panelSpecs.Children.Add((New-GroupHeader 'Operating System')) | Out-Null

try {
    $os = Get-CimInstance Win32_OperatingSystem
    $osName = $os.Caption -replace 'Microsoft ', ''
    
    $panelSpecs.Children.Add((Add-SpecItem 'OS:' $osName)) | Out-Null
    
    # Activation status with auto-refresh
    $actStatusLabel = New-Object System.Windows.Controls.TextBlock
    $actStatusLabel.Text = 'Activation Status:'
    $actStatusLabel.FontWeight = 'SemiBold'
    $actStatusLabel.Width = 180
    $actStatusLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#666666')
    
    $actStatusValue = New-Object System.Windows.Controls.TextBlock
    $actStatusValue.Name = 'txtActStatus'
    
    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Orientation = 'Horizontal'
    $sp.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)
    $sp.Children.Add($actStatusLabel) | Out-Null
    $sp.Children.Add($actStatusValue) | Out-Null
    $panelSpecs.Children.Add($sp) | Out-Null
    
    # Function to update activation status
    $updateActStatus = {
        try {
            $lic = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.PartialProductKey -and $_.LicenseStatus -eq 1 }
            if ($lic) {
                $actStatusValue.Text = 'Activated'
                $actStatusValue.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#107C10')
            } else {
                $actStatusValue.Text = 'Not Activated'
                $actStatusValue.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#D83B01')
            }
        } catch {
            $actStatusValue.Text = 'Unknown'
            $actStatusValue.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#666666')
        }
    }
    
    & $updateActStatus
    
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(5)
    $timer.Add_Tick($updateActStatus)
    $timer.Start()
    
} catch {
    $panelSpecs.Children.Add((Add-SpecItem 'OS:' 'Unable to retrieve')) | Out-Null
}

# 3. CPU
$panelSpecs.Children.Add((New-GroupHeader 'Processor')) | Out-Null

try {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cpuInfo = "$($cpu.Name) ($($cpu.NumberOfCores) cores, $($cpu.NumberOfLogicalProcessors) threads)"
    $panelSpecs.Children.Add((Add-SpecItem 'CPU:' $cpuInfo)) | Out-Null
} catch {
    $panelSpecs.Children.Add((Add-SpecItem 'CPU:' 'Unable to retrieve')) | Out-Null
}

# 4. STORAGE
$panelSpecs.Children.Add((New-GroupHeader 'Storage')) | Out-Null

try {
    $disks = Get-CimInstance Win32_DiskDrive
    foreach ($disk in $disks) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 2)
        $diskInfo = "$($disk.Model) ($sizeGB GB)"
        $panelSpecs.Children.Add((Add-SpecItem "Disk $($disk.Index):" $diskInfo)) | Out-Null
        
        $partitions = Get-CimInstance Win32_DiskPartition | Where-Object { $_.DiskIndex -eq $disk.Index }
        foreach ($part in $partitions) {
            $partSizeGB = [math]::Round($part.Size / 1GB, 2)
            $logicalDisks = Get-CimInstance Win32_LogicalDiskToDiskPartition | Where-Object { $_.Antecedent.DeviceID -eq $part.DeviceID }
            foreach ($ld in $logicalDisks) {
                $drive = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $ld.Dependent.DeviceID }
                if ($drive) {
                    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
                    $partInfo = "  └─ $($drive.DeviceID) ($partSizeGB GB, $freeGB GB free)"
                    $panelSpecs.Children.Add((Add-SpecItem '' $partInfo)) | Out-Null
                }
            }
        }
    }
} catch {
    $panelSpecs.Children.Add((Add-SpecItem 'Storage:' 'Unable to retrieve')) | Out-Null
}

# 5. RAM
$panelSpecs.Children.Add((New-GroupHeader 'Memory')) | Out-Null

try {
    $ram = Get-CimInstance Win32_PhysicalMemory
    $totalRAM = [math]::Round(($ram | Measure-Object Capacity -Sum).Sum / 1GB, 2)
    
    $ramType = switch ($ram[0].SMBIOSMemoryType) {
        20 { 'DDR' }
        21 { 'DDR2' }
        24 { 'DDR3' }
        26 { 'DDR4' }
        34 { 'DDR5' }
        default { 'Unknown' }
    }
    
    $ramSpeed = $ram[0].Speed
    
    $ramInfo = "$totalRAM GB $ramType @ $ramSpeed MHz"
    $panelSpecs.Children.Add((Add-SpecItem 'Total RAM:' $ramInfo)) | Out-Null
} catch {
    $panelSpecs.Children.Add((Add-SpecItem 'RAM:' 'Unable to retrieve')) | Out-Null
}

# 6. GRAPHICS
$panelSpecs.Children.Add((New-GroupHeader 'Graphics')) | Out-Null

try {
    $gpus = Get-CimInstance Win32_VideoController
    $gpuIndex = 0
    foreach ($gpu in $gpus) {
        $gpuIndex++
        $gpuName = if ($gpu.Name -match 'Intel|AMD.*Radeon.*Vega|AMD.*Ryzen') { 
            "$($gpu.Name) (Integrated)" 
        } else { 
            "$($gpu.Name) (Discrete)" 
        }
        $panelSpecs.Children.Add((Add-SpecItem "GPU $gpuIndex`:" $gpuName)) | Out-Null
    }
    
    Add-Type -AssemblyName System.Windows.Forms
    $screens = [System.Windows.Forms.Screen]::AllScreens
    $monIndex = 0
    foreach ($screen in $screens) {
        $monIndex++
        $isPrimary = if ($screen.Primary) { ' (Primary)' } else { '' }
        $refreshRate = 60
        $monInfo = "$($screen.Bounds.Width)x$($screen.Bounds.Height) @ ${refreshRate}Hz$isPrimary"
        $panelSpecs.Children.Add((Add-SpecItem "Monitor $monIndex`:" $monInfo)) | Out-Null
    }
} catch {
    $panelSpecs.Children.Add((Add-SpecItem 'Graphics:' 'Unable to retrieve')) | Out-Null
}

# 7. NETWORK
$panelSpecs.Children.Add((New-GroupHeader 'Network Controllers')) | Out-Null

try {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -ne 'Disabled' }
    
    foreach ($adapter in $adapters) {
        $adapterType = if ($adapter.Name -match 'Wi-Fi|Wireless') { 'WiFi' } else { 'Ethernet' }
        $status = if ($adapter.Status -eq 'Up') { 'Connected' } else { 'Disconnected' }
        $statusColor = if ($adapter.Status -eq 'Up') { '#107C10' } else { '#D83B01' }
        
        $speed = if ($adapter.LinkSpeed) { 
            $speedGbps = [math]::Round([double]($adapter.LinkSpeed -replace ' Gbps| Mbps') / 1000, 2)
            if ($speedGbps -ge 1) { "$speedGbps Gbps" } else { "$($adapter.LinkSpeed)" }
        } else { 'N/A' }
        
        $adapterInfo = "$($adapter.InterfaceDescription) | $speed | $status"
        $panelSpecs.Children.Add((Add-SpecItem "$adapterType`:" $adapterInfo $statusColor)) | Out-Null
    }
} catch {
    $panelSpecs.Children.Add((Add-SpecItem 'Network:' 'Unable to retrieve')) | Out-Null
}

# =====================================================================
# RUN WPF
# =====================================================================
$window.ShowDialog() | Out-Null
