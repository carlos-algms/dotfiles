export ORIGINAL_PATH="$PATH"

### Less important paths on the top
enhancedPath="${PATH}";

# for some reason git-sdk was not including this automatically
enhancedPath="/mingw64/bin:${enhancedPath}"
enhancedPath="/cmd:${enhancedPath}"


enhancedPath="/mingw64/libexec/git-core:${enhancedPath}"
enhancedPath="${DOTFILES_SHELL_PATH}/bin:${enhancedPath}"
enhancedPath="${DOTFILES_SHELL_PATH}/windows/bin:${enhancedPath}"
enhancedPath="$HOME/.local/bin:${enhancedPath}"
enhancedPath="$HOME/.bin:${enhancedPath}"


export PATH="${enhancedPath}"
