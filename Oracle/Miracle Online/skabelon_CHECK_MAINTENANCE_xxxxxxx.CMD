echo off
REM Hvis scriptet køres på Windows 2000 så findes CHOICE.EXE ikke,
REM rename filen CHOICE_WIN2000.CMD til CHOICE.CMD og sciptet kan køre

Call CHOICE /M  "Rotate the database alertlog ?"

IF %ERRORLEVEL% == 1 GOTO ROTATE
IF %ERRORLEVEL% == 2 GOTO END_ALERT

GOTO END_ALERT

:ROTATE
ECHO ROTATE ALERTLOG
sqlplus "/ as sysdba" @check_maintenance.sql WIN
GOTO END_ALERT

:END_ALERT
echo .


REM ----------------------------------------------------------------------------
REM Evt. Rotate af listener loggen
REM ----------------------------------------------------------------------------

set listener_fdir=D:\oracle\product\10.2.0\NETWORK\log\
set listener_fname=listener.log
set listener=LISTENER

FOR /f "tokens=1" %%A IN ('cscript.exe //nologo showdate.vbs') DO set DateStamp=%%A

if not exist %listener_fdir%%listener_fname% goto notfound

for %%A in (%listener_fdir%%listener_fname%) do set size=%%~zA
echo Listenerlog: %listener_fname% is %size% bytes?

Call CHOICE /M "Rotate the database listener log ?"

IF %ERRORLEVEL% == 1 GOTO ROTATE_LIST
IF %ERRORLEVEL% == 2 GOTO END_LIST

rem ------------------------------------------------------------------------------
:ROTATE_LIST
ECHO Rotate Listener log %listener_log%

rem stop logging
(
echo set current_listener %listener%
echo set log_status off
echo exit
) | lsnrctl

rem rename filen
move %listener_fdir%%listener_fname% %listener_fdir%%DateStamp%_%listener_fname%

rem start logging igen
(
echo set current_listener %listener%
echo set log_status on
echo exit
) | lsnrctl

GOTO END_LIST

rem ------------------------------------------------------------------------------
:NOTFOUND
 echo ----------------------------------------------------------------------------
 echo OBS !!!
 echo Filen %fname% findes ikke
 goto END_LIST

rem ------------------------------------------------------------------------------
:END_LIST
 ECHO .
