## https://github.com/ohmyzsh/ohmyzsh/blob/master/custom/example.zsh
# this file will be loaded automatically by zsh, if it exists under ~/.oh-my-zsh/custom with zsh extensions (.zsh)

export LANG="en_US"
export LC_ALL="en_US.UTF-8"

## Hide the default user name from the prompt
DEFAULT_USER=`whoami`


## set VSCode as default editor if it is in the path
if [[ -x "$(command -v code)" ]]; then
  export EDITOR='code --wait'
else
  export EDITOR='vim'
fi

# disable shared history between ZSH instances
unsetopt inc_append_history
unsetopt share_history


# https://github.com/docker/cli/commit/b10fb430481574b34997e4b0e00b703cfcd6669e#diff-474a9d942d53cc2279d5641e4a9dcfb18958e412ad53940b53423a38033857d6
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/docker/README.md#settings
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes


HISTORY_IGNORE="(ls|pwd|exit|clear|ll|lsa|cd ..|cd -)"


thisFilePath=`realpath ${0:a}`

DOTFILES_SHELL_PATH="$(dirname $thisFilePath)"

. $DOTFILES_SHELL_PATH/bin/source-dotfiles $DOTFILES_SHELL_PATH
