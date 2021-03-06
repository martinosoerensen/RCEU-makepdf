@echo off
if NOT [%2]==[] GOTO :cont
echo Missing argument(s), example usage:
echo %~f0 manual\ manual\origs\out\
exit 1

:cont
set DRIVE=%~d1
set MANUALPATH=%~p1
set MANUALPATH1=%MANUALPATH:~0,-1%
rem set MAINDIR=%~p1
rem set MAINDIR1=%MAINDIR:~0,-1%
rem for %%f in ("%MAINDIR1%") do set ManualName=%%~nxf
set IMAGEDIR=%~p2
set IMAGEDIR1=%IMAGEDIR:~0,-1%

echo.
echo Manual dir   = %~dp1
echo TIF/JPG dir  = %~dp2

rem Check if volume makepdf_persist exists and create it if not
docker volume inspect makepdf_persist >nul
IF NOT "%ERRORLEVEL%"=="0" (
 echo Creating docker volume makepdf_persist, used to store settings
 docker volume create --name makepdf_persist >nul
)
docker run -it --rm --volume %DRIVE%\:/app/mnt --volume makepdf_persist:/app/data:rw martinosoerensen/rceu-makepdf "%MANUALPATH1%" "%IMAGEDIR1%"
