#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd )"

source "${SCRIPT_DIR}/common/01_logging.sh"

# Install Homebrew.
if [[ ! "$(type brew)" ]]; then
    e_header "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    e_success "Brew is already installed"
fi

# Exit if, for some reason, Homebrew is not installed.
if [ ! "$(type brew)" ]; then
    e_error "Homebrew failed to install."
    exit 1
fi

e_header "Updating Homebrew"
brew doctor
brew update
brew install coreutils wget

if [ -d "$HOME/.oh-my-zsh" ]; then
    e_success "oh-my-zsh is already installed"
else
    e_header "Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Hide username from ZSH
CONFIG_STR="DEFAULT_USER=`whoami`"

grep -q -F "${CONFIG_STR}" ~/.zshrc

if [ $? -ne 0 ]; then
    e_header "Hiding username from PS1"
    echo $'\n'"$CONFIG_STR"$'\n' >> ~/.zshrc
fi


# include a line to source common shell configs
grep -q -F 'source ~/.bashrc' ~/.zshrc

if [ $? -ne 0 ]; then
    e_header "Including source to bashrc into zshrc"
    echo -e $'\n'"source ~/.bashrc"$'\n\n' >> ~/.zshrc
fi
