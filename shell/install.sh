#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ln -snf $SCRIPT_DIR/aliases       $HOME/.bash_aliases
# bash_common is loaded by both profile and bashrc
ln -snf $SCRIPT_DIR/bash_common   $HOME/.bash_common

ln -snf $SCRIPT_DIR/profile       $HOME/.bash_profile
ln -snf $SCRIPT_DIR/bashrc        $HOME/.bashrc

ln -snf $SCRIPT_DIR/bin           $HOME/bin
