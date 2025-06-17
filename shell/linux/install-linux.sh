#!/usr/bin/env bash

sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
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
    fzf \
    git \
    gpg \
    htop \
    luajit \
    ripgrep \
    tree \
    watch \
    wget \
    xz-utils

curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
curl -s https://ohmyposh.dev/install.sh | bash -s
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
