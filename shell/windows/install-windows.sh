#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "${BASH_SOURCE[0]%"${BASH_SOURCE[0]##*/}"}." && pwd)"
SHELL_DIR="${SCRIPT_DIR%/*}"

source "${SHELL_DIR}/common/01_logging.sh"

# Link mintty config file only for Windows
ln -snf "${SHELL_DIR}/minttyrc" "$HOME/.minttyrc"

e_success "Done installing Windows shell configs"
