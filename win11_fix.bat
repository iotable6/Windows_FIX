
@echo off
setlocal EnableExtensions
title Windows 11 Repair Toolkit - CMD Edition
color 0B

:: Request Administrator privileges
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Administrator privileges required.
    echo Restarting as Administrator...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "LOGDIR=%ProgramData%\Win11Repair"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set "LOG=%LOGDIR%\Repair-Log.txt"

:MENU
cls
echo =================================================
echo          WINDOWS 11 REPAIR TOOLKIT
echo                  CMD EDITION
echo =================================================
echo.
echo  [1] Repair Windows Image - DISM
echo  [2] Repair System Files - SFC
echo  [3] Complete System Repair
echo  [4] Check System Drive
echo  [5] Show Network Configuration
echo  [6] Flush DNS Cache
echo  [7] Test Internet Connection
echo  [8] Reset Winsock and TCP/IP
echo  [9] Check Windows Update Services
echo [10] Restart Windows Update Services
echo [11] Show System Information
echo [12] Open Event Viewer
echo [13] Open Reliability Monitor
echo [14] Show Disk Free Space
echo [15] Open Log Folder
echo.
echo  [0] Exit
echo =================================================
echo.
set /p "CHOICE=Enter menu number: "

if "%CHOICE%"=="1" goto DISM
if "%CHOICE%"=="2" goto SFC
if "%CHOICE%"=="3" goto FULLREPAIR
if "%CHOICE%"=="4" goto CHKDSK
if "%CHOICE%"=="5" goto NETWORK
if "%CHOICE%"=="6" goto DNS
if "%CHOICE%"=="7" goto INTERNET
if "%CHOICE%"=="8" goto NETRESET
if "%CHOICE%"=="9" goto UPDATECHECK
if "%CHOICE%"=="10" goto UPDATERESTART
if "%CHOICE%"=="11" goto SYSINFO
if "%CHOICE%"=="12" goto EVENTVIEWER
if "%CHOICE%"=="13" goto RELIABILITY
if "%CHOICE%"=="14" goto DISKSPACE
if "%CHOICE%"=="15" goto LOGFOLDER
if "%CHOICE%"=="0" goto EXIT

echo Invalid selection.
pause
goto MENU

:DISM
cls
echo Running DISM RestoreHealth...
echo [%date% %time%] DISM started >> "%LOG%"
DISM /Online /Cleanup-Image /RestoreHealth
echo [%date% %time%] DISM finished with code %errorlevel% >> "%LOG%"
pause
goto MENU

:SFC
cls
echo Running System File Checker...
echo [%date% %time%] SFC started >> "%LOG%"
sfc /scannow
echo [%date% %time%] SFC finished with code %errorlevel% >> "%LOG%"
pause
goto MENU

:FULLREPAIR
cls
echo This runs DISM followed by SFC.
choice /c YN /m "Continue"
if errorlevel 2 goto MENU
echo [%date% %time%] Full repair started >> "%LOG%"
DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow
echo [%date% %time%] Full repair finished >> "%LOG%"
pause
goto MENU

:CHKDSK
cls
echo Checking the Windows drive for file system errors...
chkdsk %SystemDrive% /scan
echo [%date% %time%] CHKDSK scan completed >> "%LOG%"
pause
goto MENU

:NETWORK
cls
ipconfig /all
pause
goto MENU

:DNS
cls
ipconfig /flushdns
echo [%date% %time%] DNS cache flushed >> "%LOG%"
pause
goto MENU

:INTERNET
cls
echo Testing DNS resolution...
nslookup www.microsoft.com
echo.
echo Testing HTTPS connectivity...
powershell -NoProfile -Command "Test-NetConnection www.microsoft.com -Port 443"
pause
goto MENU

:NETRESET
cls
echo WARNING: This can affect VPNs and custom network settings.
choice /c YN /m "Reset Winsock and TCP/IP"
if errorlevel 2 goto MENU
netsh winsock reset
netsh int ip reset
echo A restart may be required.
echo [%date% %time%] Network reset commands executed >> "%LOG%"
pause
goto MENU

:UPDATECHECK
cls
echo Windows Update service status:
sc query wuauserv
echo.
echo Background Intelligent Transfer Service:
sc query bits
echo.
echo Cryptographic Services:
sc query cryptsvc
pause
goto MENU

:UPDATERESTART
cls
echo This restarts Windows Update and BITS services.
choice /c YN /m "Continue"
if errorlevel 2 goto MENU
net stop wuauserv
net stop bits
net start bits
net start wuauserv
echo [%date% %time%] Update services restart attempted >> "%LOG%"
pause
goto MENU

:SYSINFO
cls
systeminfo
echo.
echo Windows version:
ver
pause
goto MENU

:EVENTVIEWER
start eventvwr.msc
goto MENU

:RELIABILITY
start perfmon /rel
goto MENU

:DISKSPACE
cls
wmic logicaldisk get caption,freespace,size
pause
goto MENU

:LOGFOLDER
start "" explorer.exe "%LOGDIR%"
goto MENU

:EXIT
echo Exiting Windows 11 Repair Toolkit.
endlocal
exit /b
