source $ZSH/themes/bira.zsh-theme

# blank line between prompts
PROMPT=$'\n'"$PROMPT"

# bira hardcodes %n@%m; replace with a fixed label
PROMPT=${PROMPT/'%n@%m'/carlos@parloa-mac}

# lambda instead of $
PROMPT=${PROMPT/'%(!.#.$)'/'%(!.#.λ)'}
