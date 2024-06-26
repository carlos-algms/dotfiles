#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/../shell/common/00_os.sh"
source "${SCRIPT_DIR}/../shell/common/01_logging.sh"

if [ -z "$(command -v nvim)" ]; then
    if [[ ! -z "$IS_MAC" ]]; then
        # ripgrep is required for grep_string, telescope, etc..
        brew install neovim ripgrep
    elif [[ ! -z "$IS_LINUX" ]]; then
        sudo apt-get install -y neovim ripgrep
    else
        log_error "OS not supported"
        exit 1
    fi
fi


config_dir="${HOME}/.config"

# I have to create the directory, new installations don't have it
if [ ! -d "$config_dir" ]; then
    mkdir -p "$config_dir"
fi

target="${HOME}/.config/nvim"

if [ -d "$target" ] || [ -L "$target" ]; then
    TODAY="`date`"
    mv "$target" "$target-${TODAY}"
fi

ln -snf "${SCRIPT_DIR}/nvim" "$target"
