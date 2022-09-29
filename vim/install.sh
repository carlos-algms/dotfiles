#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ln -snf $SCRIPT_DIR/vimdir               $HOME/.vim
ln -snf $SCRIPT_DIR/vimdir/vimrc.vim     $HOME/.vimrc

# Adapted from:
# https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# install the plugins and quit
# https://github.com/junegunn/vim-plug/wiki/tips#install-plugins-on-the-command-line
vim -e -i NONE +PlugInstall +qall
