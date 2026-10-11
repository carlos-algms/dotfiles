source $ZSH/themes/bira.zsh-theme

# blank line between prompts
PROMPT=$'\n'"$PROMPT"

# bira hardcodes %n@%m; use a fixed label on mac
if [[ $OSTYPE == darwin* ]]; then
  PROMPT=${PROMPT/'%n@%m'/carlos@mac}
fi

# lambda instead of $
PROMPT=${PROMPT/'%(!.#.$)'/'%(!.#.λ)'}

# OS logo (Nerd Font) before the user label
if [[ $OSTYPE == darwin* ]]; then
  os_icon=$'%F{15}\uf179%f'
else
  os_icon=$'%F{208}\uf31b%f'
fi
PROMPT=${PROMPT/'╭─'/"╭─${os_icon} "}
unset os_icon
