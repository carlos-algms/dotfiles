#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${SCRIPT_DIR}/shell/common/00_os.sh"
source "${SCRIPT_DIR}/shell/common/01_logging.sh"

for dir in $SCRIPT_DIR/*; do
  if [ -d "${dir}" ]; then
    if [ -f "$dir/install.sh" ]; then
        e_arrow "$dir/install.sh"

        chmod +x "$dir/install.sh"
        "$dir/install.sh"
    fi
  fi
done
