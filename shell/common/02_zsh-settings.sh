IS_ZSH=""

if [[ -n "$ZSH_VERSION" ]]; then
    IS_ZSH=true
    # this has to be per-theme base, so add it to .zshrc as needed.
    # export PS1=$'\n'"$PS1"$'\n'"λ "

    ### Allow use keyboard to navigate
    ## PS: Using a preset "Natural Text editing" does the trick, no need for this hack
    # bindkey "[D" backward-word
    # bindkey "[C" forward-word
    # bindkey "^[a" beginning-of-line
    # bindkey "^[e" end-of-line
fi

export IS_ZSH
