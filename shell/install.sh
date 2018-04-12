#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ln -snf $SCRIPT_DIR/aliases_servers.sh  $HOME/.bash_aliases
ln -snf $SCRIPT_DIR/aliases_common.sh   $HOME/.aliases_common

# bash_common is loaded by both profile and bashrc
ln -snf $SCRIPT_DIR/bash_common.sh      $HOME/.bash_common

ln -snf $SCRIPT_DIR/bashrc              $HOME/.bash_profile
ln -snf $SCRIPT_DIR/bashrc              $HOME/.bashrc

ln -snf $SCRIPT_DIR/minttyrc            $HOME/.minttyrc

ln -snf $SCRIPT_DIR/bin                 $HOME/bin

chmod u+x $SCRIPT_DIR/bin/*
