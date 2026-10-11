#!/usr/bin/env bash
# Install or update CLI tools that apt does not ship at a current version:
# fzf, ripgrep, yazi, fnm, zoxide (+ Node LTS through fnm).
#
# Safe to rerun: a tool is only reinstalled when its installed version differs
# from the latest GitHub release. Run it every now and then to update them.
# Set GITHUB_TOKEN to raise the GitHub API rate limit (60 requests/hour).
# Linux only. macOS gets these tools from brew.
set -euo pipefail

SCRIPT_DIR="$(cd -- "${BASH_SOURCE[0]%"${BASH_SOURCE[0]##*/}"}." && pwd)"
SHELL_DIR="${SCRIPT_DIR%/*}"

source "${SHELL_DIR}/common/00_os.sh"
source "${SHELL_DIR}/common/01_logging.sh"

if [[ -z "$IS_LINUX" ]]; then
    e_error "Linux only. macOS gets these tools from brew"
    exit 1
fi

BIN_DIR="$HOME/.local/bin"
FNM_BIN="$HOME/.local/share/fnm/fnm"

case "$(uname -m)" in
x86_64)
    ARCH="x86_64"
    GOARCH="amd64"
    ;;
aarch64)
    ARCH="aarch64"
    GOARCH="arm64"
    ;;
*)
    e_error "Unsupported architecture: $(uname -m)"
    exit 1
    ;;
esac

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$BIN_DIR"

github_api() { # path
    local args=(-fsSL)
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
    fi
    curl "${args[@]}" "https://api.github.com/$1"
}

# First x.y.z in "<binary> --version" output. Empty when the binary is missing
installed_version() { # binary
    local output

    if [[ ! -x "$1" ]]; then
        return 0
    fi

    # A binary that fails to run counts as "no version", so it gets reinstalled
    if ! output="$("$1" --version 2>&1)"; then
        return 0
    fi

    if [[ "$output" =~ [0-9]+(\.[0-9]+)+ ]]; then
        echo "${BASH_REMATCH[0]}"
    fi
}

# Returns 0 when the installed version already matches the release
is_up_to_date() { # name binary release-json
    local installed latest
    installed="$(installed_version "$2")"
    latest="$(jq -r '.tag_name | ltrimstr("v")' <<<"$3")"

    if [[ "$installed" == "$latest" ]]; then
        e_success "$1 $installed is up to date"
        return 0
    fi

    if [[ -n "$installed" ]]; then
        e_arrow "$1 $installed -> $latest"
    else
        e_arrow "$1 not installed, installing $latest"
    fi
    return 1
}

# Release archive tools: download, extract, install the binary found by name
install_release() { # name repo asset-regex
    local name="$1" repo="$2" pattern="$3"
    local release url archive dir bin

    release="$(github_api "repos/${repo}/releases/latest")"
    if is_up_to_date "$name" "${BIN_DIR}/${name}" "$release"; then
        return 0
    fi

    url="$(jq -r --arg p "$pattern" 'first(.assets[] | select(.name | test($p))) | .browser_download_url' <<<"$release")"
    if [[ -z "$url" ]]; then
        e_error "No $name release asset matches $pattern"
        return 1
    fi

    archive="${WORK_DIR}/${name}.archive"
    dir="${WORK_DIR}/${name}"
    mkdir -p "$dir"
    curl -fsSL "$url" -o "$archive"

    case "$url" in
    *.tar.gz) tar -xzf "$archive" -C "$dir" ;;
    *.zip) unzip -q "$archive" -d "$dir" ;;
    *)
        e_error "Unknown archive type: $url"
        return 1
        ;;
    esac

    bin="$(find "$dir" -type f -name "$name" -print -quit)"
    if [[ -z "$bin" ]]; then
        e_error "$name binary not found in $url"
        return 1
    fi

    install -m 755 "$bin" "${BIN_DIR}/${name}"
    e_success "$name installed"
}

# Vendor installer tools: run their script only when the release is newer
install_with_script() { # name binary repo script-url [installer args...]
    local name="$1" binary="$2" repo="$3" script_url="$4" release
    shift 4

    release="$(github_api "repos/${repo}/releases/latest")"
    if is_up_to_date "$name" "$binary" "$release"; then
        return 0
    fi

    curl -fsSL "$script_url" | bash -s -- "$@"
    e_success "$name installed"
}

install_release fzf junegunn/fzf "linux_${GOARCH}"'\.tar\.gz$'
install_release rg BurntSushi/ripgrep "${ARCH}"'-unknown-linux-musl\.tar\.gz$'
install_release yazi sxyazi/yazi 'yazi-'"${ARCH}"'-unknown-linux-gnu\.zip$'

install_with_script fnm "$FNM_BIN" Schniz/fnm https://fnm.vercel.app/install --skip-shell
install_with_script zoxide "${BIN_DIR}/zoxide" ajeetdsouza/zoxide https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh

# Node LTS: the first install sets the default alias, reruns only warn, no error.
if [[ -x "$FNM_BIN" ]]; then
    "$FNM_BIN" install --lts
fi

e_success "Done installing shell tools"
