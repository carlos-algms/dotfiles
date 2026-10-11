export ORIGINAL_PATH="$PATH"

### Less important paths on the top
enhancedPath="${PATH}"

# for some reason git-sdk was not including this automatically
enhancedPath="/mingw64/bin:${enhancedPath}"
enhancedPath="/cmd:${enhancedPath}"

enhancedPath="/mingw64/libexec/git-core:${enhancedPath}"
enhancedPath="${DOTFILES_SHELL_PATH}/bin:${enhancedPath}"
enhancedPath="${DOTFILES_SHELL_PATH}/windows/bin:${enhancedPath}"
enhancedPath="$HOME/.bin:${enhancedPath}"

export PATH="${enhancedPath}"

unset enhancedPath

# Keep the first occurrence of each PATH entry and drop empty entries
# An empty entry means "current directory"
# Pure bash: forks are slow in Git Bash
_dedupe_path() {
    local dir out="" dirs
    IFS=: read -ra dirs <<<"$PATH"
    for dir in "${dirs[@]}"; do
        if [[ -z "$dir" ]]; then
            continue
        fi
        if [[ ":$out:" != *":$dir:"* ]]; then
            out="${out:+$out:}$dir"
        fi
    done
    PATH="$out"
}
_dedupe_path
unset -f _dedupe_path
