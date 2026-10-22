# Windows11-Repair-GUI.ps1
# Windows 11 Repair Toolkit - WPF graphical interface

$ErrorActionPreference = "Continue"

# Relaunch as Administrator if needed
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`""
    )
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$logDir = Join-Path $env:ProgramData "Win11Repair"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$script:logFile = Join-Path $logDir ("GUI-Repair-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows 11 Repair Toolkit" Height="760" Width="1120"
        MinHeight="650" MinWidth="960" WindowStartupLocation="CenterScreen"
        Background="#F3F6FB" FontFamily="Segoe UI">
  <Grid Margin="14">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="210"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" Background="#142B45" CornerRadius="12"
            Padding="18" Margin="0,0,0,12">
      <DockPanel>
        <StackPanel>
          <TextBlock Text="Windows 11 Repair Toolkit"
                     Foreground="White" FontSize="25" FontWeight="Bold"/>
          <TextBlock Text="Diagnose • Repair • Review logs"
                     Foreground="#C7D8EA" FontSize="13" Margin="0,5,0,0"/>
        </StackPanel>
        <TextBlock x:Name="SystemInfo" DockPanel.Dock="Right"
                   Foreground="#EAF2FA" FontSize="12" TextAlignment="Right"
                   VerticalAlignment="Center" TextWrapping="Wrap" Width="360"/>
      </DockPanel>
    </Border>

    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <Grid.RowDefinitions>
        <RowDefinition Height="*"/>
        <RowDefinition Height="*"/>
      </Grid.RowDefinitions>

      <Border Grid.Column="0" Grid.Row="0"
              Style="{StaticResource CardStyle}" Margin="0,0,8,8">
        <StackPanel>
          <TextBlock Text="System Repair" FontSize="18"
                     FontWeight="SemiBold" Foreground="#173B65"/>
          <TextBlock Text="Repair Windows components and protected system files."
                     TextWrapping="Wrap" Margin="0,6,0,10"/>
          <Button x:Name="BtnDISM" Content="Run DISM RestoreHealth"
                  Style="{StaticResource BlueButton}"/>
          <Button x:Name="BtnSFC" Content="Run SFC /scannow"
                  Style="{StaticResource BlueButton}"/>
          <Button x:Name="BtnSystemRepair" Content="Run DISM + SFC"
                  Style="{StaticResource BlueButton}"/>
        </StackPanel>
      </Border>

      <Border Grid.Column="1" Grid.Row="0"
              Style="{StaticResource CardStyle}" Margin="0,0,8,8">
        <StackPanel>
          <TextBlock Text="Network Repair" FontSize="18"
                     FontWeight="SemiBold" Foreground="#173B65"/>
          <TextBlock Text="Check connectivity or reset selected network components."
                     TextWrapping="Wrap" Margin="0,6,0,10"/>
          <Button x:Name="BtnIPConfig" Content="Show IP Configuration"
                  Style="{StaticResource GreenButton}"/>
          <Button x:Name="BtnDNS" Content="Flush DNS Cache"
                  Style="{StaticResource GreenButton}"/>
          <Button x:Name="BtnNetReset" Content="Reset Winsock + TCP/IP"
                  Style="{StaticResource GreenButton}"/>
          <Button x:Name="BtnConnectivity" Content="Test DNS and HTTPS"
                  Style="{StaticResource GreenButton}"/>
        </StackPanel>
      </Border>

      <Border Grid.Column="2" Grid.Row="0"
              Style="{StaticResource CardStyle}" Margin="0,0,0,8">
        <StackPanel>
          <TextBlock Text="Disk &amp; Storage" FontSize="18"
                     FontWeight="SemiBold" Foreground="#173B65"/>
          <TextBlock Text="Check file-system health and available disk space."
                     TextWrapping="Wrap" Margin="0,6,0,10"/>
          <Button x:Name="BtnCHKDSK" Content="Run CHKDSK /scan"
                  Style="{StaticResource PurpleButton}"/>
          <Button x:Name="BtnDiskSpace" Content="Check Free Disk Space"
                  Style="{StaticResource PurpleButton}"/>
          <Button x:Name="BtnDiskHealth" Content="Check Physical Disk Health"
                  Style="{StaticResource PurpleButton}"/>
        </StackPanel>
      </Border>

      <Border Grid.Column="0" Grid.Row="1"
              Style="{StaticResource CardStyle}" Margin="0,0,8,0">
        <StackPanel>
          <TextBlock Text="Windows Update" FontSize="18"
                     FontWeight="SemiBold" Foreground="#173B65"/>
          <TextBlock Text="Inspect or restart common update services."
                     TextWrapping="Wrap" Margin="0,6,0,10"/>
          <Button x:Name="BtnUpdateServices" Content="Check Update Services"
                  Style="{StaticResource BlueButton}"/>
          <Button x:Name="BtnRestartUpdate" Content="Restart Update + BITS"
                  Style="{StaticResource BlueButton}"/>
        </StackPanel>
      </Border>

      <Border Grid.Column="1" Grid.Row="1"
              Style="{StaticResource CardStyle}" Margin="0,0,8,0">
        <StackPanel>
          <TextBlock Text="Devices &amp; Security" FontSize="18"
                     FontWeight="SemiBold" Foreground="#173B65"/>
          <TextBlock Text="Find device errors and inspect Defender status."
                     TextWrapping="Wrap" Margin="0,6,0,10"/>
          <Button x:Name="BtnDevices" Content="List Devices with Errors"
                  Style="{StaticResource OrangeButton}"/>
          <Button x:Name="BtnDefender" Content="Check Defender Status"
                  Style="{StaticResource OrangeButton}"/>
          <Button x:Name="BtnServices" Content="Check Key Services"
                  Style="{StaticResource OrangeButton}"/>
        </StackPanel>
      </Border>

      <Border Grid.Column="2" Grid.Row="1"
              Style="{StaticResource CardStyle}" Margin="0">
        <StackPanel>
          <TextBlock Text="Logs &amp; Tools" FontSize="18"
                     FontWeight="SemiBold" Foreground="#173B65"/>
          <TextBlock Text="Review crashes, open logs, or collect basic diagnostics."
                     TextWrapping="Wrap" Margin="0,6,0,10"/>
          <Button x:Name="BtnReliability" Content="Open Reliability Monitor"
                  Style="{StaticResource GrayButton}"/>
          <Button x:Name="BtnEventViewer" Content="Open Event Viewer"
                  Style="{StaticResource GrayButton}"/>
          <Button x:Name="BtnLogs" Content="Open Log Folder"
                  Style="{StaticResource GrayButton}"/>
          <Button x:Name="BtnSaveLog" Content="Save Visible Log"
                  Style="{StaticResource GrayButton}"/>
        </StackPanel>
      </Border>
    </Grid>

    <Border Grid.Row="2" Background="#0D1B2A" CornerRadius="10"
            Padding="10" Margin="0,12,0,8">
      <DockPanel>
        <TextBlock DockPanel.Dock="Top" Text="Activity Log"
                   Foreground="#FFFFFF" FontSize="14" FontWeight="SemiBold"
                   Margin="2,0,0,8"/>
        <TextBox x:Name="LogBox" Background="#0D1B2A"
                 Foreground="#D8F3DC" BorderThickness="0"
                 FontFamily="Consolas" FontSize="12" IsReadOnly="True"
                 AcceptsReturn="True" VerticalScrollBarVisibility="Auto"
                 HorizontalScrollBarVisibility="Auto" TextWrapping="NoWrap"/>
      </DockPanel>
    </Border>

    <DockPanel Grid.Row="3" Margin="2,2,2,0">
      <TextBlock x:Name="StatusText" Text="Ready"
                 Foreground="#34495E" VerticalAlignment="Center"/>
      <Button x:Name="BtnClearLog" DockPanel.Dock="Right"
              Content="Clear Log" Padding="14,6" Margin="6,0,0,0"/>
      <TextBlock DockPanel.Dock="Right"
                 Text="Log: C:\ProgramData\Win11Repair"
                 Foreground="#64748B" VerticalAlignment="Center"
                 Margin="0,0,10,0"/>
    </DockPanel>
  </Grid>

  <Window.Resources>
    <Style x:Key="CardStyle" TargetType="Border">
      <Setter Property="Background" Value="White"/>
      <Setter Property="BorderBrush" Value="#D6E0EB"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="10"/>
      <Setter Property="Padding" Value="14"/>
    </Style>
    <Style x:Key="BaseButton" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Padding" Value="9,7"/>
      <Setter Property="Margin" Value="0,3,0,3"/>
      <Setter Property="HorizontalContentAlignment" Value="Center"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
    <Style x:Key="BlueButton" TargetType="Button"
           BasedOn="{StaticResource BaseButton}">
      <Setter Property="Background" Value="#1769D2"/>
    </Style>
    <Style x:Key="GreenButton" TargetType="Button"
           BasedOn="{StaticResource BaseButton}">
      <Setter Property="Background" Value="#168A55"/>
    </Style>
    <Style x:Key="PurpleButton" TargetType="Button"
           BasedOn="{StaticResource BaseButton}">
      <Setter Property="Background" Value="#6842C2"/>
    </Style>
    <Style x:Key="OrangeButton" TargetType="Button"
           BasedOn="{StaticResource BaseButton}">
      <Setter Property="Background" Value="#C56A16"/>
    </Style>
    <Style x:Key="GrayButton" TargetType="Button"
           BasedOn="{StaticResource BaseButton}">
      <Setter Property="Background" Value="#42566E"/>
    </Style>
  </Window.Resources>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$controlNames = @(
    "SystemInfo","LogBox","StatusText","BtnDISM","BtnSFC","BtnSystemRepair",
    "BtnIPConfig","BtnDNS","BtnNetReset","BtnConnectivity","BtnCHKDSK","BtnDiskSpace",
    "BtnDiskHealth","BtnUpdateServices","BtnRestartUpdate","BtnDevices","BtnDefender",
    "BtnServices","BtnReliability","BtnEventViewer","BtnLogs","BtnSaveLog","BtnClearLog"
)

$ui = @{}
foreach ($name in $controlNames) {
    $ui[$name] = $window.FindName($name)
}

$os = Get-CimInstance Win32_OperatingSystem
$ui.SystemInfo.Text = "$($os.Caption) | Build $($os.BuildNumber)`nComputer: $env:COMPUTERNAME | Elevated session"
$script:busy = $false

