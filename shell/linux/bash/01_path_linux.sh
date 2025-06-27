export PATH="${DOTFILES_SHELL_PATH}/linux/bin:${DOTFILES_SHELL_PATH}/bin:$PATH"

export FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
    export PATH="$FNM_PATH:$PATH"
fi
