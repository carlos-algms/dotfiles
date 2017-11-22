@echo off

set "SCRIPT_DIR=%~dp0"
set "HOME=%HOMEDRIVE%\msys64\home\Carlos"

for /f "delims=" %%D in ('dir /a:d /b %SCRIPT_DIR%') ^
do if not "%%D"==".git" if exist %%D/install.bat echo "installing %%D" && %%~fD\install.bat