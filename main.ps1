# main.ps1 - GUI WPF cho WinSetup Pro

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# --- Duong dan config ---
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue
if (-not $scriptDir) {
    # Khi chay qua irm | iex, dung duong dan tam
    $scriptDir = $env:TEMP
    $configPath = Join-Path $scriptDir 'winsetup-config.json'
    # Tai apps.json tu GitHub
    $configUrl = 'https://raw.githubusercontent.com/mson-ssh/windowssetup/main/config/apps.json'
    try {
        Invoke-RestMethod $configUrl | Set-Content $configPath -Encoding UTF8
    } catch {
        Write-Host "[!] Khong the tai config tu GitHub: $_" -ForegroundColor Red
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
    Title="WinSetup Pro v1.0"
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

            <TabItem Header="&#x1F4E6;  C&#xE0;i ph&#x1EA7;n m&#x1EC1;m">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
                        <StackPanel x:Name="panelApps" Margin="0,4,0,4"/>
                    </ScrollViewer>
                    <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,10,0,0">
                        <Button x:Name="btnSelectAll" Content="Ch&#x1ECD;n t&#x1EA5;t c&#x1EA3;" Width="110" Margin="0,0,8,0" Background="#0078D4"/>
                        <Button x:Name="btnDeselectAll" Content="B&#x1EE3; ch&#x1ECD;n" Width="90" Background="#6C757D"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="&#x1F511;  K&#xED;ch ho&#x1EA1;t">
                <StackPanel Margin="20,16,20,16">
                    <TextBlock x:Name="lblActStatus" FontSize="14" Margin="0,0,0,20"
                               Foreground="#444444" Text="&#x110;ang ki&#x1EC3;m tra tr&#x1EA1;ng th&#xE1;i..."/>
                    <TextBlock Text="Ch&#x1ECD;n ph&#x01B0;&#x01A1;ng ph&#xE1;p:" Foreground="#666666" FontSize="12" Margin="0,0,0,8"/>
                    <RadioButton x:Name="rbHWID"   Content="HWID  &#x2014;  V&#x129;nh vi&#x1EC5;n, g&#x1EAF;n v&#x1EDB;i ph&#x1EA7;n c&#x1EE9;ng (Windows 10/11)" IsChecked="True"/>
                    <RadioButton x:Name="rbKMS38"  Content="KMS38  &#x2014;  &#x110;&#x1EBF;n n&#x103;m 2038, t&#x1EF1; gia h&#x1EA1;n"/>
                    <RadioButton x:Name="rbOhook"  Content="Ohook  &#x2014;  Microsoft 365, offline"/>
                    <Button x:Name="btnActivate" Content="K&#xED;ch ho&#x1EA1;t ngay"
                            Width="160" HorizontalAlignment="Left" Margin="0,20,0,0"
                            Background="#0078D4" Foreground="White"/>
                </StackPanel>
            </TabItem>

            <TabItem Header="&#x26A1;  T&#x1ED1;i &#x01B0;u">
                <Grid Margin="12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <StackPanel Grid.Row="0" x:Name="panelOptimize" Margin="8,8,8,8"/>
                    <Button Grid.Row="1" x:Name="btnDryRun"
                            Content="Dry Run (Test &#x2014; kh&#xF4;ng thay &#x111;&#x1ED5;i h&#x1EC7; th&#x1ED1;ng)"
                            HorizontalAlignment="Left" Margin="8,8,0,0"
                            Background="#6C757D" Width="280"/>
                </Grid>
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
                       Text="S&#x1EB5;n s&#xE0;ng." Foreground="#666666"
                       FontSize="12" VerticalAlignment="Center"/>
            <Button Grid.Column="1" x:Name="btnLog"
                    Content="Xem Log" Width="80" Margin="8,0,8,0"
                    Background="#6C757D"/>
            <Button Grid.Column="2" x:Name="btnRun"
                    Content="Ch&#x1EA1;y t&#x1EA5;t c&#x1EA3;" Width="100"
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
$lblActStatus = $window.FindName('lblActStatus')
$rbHWID       = $window.FindName('rbHWID')
$rbKMS38      = $window.FindName('rbKMS38')
$rbOhook      = $window.FindName('rbOhook')
$btnActivate  = $window.FindName('btnActivate')
$btnSelectAll = $window.FindName('btnSelectAll')
$btnDeselect  = $window.FindName('btnDeselectAll')
$btnDryRun    = $window.FindName('btnDryRun')
$progressBar  = $window.FindName('progressBar')
$lblStatus    = $window.FindName('lblStatus')
$btnRun       = $window.FindName('btnRun')
$btnLog       = $window.FindName('btnLog')

# =====================================================================
# HELPER: tao tieu de nhom
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
# TAB 1: Load app tu apps.json
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

# =====================================================================
# TAB 2: Trang thai kich hoat
# =====================================================================
try {
    $actStatus = Get-ActivationStatus
    $lblActStatus.Text       = "Trang thai: $actStatus"
    $lblActStatus.Foreground = if ($actStatus -eq 'Da kich hoat') {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#107C10')
    } else {
        [System.Windows.Media.BrushConverter]::new().ConvertFromString('#D83B01')
    }
} catch {
    $lblActStatus.Text = 'Trang thai: Khong xac dinh'
}

$btnActivate.Add_Click({
    $method = if ($rbHWID.IsChecked) { 'HWID' } elseif ($rbKMS38.IsChecked) { 'KMS38' } else { 'Ohook' }
    $r = [System.Windows.MessageBox]::Show(
        "Xac nhan kich hoat bang $method?", 'WinSetup Pro',
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question)
    if ($r -eq 'Yes') {
        $lblStatus.Text = "Dang kich hoat ($method)..."
        Invoke-Activation -Method $method
        $lblStatus.Text = 'Kich hoat hoan tat!'
    }
})

# =====================================================================
# TAB 3: Toi uu he thong
# =====================================================================
$optimizeTasks = @(
    @{ Name='Tat Telemetry';         Func='Disable-Telemetry';    Safe=$true  }
    @{ Name='Tat Cortana';           Func='Disable-Cortana';      Safe=$true  }
    @{ Name='High Performance Plan'; Func='Set-PowerPlan';        Safe=$true  }
    @{ Name='Xoa file tam';          Func='Clear-TempFiles';      Safe=$true  }
    @{ Name='Bat Dark Mode';         Func='Enable-DarkMode';      Safe=$true  }
    @{ Name='Cai dat Explorer';      Func='Set-ExplorerSettings'; Safe=$true  }
    @{ Name='Go bo Bloatware';       Func='Disable-Bloatware';    Safe=$false }
    @{ Name='Tat Startup Apps';      Func='Disable-StartupApps';  Safe=$false }
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
    $lblStatus.Text = 'Dang chay Dry Run...'
    foreach ($task in $optimizeTasks) {
        if ($optCheckboxes[$task.Func].IsChecked) { & $task.Func -DryRun }
    }
    $lblStatus.Text = 'Dry Run hoan tat. Xem log de kiem tra.'
})

# =====================================================================
# NUT CHAY TAT CA
# =====================================================================
$btnRun.Add_Click({
    $selectedApps = @()
    foreach ($cb in $appCheckboxes.Values) {
        if ($cb.IsChecked) { $selectedApps += $cb.Tag }
    }
    $selectedOpts = @($optimizeTasks | Where-Object { $optCheckboxes[$_.Func].IsChecked })
    $total = $selectedApps.Count + $selectedOpts.Count

    if ($total -eq 0) {
        [System.Windows.MessageBox]::Show('Chua chon gi ca!', 'WinSetup Pro') | Out-Null
        return
    }

    $progressBar.Maximum = $total
    $progressBar.Value   = 0
    $done = 0

    if ($selectedApps.Count -gt 0) {
        $lblStatus.Text = 'Dang cai phan mem...'
        Install-Apps -Apps $selectedApps
        $done += $selectedApps.Count
        $progressBar.Value = $done
    }

    foreach ($task in $selectedOpts) {
        $lblStatus.Text = "Dang chay: $($task.Name)..."
        & $task.Func
        $done++
        $progressBar.Value = $done
        $window.Dispatcher.Invoke([action]{}, 'Background')
    }

    $lblStatus.Text = 'Hoan tat!'
    [System.Windows.MessageBox]::Show('Da hoan thanh tat ca tac vu!', 'WinSetup Pro',
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information) | Out-Null
})

# =====================================================================
# NUT XEM LOG
# =====================================================================
$btnLog.Add_Click({
    if (Test-Path $logPath) {
        Start-Process notepad $logPath
    } else {
        [System.Windows.MessageBox]::Show('Chua co file log.', 'WinSetup Pro') | Out-Null
    }
})

# =====================================================================
# CHAY WPF
# =====================================================================
$window.ShowDialog() | Out-Null
