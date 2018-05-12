
export ORIGINAL_PATH="$PATH"
cleanPath="/mingw64/bin:/usr/local/bin:/usr/bin:/bin:/c/Windows/system32:/c/Windows:/c/Windows/System32/WindowsPowerShell/v1.0:${HOME}/AppData/Roaming/nvm:/c/Program Files/nodejs:/d/xampp-7.1.1/php:/d/xampp-7.1.1/mysql/bin:/c/ProgramData/ComposerSetup/bin:/cmd:/c/Program Files/Microsoft VS Code/bin:${HOME}/AppData/Roaming/Composer/vendor/bin:/usr/bin/vendor_perl:/usr/bin/core_perl"

PATH="$HOME/bin:$HOME/.bin:$HOME/.local/bin:${DOTFILES_SHELL_PATH}/windows/bin:${DOTFILES_SHELL_PATH}/bin:${cleanPath}"

export NODE_PATH="/c/Program Files/nodejs/node_modules"

export CYGWIN=winsymlinks:nativestrict
export MSYS=winsymlinks:nativestrict
