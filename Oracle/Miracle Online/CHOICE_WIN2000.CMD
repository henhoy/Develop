@ECHO off
ECHO.
ECHO.
SET /P VALG="%2% [Y/N] > "
IF %VALG%==Y goto rotate
IF %VALG%==y goto rotate
IF %VALG%==J goto rotate
IF %VALG%==j goto rotate
goto norotate

:rotate
ECHO.
ECHO Log file will be rotated
exit /b 1

:norotate
ECHO.
ECHO Log file will NOT be rotated
exit /b 2
