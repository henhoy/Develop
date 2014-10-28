@ECHO OFF
SET SCRIPT_DIR=C:\miracle_online\script
SET LOG_DIR=C:\miracle_online\log
SET BACKUPLOG_DIR=d:\rman\log
SET FTP_SERVER=ftp.miracleas.dk
SET FTP_USER=mo-xxx
SET FTP_PWD=pwd2xxx
SET ALERTCOPY=YES

FOR /f "tokens=1" %%A IN ('cscript.exe //nologo showdate.vbs /withtimestamp:1') DO set DateStamp2=%%A
SET DATESTAMP=%DATESTAMP2:~0,13%
SET DATE_only=%DATESTAMP2:~0,8%

REM Get latest version of checks from FTP server
CD %SCRIPT_DIR%
ftp -s:%Script_Dir%\get_update2011_scripts.ftp
ftp -s:%Script_Dir%\update2011_scripts.ftp

REM Kør tjekket
SET ORACLE_SID=xxxxxx
sqlplus "/ as sysdba" @check_start.sql WIN %Log_Dir%

REM Kør evt. MOT på ALERTLOG filen
call xx_sets
mot --scanlog %ALERT_LOG% > %LOG_DIR%\%ALERT_FNAME%_mot.log 

REM Tjek RMAN Log(S)
mot -scan %BACKUPLOG_DIR% -filemask <de filer vi leder efter> -newer 8 -match "RMAN-","ORA-" > %log_dir%\%Datestamp%_%Computername%_rman_backup_errors.log

REM Create HTML page with OS system info 
cscript //nologo GetStorage_info.wsf > %Log_Dir%\%DateStamp%_%computername%_Disk_Storage.html

REM Get Listener status
lsnrctl status   > %Log_Dir%\%DateStamp%_%computername%_listener_status.txt
lsnrctl service >> %Log_Dir%\%DateStamp%_%computername%_listener_status.txt

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

pause