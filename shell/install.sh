#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "${BASH_SOURCE[0]%"${BASH_SOURCE[0]##*/}"}." && pwd)"

source "${SCRIPT_DIR}/common/00_os.sh"
source "${SCRIPT_DIR}/common/01_logging.sh"

if [[ -n "$IS_WIN" ]]; then
    "${SCRIPT_DIR}/windows/install-windows.sh"
elif [[ -n "$IS_MAC" ]]; then
    "${SCRIPT_DIR}/macos/install-mac.sh"
    "${SCRIPT_DIR}/zsh/install-zsh.sh"
elif [[ -n "$IS_LINUX" ]]; then
    "${SCRIPT_DIR}/linux/install-linux.sh"
    "${SCRIPT_DIR}/zsh/install-zsh.sh"
else
    e_error "No OS identified to install"
    exit 1
fi

e_arrow Setup EZA theme
mkdir -p "$HOME/.config/eza"
ln -snf "$SCRIPT_DIR/eza-theme.yml" "$HOME/.config/eza/theme.yml"
e_success "EZA theme setup done"

e_success "Done installing shell configs"
