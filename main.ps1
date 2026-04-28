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
    Title="WinSetup Pro"
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

                    <!-- Status Section -->
                    <TextBlock Text="Activation Status" FontSize="13" FontWeight="SemiBold"
                               Foreground="#0078D4" Margin="0,0,0,10"/>

                    <Grid Margin="0,0,0,6">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="160"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="Windows:" FontSize="13"
                                   Foreground="#444444" VerticalAlignment="Center"/>
                        <TextBlock Grid.Column="1" x:Name="lblWinStatus" FontSize="13"
                                   FontWeight="SemiBold" Foreground="#666666"
                                   Text="Checking..." VerticalAlignment="Center"/>
                    </Grid>

                    <Grid Margin="0,0,0,20">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="160"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="Microsoft Office:" FontSize="13"
                                   Foreground="#444444" VerticalAlignment="Center"/>
                        <TextBlock Grid.Column="1" x:Name="lblOfficeStatus" FontSize="13"
                                   FontWeight="SemiBold" Foreground="#666666"
                                   Text="Checking..." VerticalAlignment="Center"/>
                    </Grid>

                    <!-- Method Section -->
                    <TextBlock Text="Select activation method:" Foreground="#666666"
                               FontSize="12" Margin="0,0,0,8"/>
                    <RadioButton x:Name="rbHWID"   Content="HWID  —  Permanent, hardware-based (Windows 10/11)" IsChecked="True"/>
                    <RadioButton x:Name="rbKMS38"  Content="KMS38  —  Until 2038, auto-renew"/>
                    <RadioButton x:Name="rbOhook"  Content="Ohook  —  Microsoft 365 (offline)"/>

                    <StackPanel Orientation="Horizontal" Margin="0,20,0,0">
                        <Button x:Name="btnActivate" Content="Activate Now"
                                Width="130" Margin="0,0,10,0"
                                Background="#0078D4" Foreground="White"/>
                        <Button x:Name="btnRefreshStatus" Content="Refresh Status"
                                Width="120"
                                Background="#6C757D" Foreground="White"/>
                    </StackPanel>

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
                    Content="AutoRUN" Width="80" Margin="8,0,8,0"
                    Background="#6C757D"/>
            <Button Grid.Column="2" x:Name="btnRun"
                    Content="Run" Width="90"
                    Background="#107C10" Foreground="White"
                    FontWeight="SemiBold"/>
        </Grid>
    </Grid>
</Window>
'@

# =====================================================================
# LOAD WPF ASSEMBLIES + XAML
# =====================================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$panelApps         = $window.FindName('panelApps')
$panelOpt          = $window.FindName('panelOptimize')
$panelSpecs        = $window.FindName('panelSpecs')
$lblWinStatus      = $window.FindName('lblWinStatus')
$lblOfficeStatus   = $window.FindName('lblOfficeStatus')
$rbHWID            = $window.FindName('rbHWID')
$rbKMS38           = $window.FindName('rbKMS38')
$rbOhook           = $window.FindName('rbOhook')
$btnActivate       = $window.FindName('btnActivate')
$btnRefreshStatus  = $window.FindName('btnRefreshStatus')
$btnSelectAll      = $window.FindName('btnSelectAll')
$btnDeselect       = $window.FindName('btnDeselectAll')
$btnDefault        = $window.FindName('btnDefault')
$btnDryRun         = $window.FindName('btnDryRun')
$progressBar       = $window.FindName('progressBar')
$lblStatus         = $window.FindName('lblStatus')
$btnRun            = $window.FindName('btnRun')
$btnLog            = $window.FindName('btnLog')

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
function Set-ActivationStatusLabel($label, [string]$prefix, [string]$status) {
    $label.Text = "$prefix $status"

    $color = switch ($status) {
        'Activated' { '#107C10' }
        'Not Activated' { '#D83B01' }
        default { '#666666' }
    }

    $label.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
}

function Refresh-ActivationStatus {
    try {
        $windowsStatus = Get-WindowsActivationStatus
    } catch {
        $windowsStatus = 'Unknown'
    }

    try {
        $officeStatus = Get-OfficeActivationStatus
    } catch {
        $officeStatus = 'Unknown'
    }

    Set-ActivationStatusLabel $lblWinStatus 'Windows Status:' $windowsStatus
    Set-ActivationStatusLabel $lblOfficeStatus 'Office Status:' $officeStatus
}

