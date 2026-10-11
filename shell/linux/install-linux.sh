#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "${BASH_SOURCE[0]%"${BASH_SOURCE[0]##*/}"}." && pwd)"

# gpg --dearmor asks before overwriting, so only create the key once
sudo mkdir -p /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/gierens.gpg ]]; then
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
fi
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

sudo apt update
sudo apt install -y \
    ack \
    bat \
    coreutils \
    curl \
    eza \
    fd-find \
    git \
    gpg \
    htop \
    jq \
    luajit \
    rsync \
    tree \
    unzip \
    watch \
    wget \
    xz-utils \
    zsh

mkdir -p "$HOME/.local/bin"

# Debian/Ubuntu install fd as "fdfind". Other tools (fzf, nvim) need the name "fd"
if command -v fdfind >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# fzf, ripgrep, yazi, fnm, zoxide. Rerun that script alone to update them
"${SCRIPT_DIR}/install-or-update-shell-tools.sh"