function Add-Log {
    param([string]$Text, [string]$Level = "INFO")

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "HH:mm:ss"), $Level, $Text
    $ui.LogBox.AppendText($line + [Environment]::NewLine)
    $ui.LogBox.ScrollToEnd()
    $ui.StatusText.Text = $Text
    Add-Content -Path $script:logFile -Value $line
    [System.Windows.Forms.Application]::DoEvents()
}

function Ask-Confirm {
    param([string]$Message)

    $result = [System.Windows.MessageBox]::Show(
        $window, $Message, "Confirm action",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    return ($result -eq [System.Windows.MessageBoxResult]::Yes)
}

function Invoke-Tool {
    param(
        [string]$Title,
        [scriptblock]$Action,
        [switch]$NeedsConfirm,
        [string]$Warning
    )

    if ($script:busy) {
        [System.Windows.MessageBox]::Show(
            $window, "Another task is running. Please wait.", "Busy"
        ) | Out-Null
        return
    }

    if ($NeedsConfirm -and -not (Ask-Confirm $Warning)) {
        Add-Log "$Title cancelled by user." "WARN"
        return
    }

    $script:busy = $true
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    Add-Log "Starting: $Title"

    try {
        & $Action 2>&1 | ForEach-Object {
            $text = "$_"
            $ui.LogBox.AppendText($text + [Environment]::NewLine)
            Add-Content -Path $script:logFile -Value $text
            $ui.LogBox.ScrollToEnd()
            [System.Windows.Forms.Application]::DoEvents()
        }
        Add-Log "Finished: $Title"
    }
    catch {
        Add-Log "$Title failed: $($_.Exception.Message)" "ERROR"
    }
    finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        $script:busy = $false
    }
}

