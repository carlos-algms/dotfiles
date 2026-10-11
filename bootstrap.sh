#!/usr/bin/env bash
# No -e: a failing component must not stop the others, failures are reported at the end
set -uo pipefail

SCRIPT_DIR="$(cd -- "${BASH_SOURCE[0]%"${BASH_SOURCE[0]##*/}"}." && pwd)"

source "${SCRIPT_DIR}/shell/common/00_os.sh"
source "${SCRIPT_DIR}/shell/common/01_logging.sh"

failed=()

for dir in "$SCRIPT_DIR"/*; do
    if [ ! -f "${dir}/install.sh" ]; then
        continue
    fi

    e_arrow "${dir}/install.sh"
    if ! "${dir}/install.sh"; then
        e_error "Failed: ${dir}/install.sh"
        failed+=("${dir}")
    fi
done

if [ ${#failed[@]} -gt 0 ]; then
    e_error "Failed components, rerun with:"
    for dir in "${failed[@]}"; do
        echo "  ${dir}/install.sh"
    done
    exit 1
fi
