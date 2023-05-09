#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd )"

source "${SCRIPT_DIR}/common/01_logging.sh"

# Install Homebrew.
if [[ ! "$(type brew)" ]]; then
    e_header "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
else
    e_success "Brew is already installed"
fi

# Exit if, for some reason, Homebrew is not installed.
if [ ! "$(type brew)" ]; then
    e_error "Homebrew failed to install."
    exit 1
fi

# e_header "Updating Homebrew"
brew doctor
brew update
brew install coreutils wget git watch

if [ -d "$HOME/.oh-my-zsh" ]; then
    e_success "oh-my-zsh is already installed"
else
    e_header "Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

e_header "Linking custom zsh config file"

ln -sf `realpath $SCRIPT_DIR/custom.zsh` $HOME/.oh-my-zsh/custom/custom.zsh

e_header "Linking custom zsh agnoster with λ theme"

ln -sf `realpath $SCRIPT_DIR/zsh/themes/agnoster.zsh-theme` ~/.oh-my-zsh/custom/themes/agnoster.zsh-theme

e_success "Done installing 🍎 Mac dotfiles"
