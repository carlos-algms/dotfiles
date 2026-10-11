#!/usr/bin/env zsh
set -euo pipefail

scriptDir="${0:a:h}"

source "$scriptDir/../common/01_logging.sh"

if [[ -d ~/.oh-my-zsh ]]; then
    e_success "oh-my-zsh is already installed"
else
    e_header "Installing oh-my-zsh"
    # RUNZSH=no: do not exec zsh and end this script.
    # The installer replaces an existing ~/.zshrc with its template (old file saved as ~/.zshrc.pre-oh-my-zsh),
    # so a fresh machine always gets a working file.
    # Symlink your own ~/.zshrc afterwards if you want
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

e_header "Linking custom zsh config file"

ln -sf "$(realpath "$scriptDir/custom.zsh")" ~/.oh-my-zsh/custom/custom.zsh

e_header "Linking custom zsh agnoster with λ theme"

ln -sf "$(realpath "$scriptDir/themes/agnoster.zsh-theme")" ~/.oh-my-zsh/custom/themes/agnoster.zsh-theme

e_success "Done installing ZSH and oh-my-zsh"
echo ""

"$scriptDir/installers/pnpm-shell-completion.sh"

unset scriptDir
