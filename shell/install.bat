@echo off
set "SCRIPT_DIR=%~dp0"

mklink    %HOME%\.bash_profile  %SCRIPT_DIR%\bashrc
mklink    %HOME%\.bashrc        %SCRIPT_DIR%\bashrc
mklink    %HOME%\.minttyrc      %SCRIPT_DIR%\minttyrc

attrib +h /l %HOME%\.bash_profile
attrib +h /l %HOME%\.bashrc
attrib +h /l %HOME%\.minttyrc
