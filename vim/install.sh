#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ln -snf $SCRIPT_DIR/vimdir           $HOME/.vim
ln -snf $SCRIPT_DIR/vimdir/vimrc     $HOME/.vimrc