function Run-Native {
    param([string]$Exe, [string[]]$Args)

    & $Exe @Args 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "$([IO.Path]::GetFileName($Exe)) returned exit code $LASTEXITCODE"
    }
}

# System repair
$ui.BtnDISM.Add_Click({
    Invoke-Tool "DISM RestoreHealth" {
        Run-Native "$env:SystemRoot\System32\DISM.exe" @(
            "/Online", "/Cleanup-Image", "/RestoreHealth"
        )
    } -NeedsConfirm -Warning "Run DISM RestoreHealth? This can take several minutes and may use Windows Update."
})

$ui.BtnSFC.Add_Click({
    Invoke-Tool "System File Checker" {
        Run-Native "$env:SystemRoot\System32\sfc.exe" @("/scannow")
    } -NeedsConfirm -Warning "Run SFC /scannow to scan and repair protected Windows system files?"
})

$ui.BtnSystemRepair.Add_Click({
    Invoke-Tool "DISM + SFC repair" {
        Run-Native "$env:SystemRoot\System32\DISM.exe" @(
            "/Online", "/Cleanup-Image", "/RestoreHealth"
        )
        Run-Native "$env:SystemRoot\System32\sfc.exe" @("/scannow")
    } -NeedsConfirm -Warning "Run DISM RestoreHealth followed by SFC /scannow? This may take a long time."
})

