@echo off
set "SCRIPT_DIR=%~dp0"

rem mklink /d %HOME%\.vim       %SCRIPT_DIR%\vimdir
mklink    %HOME%\.vimrc     %SCRIPT_DIR%\vimdir\vimrc.vim

rem attrib +h /l %HOME%\.vim
attrib +h /l %HOME%\.vimrc
