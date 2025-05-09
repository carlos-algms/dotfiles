#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../shell/common/00_os.sh"
source "${SCRIPT_DIR}/../shell/common/01_logging.sh"

if [ -z "$IS_MAC" ]; then
    e_arrow "Not on macOS, skipping install kitty"
    exit 0
fi

if ! command -v kitty >/dev/null 2>&1; then
    e_header "Installing kitty 🐱"
    brew install kitty
fi

if [ ! -d ~/.config/kitty ]; then
    mkdir -p ~/.config/kitty
fi

target="${HOME}/.config/kitty/kitty.conf"
source="${SCRIPT_DIR}/kitty.conf"

if [ -e "$target" ]; then
    if [ -L "$target" ] && [ "$source" == "$(realpath $target)" ]; then
        e_arrow "$target already linked to $source"
        exit 0
    fi

    e_arrow "Backing up $target to $target.bak"
    TODAY="$(date)"
    mv "$target" "$target-${TODAY}"
fi

e_arrow "Linking $target to $source"
ln -snf "$source" "$target"
