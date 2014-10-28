@ECHO OFF
SET SCRIPT_DIR=C:\miracle_online\script
SET LOG_DIR=C:\miracle_online\log
SET FTP_SERVER=ftp.miracleas.dk
SET FTP_USER=mo-xxx
SET FTP_PWD=pwd2xxx

FOR /f "tokens=1" %%A IN ('cscript.exe //nologo showdate.vbs /withtimestamp:1') DO set DateStamp2=%%A
SET DATESTAMP=%DATESTAMP2:~0,13%
SET DATE_only=%DATESTAMP2:~0,8%

REM Get latest version of checks from FTP server
CD %SCRIPT_DIR%
ftp -s:%script_dir%\get_MSSQL_update.ftp
ftp -s:%Script_Dir%\update_MSSQL_script.ftp

REM Show Update Info
start /wait MSSQL_Update_Info.cmd

REM errorlevel from MSSQL_Update_Info.cmd is 1 then exit run_check
IF %ERRORLEVEL% == 1 GOTO EXIT

echo "Running checks..."

REM *** SQL 2000 ***
REM osql -S %computername% -E -h-1 -n -w 1400 -i sqlserver.sql -o %Log_dir%\%DateStamp%_%computername%_sqlserver.html

REM *** SQL 2005/2008 ***
REM *** Run check against default instance ***
SET INSTANCE_NAME=MSSQL
REM sqlcmd -S %computername% -E -i sqlserver.sql -o %Log_dir%\%DateStamp%_%computername%_sqlserver.html

REM *** SQL 2005/2008 ***
REM *** Run check against named instance ***
REM Set INSTANCE_NAME=XXX
REM sqlcmd -S %computername%\%INSTANCE_NAME% -E -i sqlserver.sql -o %Log_dir%\%DateStamp%_%computername%-%INSTANCE_NAME%_sqlserver.html

REM Create HTML page with OS system info 
cscript //nologo GetStorage_info.wsf > %Log_Dir%\%DateStamp%_%computername%_Disk_Storage.html

REM FTP File upload
ECHO open %FTP_SERVER% > %Script_Dir%\dyn_ftp.ftp
ECHO %FTP_USER%>> %Script_Dir%\dyn_ftp.ftp
ECHO %FTP_PWD%>> %Script_Dir%\dyn_ftp.ftp
ECHO literal PASV >> %Script_Dir%\dyn_ftp.ftp
ECHO prompt >> %Script_Dir%\dyn_ftp.ftp
ECHO mput %Log_Dir%\%Date_only%* >> %Script_Dir%\dyn_ftp.ftp
ECHO bye >> %Script_Dir%\dyn_ftp.ftp

ftp -s:%Script_Dir%\dyn_ftp.ftp
erase dyn_ftp.ftp

REM Display output bye remove "REM" and verify file references
REM %Log_Dir%\%DateStamp%_%computername%_Disk_Storage.html
REM %Log_dir%\%DateStamp%_%computername%_sqlserver.html

:EXIT
pause
