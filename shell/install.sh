#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


ln -snf $SCRIPT_DIR/bashrc              $HOME/.bash_profile
ln -snf $SCRIPT_DIR/bashrc              $HOME/.bashrc

# ln -snf $SCRIPT_DIR/minttyrc            $HOME/.minttyrc

# Linux needs to add execution rights
chmod u+x $SCRIPT_DIR/bin/*
chmod u+x $SCRIPT_DIR/linux/bin/*
