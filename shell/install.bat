@echo off
set "SCRIPT_DIR=%~dp0"

mklink    %HOME%\.bash_aliases  %SCRIPT_DIR%\aliases
mklink    %HOME%\.bash_common   %SCRIPT_DIR%\bash_common
mklink    %HOME%\.bash_profile  %SCRIPT_DIR%\profile
mklink    %HOME%\.bashrc        %SCRIPT_DIR%\bashrc
mklink /D %HOME%\bin            %SCRIPT_DIR%\bin

attrib +h %HOME%\.bash_aliases
attrib +h %HOME%\.bash_common
attrib +h %HOME%\.bash_profile
attrib +h %HOME%\.bashrc
