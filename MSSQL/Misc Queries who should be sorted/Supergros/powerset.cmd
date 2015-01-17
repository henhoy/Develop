echo Testing Windows version
echo off
REM Check Windows Version
ver | findstr /i "5\.0\." > nul
IF %ERRORLEVEL% EQU 0 goto ver_2000
ver | findstr /i "5\.1\." > nul
IF %ERRORLEVEL% EQU 0 goto ver_XP
ver | findstr /i "5\.2\." > nul
IF %ERRORLEVEL% EQU 0 goto ver_2003
ver | findstr /i "6\.0\." > nul
IF %ERRORLEVEL% EQU 0 goto ver_Vista_2008
ver | findstr /i "6\.1\." > nul
IF %ERRORLEVEL% EQU 0 goto ver_Win7_2008R2
ver | findstr /i "6\.2\." > nul
IF %ERRORLEVEL% EQU 0 goto ver_Win8_2012
ver | findstr /i "6\.3\." > nul
IF %ERRORLEVEL% EQU 0 goto ver_Win81_2012R2
goto warn_and_exit

:ver_Win81_2012R2
:ver_Win8_2012
:ver_Win7_2008R2
:ver_Vista_2008
REM Run Windows 7 specific commands here
echo OS Version: Windows Vista/7/8/8.1 or Windows Server 2008/2008R2/2012/2012R2
echo Setting Power Scheme to "High Performance"
for /f "tokens=4,5 skip=1" %%a in ('powercfg -l') Do (if "%%b"=="(High" set pquid=%%a)
powercfg -s %pquid%
powercfg -l
goto end


:ver_2003
:ver_XP
:ver_2000
REM Run Windows 2000 specific commands here
echo OS Version: Windows 2000
echo Setting Power Scheme not applicable
goto end

:warn_and_exit
echo Machine OS cannot be determined.

:end  