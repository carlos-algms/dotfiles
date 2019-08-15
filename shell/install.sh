#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${SCRIPT_DIR}/common/00_os.sh"
source "${SCRIPT_DIR}/common/01_logging.sh"


if [[ ! -z "$IS_WIN" ]]; then
    "${SCRIPT_DIR}/windows/install-windows.sh"
elif [[ ! -z "$IS_MAC" ]]; then
    "${SCRIPT_DIR}/macos/install-mac.sh"
elif [[ ! -z "$IS_LINUX" ]]; then
    "${SCRIPT_DIR}/linux/install-linux.sh"
else
    e_error "No OS identified to install"
fi


e_header "Backup files"

TODAY="`date`"

if [ -f $HOME/.bash_profile ]; then
    mv $HOME/.bash_profile "$HOME/.bash_profile-${TODAY}"
fi

if [ -f $HOME/.bashrc ]; then
    mv $HOME/.bashrc "$HOME/.bashrc-${TODAY}"
fi

if [ -f $HOME/.zshrc ]; then
    mv $HOME/.zshrc "$HOME/.zshrc-${TODAY}"
fi

e_header "Linking config files"

ln -snf $SCRIPT_DIR/bashrc.sh              $HOME/.bash_profile
ln -snf $SCRIPT_DIR/bashrc.sh              $HOME/.bashrc

# Link mintTTY config file only for windows
if [ ! -z "$IS_WIN" ]; then
    ln -snf $SCRIPT_DIR/minttyrc           $HOME/.minttyrc
fi

# Unix needs to add execution rights
chmod u+x $SCRIPT_DIR/bin/*
chmod u+x $SCRIPT_DIR/linux/bin/*
chmod u+x $SCRIPT_DIR/macos/bin/*