Refresh-ActivationStatus

$btnRefreshStatus.Add_Click({
    Refresh-ActivationStatus
    $lblStatus.Text = 'Activation status refreshed.'
})

$btnActivate.Add_Click({
    $method = if ($rbHWID.IsChecked) { 'HWID' } elseif ($rbKMS38.IsChecked) { 'KMS38' } else { 'Ohook' }
    $r = [System.Windows.MessageBox]::Show(
        "Confirm activation with $method?", 'WinSetup Pro',
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question)
    if ($r -eq 'Yes') {
        $lblStatus.Text = "Activating ($method)..."
        Invoke-Activation -Method $method
        Refresh-ActivationStatus
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
# RUN BUTTON - execute only for the current tab
# =====================================================================
$btnRun.Add_Click({
    switch ($tabMain.SelectedIndex) {
        0 {
            $selectedApps = @()
            foreach ($cb in $appCheckboxes.Values) {
                if ($cb.IsChecked) { $selectedApps += $cb.Tag }
            }

            if ($selectedApps.Count -eq 0) {
                [System.Windows.MessageBox]::Show('No apps selected!', 'WinSetup Pro') | Out-Null
                return
            }

            $progressBar.Maximum = $selectedApps.Count
            $progressBar.Value = 0
            $lblStatus.Text = 'Installing selected apps...'

            Install-Apps -Apps $selectedApps

            $progressBar.Value = $selectedApps.Count
            $lblStatus.Text = 'App installation complete!'
        }

        1 {
            $method = if ($rbHWID.IsChecked) { 'HWID' } elseif ($rbKMS38.IsChecked) { 'KMS38' } else { 'Ohook' }
            $r = [System.Windows.MessageBox]::Show(
                "Confirm activation with $method?", 'WinSetup Pro',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question)

            if ($r -ne 'Yes') {
                return
            }

            $progressBar.Maximum = 1
            $progressBar.Value = 0
            $lblStatus.Text = "Activating ($method)..."

            Invoke-Activation -Method $method

            $progressBar.Value = 1
            $lblStatus.Text = 'Activation complete!'

            Refresh-ActivationStatus
        }

        2 {
            $selectedOpts = @($optimizeTasks | Where-Object { $optCheckboxes[$_.Func].IsChecked })

            if ($selectedOpts.Count -eq 0) {
                [System.Windows.MessageBox]::Show('No optimization tasks selected!', 'WinSetup Pro') | Out-Null
                return
            }

            $progressBar.Maximum = $selectedOpts.Count
            $progressBar.Value = 0
            $done = 0

            foreach ($task in $selectedOpts) {
                $lblStatus.Text = "Running: $($task.Name)..."
                & $task.Func
                $done++
                $progressBar.Value = $done
                $window.Dispatcher.Invoke([action]{}, 'Background')
            }

            $lblStatus.Text = 'Optimization complete!'
        }

        3 {
            [System.Windows.MessageBox]::Show('Specifications tab has no runnable tasks.', 'WinSetup Pro')
        }
    }
})

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class NativeDisplay
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct DEVMODE
    {
        private const int CCHDEVICENAME = 32;
        private const int CCHFORMNAME = 32;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCHDEVICENAME)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCHFORMNAME)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);
}
"@

function Get-DisplayRefreshRate([string]$deviceName) {
    try {
        $devMode = New-Object NativeDisplay+DEVMODE
        $devMode.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf([type][NativeDisplay+DEVMODE])
        $ENUM_CURRENT_SETTINGS = -1
        $ok = [NativeDisplay]::EnumDisplaySettings($deviceName, $ENUM_CURRENT_SETTINGS, [ref]$devMode)
        if ($ok -and $devMode.dmDisplayFrequency -gt 1) {
            return $devMode.dmDisplayFrequency
        }
    } catch {}
    return $null
}

# Load specs on demand when tab is selected
$tabMain = $window.FindName('tabMain')
$script:specsLoaded = $false

