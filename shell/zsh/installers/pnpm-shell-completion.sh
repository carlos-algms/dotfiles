#!/usr/bin/env zsh

set -euo pipefail

scriptDir="${0:a:h}"

source $scriptDir/../../common/01_logging.sh

TMPDIR=$(mktemp -d)

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
            # ASSET="pnpm-shell-completion_aarch64-unknown-linux-gnu.zip"
            echo "Linux ARM64 is not supported yet"
            exit 0
        else
            ASSET="pnpm-shell-completion_x86_64-unknown-linux-gnu.zip"
        fi
    fi

    URL=$(
        curl -s https://api.github.com/repos/g-plane/pnpm-shell-completion/releases/latest |
            grep browser_download_url |
            grep "$ASSET" |
            cut -d '"' -f 4
    )

    if [[ -n "$URL" ]]; then
        DEST="$TMPDIR/pnpm-shell-completion.zip"
        curl -L "$URL" -o "$DEST"
        unzip -o "$DEST" -d "$TMPDIR"

        ## I must cd into the temp dir, as the script expects it
        cd "$TMPDIR"

        ## $ZSH_CUSTOM isn't available
        ./install.zsh $ZSH/custom/plugins

        # Inject pnpm-shell-completion into plugins list in .zshrc if not present
        if ! grep -q "pnpm-shell-completion" "$HOME/.zshrc"; then
            awk '
            BEGIN {in_plugins=0}
            /^plugins=\(/ {in_plugins=1}
            in_plugins && /\)/ {
                print "  pnpm-shell-completion"
                in_plugins=0
            }
            {print}
        ' "$HOME/.zshrc" >"$HOME/.zshrc.tmp" && mv "$HOME/.zshrc.tmp" "$HOME/.zshrc"
            e_arrow "Injected pnpm-shell-completion into plugins list in $HOME/.zshrc"
        fi

        e_success "pnpm-shell-completion installed"
    else
        e_error "Could not find pnpm-shell-completion release for $PLATFORM/$ARCH"
    fi
fi
