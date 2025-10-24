if [ ! -z "$(command -v eza)" ]; then
  alias ls="eza --group-directories-first --color=auto --icons --almost-all --classify --time-style=long-iso "

  # https://askubuntu.com/a/466203 - colors explanation
  # export EZA_COLORS="da=0;37:ex=0;32:di=0;34"

  # Reset it to only use eza theme and avoid color conflicts
  # But I still need to set the directory color, otherwise its horrible
  export LS_COLORS="di=1;34"

  # https://github.com/eza-community/eza/blob/main/man/eza_colors-explanation.5.md
  export EZA_CONFIG_DIR=$HOME/.config/eza

  alias tree="ls --tree --ignore-glob='node_modules|build|dist|vendor|.turbo|.git|.next'"
elif [ ! -z "$(command -v gls)" ]; then
  # requires coreutils to be installed
  alias ls="gls -F --color=auto --group-directories-first"
else
  alias ls='`which -p ls` -F --color=auto --group-directories-first'
fi

alias l='ls -1a'