# Network
$ui.BtnIPConfig.Add_Click({
    Invoke-Tool "IP configuration" {
        Run-Native "$env:SystemRoot\System32\ipconfig.exe" @("/all")
    }
})

$ui.BtnDNS.Add_Click({
    Invoke-Tool "Flush DNS cache" {
        Clear-DnsClientCache
        "DNS resolver cache flushed."
    } -NeedsConfirm -Warning "Flush the local DNS resolver cache?"
})

$ui.BtnNetReset.Add_Click({
    Invoke-Tool "Winsock and TCP/IP reset" {
        Run-Native "$env:SystemRoot\System32\netsh.exe" @("winsock", "reset")
        Run-Native "$env:SystemRoot\System32\netsh.exe" @("int", "ip", "reset")
        "A Windows restart may be required."
    } -NeedsConfirm -Warning "Reset Winsock and TCP/IP? This can affect VPN software, static IP settings, custom routes, and other network configuration. Continue only if you understand the impact."
})

$ui.BtnConnectivity.Add_Click({
    Invoke-Tool "DNS and HTTPS connectivity test" {
        "DNS lookup:"
        Resolve-DnsName www.microsoft.com -ErrorAction Continue |
            Format-Table Name, Type, IPAddress | Out-String

        "HTTPS connectivity to www.microsoft.com:443:"
        Test-NetConnection www.microsoft.com -Port 443 -WarningAction SilentlyContinue |
            Format-List ComputerName, RemoteAddress, TcpTestSucceeded | Out-String
    }
})

# Disk
$ui.BtnCHKDSK.Add_Click({
    Invoke-Tool "CHKDSK online scan" {
        Run-Native "$env:SystemRoot\System32\chkdsk.exe" @(
            "$env:SystemDrive", "/scan"
        )
    } -NeedsConfirm -Warning "Run CHKDSK /scan on $env:SystemDrive? This performs an online file-system scan."
})

$ui.BtnDiskSpace.Add_Click({
    Invoke-Tool "Disk space report" {
        Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
            Select-Object DeviceID,
                @{N="FreeGB"; E={[math]::Round($_.FreeSpace / 1GB, 2)}},
                @{N="SizeGB"; E={[math]::Round($_.Size / 1GB, 2)}} |
            Format-Table -AutoSize | Out-String
    }
})

