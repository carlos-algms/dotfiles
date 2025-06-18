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
    git \
    gpg \
    htop \
    jq \
    luajit \
    ripgrep \
    tree \
    watch \
    wget \
    xz-utils

curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
curl -s https://ohmyposh.dev/install.sh | bash -s
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

mkdir -p $HOME/.local/bin

ARCH=$(uname -m)

# FZF most recent
if [[ "$ARCH" == "x86_64" ]]; then
    FZF_URL=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep browser_download_url | grep linux_amd64 | cut -d '"' -f 4)
elif [[ "$ARCH" == "aarch64" ]]; then
    FZF_URL=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep browser_download_url | grep linux_arm64 | cut -d '"' -f 4)
else
    echo "FZF Install: Unsupported architecture: $ARCH"
fi

if [[ -n "$FZF_URL" ]]; then
    TMPDIR=$(mktemp -d)
    curl -L "$FZF_URL" -o "$TMPDIR/fzf.tar.gz"
    tar -xzf "$TMPDIR/fzf.tar.gz" -C "$TMPDIR"
    mv "$TMPDIR/fzf" "$HOME/.local/bin/fzf"
    chmod +x "$HOME/.local/bin/fzf"
    rm -rf "$TMPDIR"
fi

# Install Yazi (latest release)
if [[ "$ARCH" == "x86_64" ]]; then
    YAZI_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep browser_download_url | grep yazi-x86_64-unknown-linux-gnu.zip | cut -d '"' -f 4)
elif [[ "$ARCH" == "aarch64" ]]; then
    YAZI_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep browser_download_url | grep yazi-aarch64-unknown-linux-gnu.zip | cut -d '"' -f 4)
else
    echo "Yazi Install: Unsupported architecture: $ARCH"
fi

if [[ -n "$YAZI_URL" ]]; then
    TMPDIR=$(mktemp -d)
    curl -L "$YAZI_URL" -o "$TMPDIR/yazi.zip"
    unzip -j "$TMPDIR/yazi.zip" '*/yazi' -d "$TMPDIR"
    mv "$TMPDIR/yazi" "$HOME/.local/bin/yazi"
    chmod +x "$HOME/.local/bin/yazi"
    rm -rf "$TMPDIR"
fi
