#!/usr/bin/env zsh

# Why this plugin: native pnpm completion (`pnpm completion zsh`) starts Node on
# shell start (~0.55s) and on every Tab (~0.3s). This plugin is a native binary,
# so it is faster. Do not replace it with `source <(pnpm completion zsh)`.
#
# Update: rerun this script. It compares the installed release tag (stored in
# <plugin dir>/.version) with the latest GitHub release and reinstalls when they differ.

set -euo pipefail

scriptDir="${0:a:h}"

source "$scriptDir/../../common/01_logging.sh"

# $ZSH is only exported by ~/.zshrc, not in a fresh install
ZSH="${ZSH:-$HOME/.oh-my-zsh}"
pluginDir="$ZSH/custom/plugins/pnpm-shell-completion"

if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux-gnu"* ]]; then
    e_header "Installing pnpm-shell-completion"

    ARCH=$(uname -m)

    if [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
        if [[ "$ARCH" == "arm64" ]]; then
            ASSET="pnpm-shell-completion_aarch64-apple-darwin.zip"
        else
            ASSET="pnpm-shell-completion_x86_64-apple-darwin.zip"
        fi
    else
        PLATFORM="linux"
        if [[ "$ARCH" == "aarch64" ]]; then
            ASSET="pnpm-shell-completion_aarch64-unknown-linux-gnu.zip"
        else
            ASSET="pnpm-shell-completion_x86_64-unknown-linux-gnu.zip"
        fi
    fi

    release="$(curl -fsSL https://api.github.com/repos/g-plane/pnpm-shell-completion/releases/latest)"
    latest="$(jq -r '.tag_name' <<<"$release")"
    installed=""
    if [[ -f "$pluginDir/.version" ]]; then
        installed="$(<"$pluginDir/.version")"
    fi

    if [[ "$installed" == "$latest" ]]; then
        e_success "pnpm-shell-completion $installed is up to date"
    else
        e_arrow "pnpm-shell-completion ${installed:-not installed or unknown version} -> $latest"
        URL=$(jq -r --arg asset "$ASSET" 'first(.assets[] | select(.name == $asset)) | .browser_download_url' <<<"$release")

        if [[ -z "$URL" ]]; then
            e_error "Could not find pnpm-shell-completion release for $PLATFORM/$ARCH"
            exit 1
        fi

        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT

        curl -fL "$URL" -o "$tmp/pnpm-shell-completion.zip"
        unzip -o "$tmp/pnpm-shell-completion.zip" -d "$tmp"

        ## I must cd into the temp dir, as the script expects it
        cd "$tmp"

        rm -rf "$pluginDir"

        ## $ZSH_CUSTOM isn't available
        ./install.zsh "$ZSH/custom/plugins"
        echo "$latest" >"$pluginDir/.version"
    fi

    # Inject pnpm-shell-completion into plugins list in .zshrc if not present.
    # ~/.zshrc may be a symlink, which in-place editing would replace
    zshrc="$(realpath "$HOME/.zshrc")"
    if ! grep -q "pnpm-shell-completion" "$zshrc"; then
        # multi-line list: new plugin on its own line; inline list: first item
        perl -pi -e 's/^plugins=\($/plugins=(\n  pnpm-shell-completion/ or s/^plugins=\(/plugins=(pnpm-shell-completion /' "$zshrc"

        e_arrow "Injected pnpm-shell-completion into plugins list in $zshrc"
    fi

    e_success "pnpm-shell-completion installed"
fi