$tabMain.Add_SelectionChanged({
    if ($tabMain.SelectedIndex -eq 3 -and -not $script:specsLoaded) {
        $script:specsLoaded = $true

        # Setup progress tracking (7 sections)
        $specsTotal = 7
        $progressBar.Maximum = $specsTotal
        $progressBar.Value   = 0
        $lblStatus.Text      = 'Loading Specifications... 0%'
        $window.Dispatcher.Invoke([action]{}, 'Background')

        # Helper: advance progress bar + status label
        $script:specsStep = 0
        function Step-SpecsProgress([string]$section) {
            $script:specsStep++
            $pct = [math]::Round($script:specsStep / $specsTotal * 100)
            $progressBar.Value = $script:specsStep
            $lblStatus.Text = "Loading Specifications... $pct% ($section)"
            $window.Dispatcher.Invoke([action]{}, 'Background')
        }

        # Preload fast CIM data first so the tab can render content earlier
        $cs = $null
        $bios = $null
        $os = $null
        $cpu = $null
        $ram = $null
        $lic = $null

        try { $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop } catch {}
        try { $bios = Get-CimInstance Win32_BIOS -ErrorAction Stop } catch {}
        try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch {}
        try { $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1 } catch {}
        try { $ram = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop } catch {}
        try { $lic = Get-CimInstance SoftwareLicensingProduct -ErrorAction Stop | Where-Object { $_.PartialProductKey -and $_.LicenseStatus -eq 1 } } catch {}

        # 1. GENERAL INFORMATION
        $panelSpecs.Children.Add((New-GroupHeader 'General Information')) | Out-Null
        if ($cs) {
            $panelSpecs.Children.Add((Add-SpecItem 'Model:' "$($cs.Manufacturer) $($cs.Model)")) | Out-Null
        } else {
            $panelSpecs.Children.Add((Add-SpecItem 'Model:' 'Unable to retrieve')) | Out-Null
        }

        if ($bios) {
            $panelSpecs.Children.Add((Add-SpecItem 'Serial Number:' $bios.SerialNumber)) | Out-Null
        } else {
            $panelSpecs.Children.Add((Add-SpecItem 'Serial Number:' 'Unable to retrieve')) | Out-Null
        }
        Step-SpecsProgress 'General'

        # 2. OPERATING SYSTEM
        $panelSpecs.Children.Add((New-GroupHeader 'Operating System')) | Out-Null
        if ($os) {
            $osName = $os.Caption -replace 'Microsoft ', ''
            $panelSpecs.Children.Add((Add-SpecItem 'OS:' $osName)) | Out-Null
        } else {
            $panelSpecs.Children.Add((Add-SpecItem 'OS:' 'Unable to retrieve')) | Out-Null
        }

        if ($lic) {
            $actStatus = 'Activated'
            $actColor = '#107C10'
        } elseif ($null -ne $lic) {
            $actStatus = 'Not Activated'
            $actColor = '#D83B01'
        } else {
            $actStatus = 'Unknown'
            $actColor = '#666666'
        }
        $panelSpecs.Children.Add((Add-SpecItem 'Activation Status:' $actStatus $actColor)) | Out-Null
        Step-SpecsProgress 'OS'

        # 3. CPU
        $panelSpecs.Children.Add((New-GroupHeader 'Processor')) | Out-Null
        if ($cpu) {
            $cpuInfo = "$($cpu.Name) ($($cpu.NumberOfCores) cores, $($cpu.NumberOfLogicalProcessors) threads)"
            $panelSpecs.Children.Add((Add-SpecItem 'CPU:' $cpuInfo)) | Out-Null
        } else {
            $panelSpecs.Children.Add((Add-SpecItem 'CPU:' 'Unable to retrieve')) | Out-Null
        }
        Step-SpecsProgress 'CPU'

        # 4. MEMORY
        $panelSpecs.Children.Add((New-GroupHeader 'Memory')) | Out-Null
        if ($ram) {
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
            $ramInfo = "${totalRAM} GB ${ramType} @ ${ramSpeed} MHz"
            $panelSpecs.Children.Add((Add-SpecItem 'Total RAM:' $ramInfo)) | Out-Null
        } else {
            $panelSpecs.Children.Add((Add-SpecItem 'RAM:' 'Unable to retrieve')) | Out-Null
        }
        Step-SpecsProgress 'Memory'

        # 5. STORAGE
        $panelSpecs.Children.Add((New-GroupHeader 'Storage')) | Out-Null
        try {
            $disks = Get-CimInstance Win32_DiskDrive | Sort-Object Index
            $partitions = Get-CimInstance Win32_DiskPartition
            $logicalDisks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }

            $partitionToLogical = @{}
            foreach ($partition in $partitions) {
                try {
                    $logicalForPartition = Get-CimAssociatedInstance -InputObject $partition -ResultClassName Win32_LogicalDisk
                    $partitionToLogical[$partition.DeviceID] = @($logicalForPartition)
                } catch {
                    $partitionToLogical[$partition.DeviceID] = @()
                }
            }

            foreach ($disk in $disks) {
                $sizeGB = [math]::Round($disk.Size / 1GB, 1)
                $logicalParts = @()

                $diskPartitions = $partitions | Where-Object { $_.DiskIndex -eq $disk.Index }
                foreach ($part in $diskPartitions) {
                    $mappedLogicalDisks = $partitionToLogical[$part.DeviceID]
                    foreach ($ld in $mappedLogicalDisks) {
                        $ldGB = [math]::Round($ld.Size / 1GB, 0)
                        $logicalParts += "$($ld.DeviceID) $ldGB GB"
                    }
                }

                $partStr = if ($logicalParts.Count -gt 0) {
                    ' (' + (($logicalParts | Select-Object -Unique) -join ' | ') + ')'
                } else {
                    ''
                }

                $diskInfo = "$($disk.Model) - ${sizeGB} GB${partStr}"
                $panelSpecs.Children.Add((Add-SpecItem "Disk $($disk.Index):" $diskInfo)) | Out-Null
            }
        } catch {
            $panelSpecs.Children.Add((Add-SpecItem 'Storage:' 'Unable to retrieve')) | Out-Null
        }
        Step-SpecsProgress 'Storage'

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
                $refreshRate = Get-DisplayRefreshRate $screen.DeviceName
                $refreshText = if ($refreshRate) { "${refreshRate}Hz" } else { 'Unknown refresh rate' }
                $monInfo = "$($screen.Bounds.Width)x$($screen.Bounds.Height) @ ${refreshText}${isPrimary}"
                $panelSpecs.Children.Add((Add-SpecItem "Monitor $monIndex`:" $monInfo)) | Out-Null
            }
        } catch {
            $panelSpecs.Children.Add((Add-SpecItem 'Graphics:' 'Unable to retrieve')) | Out-Null
        }
        Step-SpecsProgress 'Graphics'

        # 7. NETWORK
        $panelSpecs.Children.Add((New-GroupHeader 'Network Controllers')) | Out-Null
        try {
            $adapters = Get-NetAdapter | Where-Object { $_.Status -ne 'Disabled' }

            foreach ($adapter in $adapters) {
                $adapterType = if ($adapter.Name -match 'Wi-Fi|Wireless') { 'WiFi' } else { 'Ethernet' }
                $status = if ($adapter.Status -eq 'Up') { 'Connected' } else { 'Disconnected' }
                $statusColor = if ($adapter.Status -eq 'Up') { '#107C10' } else { '#D83B01' }

                $speed = if ($adapter.LinkSpeed) {
                    if ($adapter.LinkSpeed -match 'Gbps') {
                        $adapter.LinkSpeed
                    } else {
                        $adapter.LinkSpeed
                    }
                } else {
                    'N/A'
                }

                $adapterInfo = "$($adapter.InterfaceDescription) | ${speed} | ${status}"
                $panelSpecs.Children.Add((Add-SpecItem "$adapterType`:" $adapterInfo $statusColor)) | Out-Null
            }
        } catch {
            $panelSpecs.Children.Add((Add-SpecItem 'Network:' 'Unable to retrieve')) | Out-Null
        }
        Step-SpecsProgress 'Network'

        # Reset progress bar when done
        $progressBar.Value = 0
        $progressBar.Maximum = 100
        $lblStatus.Text = 'Ready.'
    }
})

# =====================================================================
# RUN WPF
# =====================================================================
$window.ShowDialog() | Out-Null
