@echo off
set "SCRIPT_DIR=%~dp0"

mklink /d %HOME%\.vim       %SCRIPT_DIR%\vimdir
mklink    %HOME%\.vimrc     %SCRIPT_DIR%\vimdir\vimrc

attrib +h /l %HOME%\.vim
attrib +h /l %HOME%\.vimrc
