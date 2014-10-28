@ECHO OFF

REM slet evt. gammel fil med settings
IF EXIST xx_sets.cmd erase xx_sets.cmd

REM Vi leder efter en specialversion til rul af alert loggen. (navn_%oracle_sid%)
IF NOT EXIST check_maintenance_%oracle_sid%.cmd GOTO Standard

REM Kør nonstandard scriptet
echo Vi fandt en specialversion: (check_maintenance_%oracle_sid%.cmd) og k›rer denne.
Call check_maintenance_%oracle_sid%.cmd
goto COPY

:Standard
REM kør standard scriptet
echo Vi fandt ingen specialversion (check_maintenance_%oracle_sid%.cmd) , s† vi k›rer standardversionen: check_maintenance.cmd

REM Hvis scriptet køres på Windows 2000 så findes CHOICE.EXE ikke,
REM rename filen CHOICE_WIN2000.CMD til CHOICE.CMD og sciptet kan køre

CHOICE /M "Rotate the database alertlog ?"

IF %ERRORLEVEL% == 1 GOTO ROTATE
IF %ERRORLEVEL% == 2 GOTO END

GOTO END

:ROTATE
ECHO ROTATE ALERTLOG
sqlplus "/ as sysdba" @check_maintenance.sql WIN

:COPY

REM Findes output fil fra Rotate?
if not exist xx_sets.cmd goto end

REM sæt alertlog settings
Call xx_sets.cmd

if %ALERTCOPY% == NO goto END

copy %ALERT_LOG% %LOG_DIR%

GOTO END

:END

EXIT