$ui.BtnDiskHealth.Add_Click({
    Invoke-Tool "Physical disk health" {
        try {
            Get-PhysicalDisk |
                Select-Object FriendlyName, MediaType, HealthStatus,
                    OperationalStatus,
                    @{N="SizeGB"; E={[math]::Round($_.Size / 1GB, 1)}} |
                Format-Table -AutoSize | Out-String
        }
        catch {
            "Physical disk health query is not supported or available: $($_.Exception.Message)"
        }
    }
})

# Windows Update
$ui.BtnUpdateServices.Add_Click({
    Invoke-Tool "Windows Update service status" {
        foreach ($n in @("wuauserv", "BITS", "CryptSvc")) {
            try {
                Get-Service -Name $n |
                    Select-Object Name, Status, StartType |
                    Format-Table -AutoSize | Out-String
            }
            catch {
                "Could not query service $n"
            }
        }
    }
})

$ui.BtnRestartUpdate.Add_Click({
    Invoke-Tool "Restart Windows Update services" {
        foreach ($n in @("BITS", "wuauserv")) {
            $svc = Get-Service -Name $n -ErrorAction Stop

            if ($svc.Status -eq "Running") {
                Restart-Service -Name $n -Force -ErrorAction Stop
            }
            else {
                Start-Service -Name $n -ErrorAction Stop
            }

            "Handled service: $n"
        }
    } -NeedsConfirm -Warning "Restart the Windows Update and BITS services? Active update/download tasks may be interrupted."
})

# Devices and security
$ui.BtnDevices.Add_Click({
    Invoke-Tool "Devices with errors" {
        $bad = Get-CimInstance Win32_PnPEntity |
            Where-Object { $_.ConfigManagerErrorCode -ne 0 }

        if ($bad) {
            $bad |
                Select-Object Name, PNPClass, ConfigManagerErrorCode |
                Format-Table -AutoSize | Out-String
        }
        else {
            "No devices with reported Configuration Manager errors were found."
        }
    }
})

$ui.BtnDefender.Add_Click({
    Invoke-Tool "Microsoft Defender status" {
        try {
            Get-MpComputerStatus |
                Select-Object AMServiceEnabled, AntivirusEnabled,
                    RealTimeProtectionEnabled, AntivirusSignatureLastUpdated |
                Format-List | Out-String
        }
        catch {
            "Defender status unavailable: $($_.Exception.Message)"
        }
    }
})

$ui.BtnServices.Add_Click({
    Invoke-Tool "Key Windows services" {
        foreach ($n in @(
            "BITS", "wuauserv", "CryptSvc", "Winmgmt", "EventLog",
            "LanmanWorkstation", "Spooler", "Dhcp", "Dnscache"
        )) {
            try {
                $s = Get-Service -Name $n -ErrorAction Stop
                "{0}: {1} (Start type: {2})" -f $s.Name, $s.Status, $s.StartType
            }
            catch {
                "Could not query $n"
            }
        }
    }
})

# Logs and tools
$ui.BtnReliability.Add_Click({
    Start-Process "perfmon.exe" -ArgumentList "/rel"
    Add-Log "Opened Reliability Monitor."
})

$ui.BtnEventViewer.Add_Click({
    Start-Process "eventvwr.msc"
    Add-Log "Opened Event Viewer."
})

$ui.BtnLogs.Add_Click({
    Start-Process explorer.exe -ArgumentList "`"$logDir`""
    Add-Log "Opened log folder."
})

$ui.BtnSaveLog.Add_Click({
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Filter = "Text files (*.txt)|*.txt|Log files (*.log)|*.log"
    $dialog.FileName = "Windows11-Repair-VisibleLog.txt"

    if ($dialog.ShowDialog()) {
        [IO.File]::WriteAllText($dialog.FileName, $ui.LogBox.Text)
        Add-Log "Visible log saved to $($dialog.FileName)"
    }
})

$ui.BtnClearLog.Add_Click({
    $ui.LogBox.Clear()
    Add-Log "Visible log cleared. Previous log file is unchanged."
})

Add-Log "Windows 11 Repair Toolkit started."
Add-Log "Log file: $script:logFile"
Add-Log "Use the buttons to run individual checks. Some operations require confirmation and may take several minutes."

$null = $window.ShowDialog()
