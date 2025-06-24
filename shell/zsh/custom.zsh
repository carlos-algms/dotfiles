## https://github.com/ohmyzsh/ohmyzsh/blob/master/custom/example.zsh
# this file will be loaded automatically by zsh, if it exists under ~/.oh-my-zsh/custom with zsh extensions (.zsh)

LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

# follow XDG base dir specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export GOPATH="$XDG_DATA_HOME/go"
export GOBIN="$GOPATH/bin"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export FFMPEG_DATADIR="$XDG_CONFIG_HOME/ffmpeg"
export LESSHISTFILE="$XDG_CACHE_HOME/less_history"
export PYTHON_HISTORY="$XDG_DATA_HOME/python/history"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"

## Hide the default user name from the prompt
DEFAULT_USER=$(whoami)

# it was setting as user@machine-name making it ugly and long
# And most likely conflicting with oh-my-posh, as it fixed after any command
DISABLE_AUTO_TITLE="true"
ZSH_THEME_TERM_TITLE_IDLE="%~"

# default one in case a batcat is not available
export MANPAGER="less -R --use-color -Dd+r -Du+b"

if command -v brew &>/dev/null; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

## set VSCode as default editor if it is in the path and I'm running from VSCode terminal
if command -v code &>/dev/null && [[ "$TERM_PROGRAM" == "vscode" ]]; then
    export EDITOR='code --wait'
elif command -v nvim &>/dev/null; then
    export EDITOR='nvim'
elif command -v vim &>/dev/null; then
    export EDITOR='vim'
fi

export VISUAL="$EDITOR"

# disable shared history between ZSH instances
HISTORY_IGNORE="(l|ls|pwd|exit|clear|ll|lsa|cd ..|cd -) *"
HISTSIZE=10000
HISTFILE="$XDG_STATE_HOME/zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
# unsetopt inc_append_history
# unsetopt share_history
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# https://github.com/docker/cli/commit/b10fb430481574b34997e4b0e00b703cfcd6669e#diff-474a9d942d53cc2279d5641e4a9dcfb18958e412ad53940b53423a38033857d6
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/docker/README.md#settings
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

set -o vi

export DOTFILES_SHELL_PATH="$(dirname $(dirname $(readlink -f ${0:a})))"
export DOTFILES_PATH="$(dirname $DOTFILES_SHELL_PATH)"

source $DOTFILES_SHELL_PATH/bin/source-dotfiles $DOTFILES_SHELL_PATH

# ZSH has a basic vi mode
# if [ ! -d "$ZSH_CUSTOM/plugins/zsh-vi-mode" ]; then
#     git clone https://github.com/jeffreytse/zsh-vi-mode \
#         $ZSH_CUSTOM/plugins/zsh-vi-mode
# fi
# # https://github.com/jeffreytse/zsh-vi-mode
# function vim_mode_lazy_keybindings() {
# FZF needs to be loaded after zsh-vi-mode to avoid conflicts
# move it here if re-enabling zsh-vi-mode
#}
#zvm_after_init_commands+=(vim_mode_lazy_keybindings)

export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd --corepack-enabled --shell zsh)"
    source <(fnm completions --shell zsh)

    if [[ -z "$(fnm current)" ]]; then
        fnm install --lts
    fi

fi

# disabled in favor of g-plane/pnpm-shell-completion
# if command -v pnpm &>/dev/null; then
#     source <(pnpm completion zsh)
# fi

bindkey "^P" up-line-or-beginning-search
bindkey "^N" down-line-or-beginning-search

export FZF_DEFAULT_COMMAND="fd --follow $(printf -- '--exclude %s ' .git node_modules vendor) --hidden --color=never"
export FZF_DEFAULT_OPTS="--preview='bat -p --color=always {}'"
export FZF_CTRL_R_OPTS="--info inline --no-sort --no-preview"

if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
fi

if command -v oh-my-posh >/dev/null 2>&1; then
    eval "$(oh-my-posh init zsh --config $DOTFILES_SHELL_PATH/oh-my-posh.yaml)"
fi
