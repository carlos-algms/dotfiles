#!/usr/bin/env zsh
set -euo pipefail

local shellDir="${0:a:h:h}"

source "$shellDir/common/01_logging.sh"

# Install Homebrew.
if ! command -v brew &>/dev/null; then
    e_header "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # A fresh install is not on PATH yet in this process
    # The brew plugin for omzsh only handles new shells
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    e_success "Brew is already installed"
fi

# Exit if, for some reason, Homebrew is not installed.
if ! command -v brew &>/dev/null; then
    e_error "Homebrew failed to install."
    exit 1
fi

# e_header "Updating Homebrew"
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
    pkg-config \
    ripgrep \
    rsync \
    tree \
    watch \
    wget \
    xz \
    zoxide

brew install --cask font-hack-nerd-font
brew install --cask the-unarchiver

# Node LTS: the first install sets the default alias, reruns only warn
fnm install --lts

e_success "Done installing 🍎 Mac dotfiles"
