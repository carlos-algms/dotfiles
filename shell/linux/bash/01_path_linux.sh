PATH="$HOME/.local/bin:${DOTFILES_SHELL_PATH}/linux/bin:${DOTFILES_SHELL_PATH}/bin:$PATH"

FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
    PATH="$FNM_PATH:$PATH"
fi
