# updatedPath="$HOME/bin"
# updatedPath="${updatedPath}:$HOME/.bin"
updatedPath="$HOME/.local/bin"
updatedPath="${updatedPath}:${DOTFILES_SHELL_PATH}/bin"
updatedPath="${updatedPath}:${DOTFILES_SHELL_PATH}/macos/bin"
updatedPath="${updatedPath}:$PATH"

export PATH="${updatedPath}"

unset updatedPath
