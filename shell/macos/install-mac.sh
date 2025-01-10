#!/usr/bin/env zsh

local shellDir="`dirname ${0:a:h}`"

source "$shellDir/common/01_logging.sh"

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
brew install \
    ack \
    bat \
    coreutils \
    eza \
    fd \
    fzf \
    git \
    htop \
    oh-my-posh \
    ripgrep \
    tree \
    watch \
    wget \
    xz \
    zoxide

brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
brew install --cask the-unarchiver

e_success "Done installing 🍎 Mac dotfiles"
