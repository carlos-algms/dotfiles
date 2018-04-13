#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


ln -snf $SCRIPT_DIR/bashrc              $HOME/.bash_profile
ln -snf $SCRIPT_DIR/bashrc              $HOME/.bashrc

ln -snf $SCRIPT_DIR/minttyrc            $HOME/.minttyrc

ln -snf $SCRIPT_DIR/bin                 $HOME/bin

# Linux needs to add execution rights
chmod u+x $SCRIPT_DIR/bin/*
