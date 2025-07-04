#!/usr/bin/env zsh

local shellDir="$(dirname ${0:a:h})"

source "$shellDir/common/01_logging.sh"

# Install Homebrew.
if command -v brew &>/dev/null; then
    e_header "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Not necessary, brew plugin for omzsh will handle this
    # echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
else
    e_success "Brew is already installed"
fi

# Exit if, for some reason, Homebrew is not installed.
if command -v brew &>/dev/null; then
    e_error "Homebrew failed to install."
    exit 1
fi

# e_header "Updating Homebrew"
brew doctor
brew update
brew install \
    ack \
    bat \
    bash \
    coreutils \
    eza \
    fd \
    fnm \
    fzf \
    gh \
    git \
    htop \
    jq \
    kitty \
    luajit \
    monitorcontrol \
    neovim \
    oh-my-posh \
    pkg-config \
    ripgrep \
    tree \
    watch \
    wget \
    xz \
    zoxide

brew install --cask font-hack-nerd-font
brew install --cask the-unarchiver

e_success "Done installing 🍎 Mac dotfiles"
