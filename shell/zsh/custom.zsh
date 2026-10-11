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
# Keep PATH free of duplicates. Each shell start prepends the same dirs again
# (~/.local/bin here and in ~/.zshrc, dotfiles bin dirs), and a nested shell
# inherits its parent's PATH, so entries pile up. -U keeps the first
# occurrence, so order is preserved. It must be set on PATH, not `path`:
# these scripts assign the scalar, and `typeset -U path` alone does not
# dedupe that.
typeset -U PATH

# Set local bin early so all commands are available
export PATH="$HOME/.local/bin:$PATH"

## Hide the default user name from the prompt on themes that read it, like `agnoster`
DEFAULT_USER="$USERNAME"

# it was setting as user@machine-name making it ugly and long
DISABLE_AUTO_TITLE="true"
ZSH_THEME_TERM_TITLE_IDLE="%~"

# default one in case a batcat is not available
export MANPAGER="less -R --use-color -Dd+r -Du+b"

## set VSCode as default editor if it is in the path and I'm running from VSCode terminal
if command -v code &>/dev/null && [[ "$TERM_PROGRAM" == "vscode" ]]; then
  export EDITOR='code --wait'
elif command -v nvim &>/dev/null; then
  export EDITOR='nvim'
elif command -v vim &>/dev/null; then
  export EDITOR='vim'
fi

export VISUAL="$EDITOR"

HISTORY_IGNORE="(l|ls|pwd|exit|clear|ll|lsa|cd ..|cd -)( *|)"
HISTSIZE=10000
HISTFILE="$XDG_STATE_HOME/zsh_history"
SAVEHIST=$HISTSIZE
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# https://github.com/docker/cli/commit/b10fb430481574b34997e4b0e00b703cfcd6669e#diff-474a9d942d53cc2279d5641e4a9dcfb18958e412ad53940b53423a38033857d6
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/docker/README.md#settings
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# Redundant with the oh-my-zsh vi-mode plugin and with EDITOR=nvim|vim (zsh picks the vi keymap when EDITOR is set).
# Kept so vi keys also work on machines where neither applies
set -o vi

if [[ -n "$HERDR_ENV" && -n "$KITTY_INSTALLATION_DIR" ]]; then
    export KITTY_SHELL_INTEGRATION="enabled"
    autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
    kitty-integration
    unfunction kitty-integration
fi

# Resolve this file's real path (it is symlinked into ~/.oh-my-zsh/custom): zsh
# parameter expansion avoids forking dirname/readlink on every shell start
export DOTFILES_SHELL_PATH="${${(%):-%x}:A:h:h}"
export DOTFILES_PATH="${DOTFILES_SHELL_PATH:h}"

source $DOTFILES_SHELL_PATH/bin/source-dotfiles $DOTFILES_SHELL_PATH

export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --corepack-enabled --shell zsh)"
  # Disabled: rarely used. brew already ships _fnm on macOS; ~14ms per shell start
  # source <(fnm completions --shell zsh)
fi

bindkey "^P" up-line-or-beginning-search
bindkey "^N" down-line-or-beginning-search

export FZF_DEFAULT_COMMAND="fd --follow $(printf -- '--exclude %s ' .git node_modules vendor) --hidden --color=never"
export FZF_DEFAULT_OPTS="--preview='$(
  cmd=$(command -v batcat || command -v bat)
  [[ -n $cmd ]] && echo "$cmd -p --color=always" || echo "cat"
) {}'"
export FZF_CTRL_R_OPTS="--info inline --no-sort --no-preview"

if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi
