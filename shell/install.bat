@echo off
set "SCRIPT_DIR=%~dp0"

mklink /D %HOME%\bin            %SCRIPT_DIR%\bin

mklink    %HOME%\.bash_aliases  %SCRIPT_DIR%\aliases_common
mklink    %HOME%\.bash_common   %SCRIPT_DIR%\bash_common
mklink    %HOME%\.bash_profile  %SCRIPT_DIR%\profile
mklink    %HOME%\.bashrc        %SCRIPT_DIR%\bashrc
mklink    %HOME%\.minttyrc        %SCRIPT_DIR%\minttyrc

attrib +h /l %HOME%\.bash_aliases
attrib +h /l %HOME%\.bash_common
attrib +h /l %HOME%\.bash_profile
attrib +h /l %HOME%\.bashrc
attrib +h /l %HOME%\.minttyrc
