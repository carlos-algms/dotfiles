## https://github.com/ohmyzsh/ohmyzsh/blob/master/custom/example.zsh
# this file will be loaded automatically by zsh, if it exists under ~/.oh-my-zsh/custom with zsh extensions (.zsh)

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

## Hide the default user name from the prompt
DEFAULT_USER=$(whoami)

## set VSCode as default editor if it is in the path and I'm running from VSCode terminal
if [[ -x "$(command -v code)" ]] && [[ "$TERM_PROGRAM" == "vscode" ]]; then
    export EDITOR='code --wait'
elif [[ -x "$(command -v nvim)" ]]; then
    export EDITOR='nvim'
elif [[ -x "$(command -v vim)" ]]; then
    export EDITOR='vim'
fi

# disable shared history between ZSH instances
HISTORY_IGNORE="(ls|pwd|exit|clear|ll|lsa|cd ..|cd -) *"
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
unsetopt inc_append_history
unsetopt share_history
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# https://github.com/docker/cli/commit/b10fb430481574b34997e4b0e00b703cfcd6669e#diff-474a9d942d53cc2279d5641e4a9dcfb18958e412ad53940b53423a38033857d6
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/docker/README.md#settings
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

export DOTFILES_SHELL_PATH="$(dirname $(dirname $(readlink -f ${0:a})))"
export DOTFILES_PATH="$(dirname $DOTFILES_SHELL_PATH)"

. $DOTFILES_SHELL_PATH/bin/source-dotfiles $DOTFILES_SHELL_PATH

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-vi-mode" ]; then
    git clone https://github.com/jeffreytse/zsh-vi-mode \
        $ZSH_CUSTOM/plugins/zsh-vi-mode
fi

# TODO: automate install of pnpm-shell-completion
# https://github.com/g-plane/pnpm-shell-completion?tab=readme-ov-file#oh-my-zsh

# eval "$(starship init zsh)"

# TODO: automate install of oh-my-posh
# Linux and Mac
if command -v oh-my-posh >/dev/null 2>&1; then
    eval "$(oh-my-posh init zsh --config $DOTFILES_SHELL_PATH/oh-my-posh.yaml)"
fi

# https://github.com/jeffreytse/zsh-vi-mode
function vim_mode_lazy_keybindings() {
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

    bindkey "^P" up-line-or-beginning-search
    bindkey "^N" down-line-or-beginning-search
}

zvm_after_init_commands+=(vim_mode_lazy_keybindings)
# zvm_after_lazy_keybindings_commands+=(zvm_after_lazy_keybindings)
