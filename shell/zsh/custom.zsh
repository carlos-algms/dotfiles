## https://github.com/ohmyzsh/ohmyzsh/blob/master/custom/example.zsh
# this file will be loaded automatically by zsh, if it exists under ~/.oh-my-zsh/custom with zsh extensions (.zsh)

LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

# follow XDG base dir specification
XDG_CONFIG_HOME="$HOME/.config"
XDG_DATA_HOME="$HOME/.local/share"
XDG_CACHE_HOME="$HOME/.cache"
XDG_STATE_HOME="$HOME/.local/state"
GOPATH="$XDG_DATA_HOME/go"
GOBIN="$GOPATH/bin"
GOMODCACHE="$XDG_CACHE_HOME/go/mod"
FFMPEG_DATADIR="$XDG_CONFIG_HOME/ffmpeg"
LESSHISTFILE="$XDG_CACHE_HOME/less_history"
PYTHON_HISTORY="$XDG_DATA_HOME/python/history"

## Hide the default user name from the prompt
DEFAULT_USER=$(whoami)

# it was setting as user@machine-name making it ugly and long
# And most likely conflicting with oh-my-posh, as it fixed after any command
DISABLE_AUTO_TITLE="true"
ZSH_THEME_TERM_TITLE_IDLE="%~"

# default one in case a batcat is not available
MANPAGER="less -R --use-color -Dd+r -Du+b"

if command -v brew &>/dev/null; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

## set VSCode as default editor if it is in the path and I'm running from VSCode terminal
if [[ -x "$(command -v code)" ]] && [[ "$TERM_PROGRAM" == "vscode" ]]; then
    EDITOR='code --wait'
elif [[ -x "$(command -v nvim)" ]]; then
    EDITOR='nvim'
elif [[ -x "$(command -v vim)" ]]; then
    EDITOR='vim'
fi

# disable shared history between ZSH instances
HISTORY_IGNORE="(ls|pwd|exit|clear|ll|lsa|cd ..|cd -) *"
HISTSIZE=10000
HISTFILE=~/.zsh_history
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

DOTFILES_SHELL_PATH="$(dirname $(dirname $(readlink -f ${0:a})))"
DOTFILES_PATH="$(dirname $DOTFILES_SHELL_PATH)"

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
    bindkey "^P" up-line-or-beginning-search
    bindkey "^N" down-line-or-beginning-search

    if command -v fzf &>/dev/null; then
        # FZF needs to be loaded after zsh-vi-mode to avoid conflicts
        source <(fzf --zsh)
    fi
}

zvm_after_init_commands+=(vim_mode_lazy_keybindings)

FZF_DEFAULT_COMMAND="fd --follow $(printf -- '--exclude %s ' .git node_modules vendor) --hidden --color=never"
FZF_DEFAULT_OPTS="--preview='bat -p --color=always {}'"
FZF_CTRL_R_OPTS="--info inline --no-sort --no-preview"
