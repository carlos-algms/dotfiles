IS_ZSH=""

if [[ -n "$ZSH_VERSION" ]]; then
    IS_ZSH=true
    export PS1=$'\n'"$PS1"$'\n'"λ "
    ### Allow use keyboard to navigate
    bindkey "[D" backward-word
    bindkey "[C" forward-word
    bindkey "^[a" beginning-of-line
    bindkey "^[e" end-of-line
fi

export IS_ZSH
