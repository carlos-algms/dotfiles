
export ORIGINAL_PATH="$PATH"

cleanPath="$HOME/bin"
cleanPath="${cleanPath}:$HOME/.bin"
cleanPath="${cleanPath}:$HOME/.local/bin"
cleanPath="${cleanPath}:${DOTFILES_SHELL_PATH}/windows/bin"
cleanPath="${cleanPath}:${DOTFILES_SHELL_PATH}/bin"

cleanPath="${cleanPath}:/usr/local/bin"
cleanPath="${cleanPath}:/usr/bin"
cleanPath="${cleanPath}:/bin"
cleanPath="${cleanPath}:/mingw64/bin"
cleanPath="${cleanPath}:/cmd"
cleanPath="${cleanPath}:/c/Program Files/nodejs"
cleanPath="${cleanPath}:/usr/bin/vendor_perl"
cleanPath="${cleanPath}:/usr/bin/core_perl"

cleanPath="${cleanPath}:$HOME/AppData/Local/Programs/Microsoft VS Code/bin";
cleanPath="${cleanPath}:/c/Program Files (x86)/Yarn/bin"

cleanPath="${cleanPath}:/c/Windows/system32"
cleanPath="${cleanPath}:/c/Windows/System32/wbem"
cleanPath="${cleanPath}:/c/Windows"
cleanPath="${cleanPath}:/c/Windows/System32/WindowsPowerShell/v1.0"

export PATH="${cleanPath}"
export NODE_PATH="/c/Program Files/nodejs/node_modules"
