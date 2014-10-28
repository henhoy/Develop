@ECHO OFF
SET SCRIPT_DIR=C:\miracle_online\script
SET LOG_DIR=C:\miracle_online\log
SET FTP_SERVER=194.255.38.201
SET FTP_USER=
SET FTP_PWD=
FOR /f "tokens=1" %%A IN ('cscript.exe //nologo showdate.vbs') DO set DateStamp=%%A

REM Get latest version of check.sql from FTP server
CD %SCRIPT_DIR%
ftp -s:%Script_Dir%\update_scripts.ftp

SET ORACLE_SID=KAJ10
sqlplus "/ as sysdba" @check.sql

REM Create HTML page with OS disk usage
cscript //nologo GetStorage_info.wsf > %Log_Dir%\%DateStamp%_%computername%_Disk_Storage.htm

REM ** prepare ftp upload **
ECHO open %FTP_SERVER% > %Script_Dir%\dyn_ftp.ftp
ECHO %FTP_USER%>> %Script_Dir%\dyn_ftp.ftp
ECHO %FTP_PWD%>> %Script_Dir%\dyn_ftp.ftp
ECHO literal PASV
ECHO prompt >> %Script_Dir%\dyn_ftp.ftp
ECHO mput %Log_Dir%\%DateStamp%* >> %Script_Dir%\dyn_ftp.ftp
ECHO bye >> %Script_Dir%\dyn_ftp.ftp

ftp -s:%Script_Dir%\dyn_ftp.ftp

pause