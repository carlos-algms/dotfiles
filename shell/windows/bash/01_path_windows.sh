
export ORIGINAL_PATH="$PATH"
cleanPath="/usr/local/bin:/usr/bin:/bin:/mingw64/bin:/c/Windows/system32:/c/Windows:/c/Windows/System32/WindowsPowerShell/v1.0"
cleanPath="${cleanPath}:${HOME}/AppData/Roaming/nvm:/c/Program Files/nodejs:/cmd:/c/Program Files/Microsoft VS Code/bin";
cleanPath="${cleanPath}:/usr/bin/vendor_perl:/usr/bin/core_perl"

PATH="$HOME/bin:$HOME/.bin:$HOME/.local/bin:${DOTFILES_SHELL_PATH}/windows/bin:${DOTFILES_SHELL_PATH}/bin:${cleanPath}"

export NODE_PATH="/c/Program Files/nodejs/node_modules"
