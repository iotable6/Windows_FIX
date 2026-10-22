# Windows 11 Troubleshooting and Repair Guide

A collection of built-in Windows 11 commands for diagnosing and repairing common system problems.

## 1. System File Repair

Open **Windows Terminal as Administrator**.

Check and repair protected system files:

```powershell
sfc /scannow
```

Repair the Windows component store:

```powershell
DISM /Online /Cleanup-Image /RestoreHealth
```

Recommended order:
1. Run DISM.
2. Run SFC.
3. Restart Windows if necessary.

## 2. Network Troubleshooting

Reset the DNS resolver cache:

```powershell
ipconfig /flushdns
```

Release and renew the DHCP address:

```powershell
ipconfig /release
ipconfig /renew
```

Reset the Winsock catalog:

```powershell
netsh winsock reset
```

Reset the TCP/IP stack:

```powershell
netsh int ip reset
```

Restart the computer after network stack resets if required.

**Note:** Resetting network settings may affect VPN clients and custom network configurations.

## 3. Disk Error Checking

Scan the system drive for file system errors:

```powershell
chkdsk C: /scan
```

For offline repairs that require exclusive access:

```powershell
chkdsk C: /f
```

Windows may ask to schedule the repair for the next restart.

## 4. Windows Update Troubleshooting

Restart Windows Update services:

```powershell
Stop-Service wuauserv -Force
Stop-Service bits -Force

Start-Service bits
Start-Service wuauserv
```

If Windows Update continues to fail, inspect the Windows Update error code and logs before resetting its cache.

Avoid deleting update files or resetting update components without first checking the cause.

## 5. Check Running Services

Display stopped automatic services:

```powershell
Get-CimInstance Win32_Service |
Where-Object {
    $_.StartMode -eq "Auto" -and $_.State -ne "Running"
} |
Select-Object Name, DisplayName, State
```

A stopped service is not necessarily a problem. Some services start only when needed or may fail because of a dependency.

## 6. Check Disk Space

Display free space on local drives:

```powershell
Get-Volume |
Select-Object DriveLetter, FileSystemLabel,
@{Name="FreeSpaceGB";Expression={
    if ($_.SizeRemaining -ne $null) {
        [math]::Round($_.SizeRemaining / 1GB, 2)
    }
}}
```

Low disk space can cause update failures, application errors, and performance problems.

## 7. Diagnose System Errors

Open Event Viewer:

```powershell
eventvwr.msc
```

Open Reliability Monitor:

```powershell
perfmon /rel
```

Display recent critical system events:

```powershell
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Level = 1, 2
} -MaxEvents 20 |
Select-Object TimeCreated, ProviderName, Id, Message
```

Review the error details before making changes.

## 8. Basic System Information

Display Windows version information:

```powershell
winver
```

Display operating system details:

```powershell
Get-ComputerInfo |
Select-Object WindowsProductName, WindowsVersion,
OsBuildNumber, OsArchitecture
```

Display IP configuration:

```powershell
ipconfig /all
```

Display network connectivity:

```powershell
Test-NetConnection 1.1.1.1 -Port 443
```

## 9. Important Safety Notes

- Run administrative commands only when necessary.
- Review command output before applying additional repairs.
- Create a backup before performing major system repairs.
- Do not disable Windows Defender or the firewall as a general troubleshooting step.
- Do not reset network settings without considering VPNs, static IP addresses, and custom routes.
- Commands may require different procedures depending on the Windows version and environment.
- On corporate computers, follow your organization's IT policies.

## Disclaimer

This repository provides general Windows 11 troubleshooting guidance. Commands should be tested in a controlled environment before being used on production or corporate systems.

Always investigate the root cause before applying repairs.

## Contributing

Suggestions, corrections, and tested troubleshooting procedures are welcome.

**Platform:** Windows 11  
**Tools:** Windows Terminal, PowerShell, DISM, SFC, CHKDSK, Event Viewer  
**Purpose:** System diagnostics and troubleshooting
