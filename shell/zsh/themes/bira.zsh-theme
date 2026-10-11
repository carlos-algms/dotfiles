source $ZSH/themes/bira.zsh-theme

# blank line between prompts
PROMPT=$'\n'"$PROMPT"

# bira hardcodes %n@%m; replace with a fixed label
PROMPT=${PROMPT/'%n@%m'/carlos@parloa-mac}

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
