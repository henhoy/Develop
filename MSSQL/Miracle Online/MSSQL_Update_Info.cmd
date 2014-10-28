echo off
cls
type MSSQL_Update_Info.txt
echo:

if exist %SCRIPT_DIR%\sqlserver_config.sql goto :CONFIG_EXIST

copy %SCRIPT_DIR%\skabelon_sqlserver_config.sql %SCRIPT_DIR%\sqlserver_config.sql

notepad %SCRIPT_DIR%\new_sql_version_todo.txt
notepad %SCRIPT_DIR%\sqlserver_config.sql

:CONFIG_EXIST

findstr run_defrag_index %SCRIPT_DIR%\sqlserver_config.sql
IF %ERRORLEVEL% == 0 goto WAIT_LOOP_COUNTER

:RUN_DEFRAG_INDEX
echo.>>%SCRIPT_DIR%\sqlserver_config.sql 
echo /* update the default (yes) run of index fragmentation scan value */>>%SCRIPT_DIR%\sqlserver_config.sql
echo --update #MORLT set Value ='NO' where Name = 'run_defrag_index';>>%SCRIPT_DIR%\sqlserver_config.sql

:WAIT_LOOP_COUNTER
findstr wait_loop_counter %SCRIPT_DIR%\sqlserver_config.sql
IF %ERRORLEVEL% == 0 goto IGNORE_WAITS

echo.>>%SCRIPT_DIR%\sqlserver_config.sql 
echo /* update the default numbers of loop counts to something else (x times of 1 minutes) */>>%SCRIPT_DIR%\sqlserver_config.sql
echo --update #MORLT set Value ='2' where Name = 'wait_loop_counter';>>%SCRIPT_DIR%\sqlserver_config.sql

:IGNORE_WAITS
findstr ignore_waits %SCRIPT_DIR%\sqlserver_config.sql
IF %ERRORLEVEL% == 0 goto CHOOSE

echo.>>%SCRIPT_DIR%\sqlserver_config.sql
echo /* Insert additional wait exclusions */>>%SCRIPT_DIR%\sqlserver_config.sql
echo --insert into #ignore_waits values ('WAIT_TO_EXCLUDE');>>%SCRIPT_DIR%\sqlserver_config.sql

echo Please verify new values in sqlserver_config.sql
pause
notepad %SCRIPT_DIR%\sqlserver_config.sql

:CHOOSE
echo:

choice /M "Do you want to execute the check with the current version (y) or exit to carry out adjustments (n) ?" /D y /T 45

IF %ERRORLEVEL% == 1 GOTO EXECUTE
IF %ERRORLEVEL% == 2 GOTO EXIT

:EXECUTE
exit 0

:EXIT
exit 1
