alias Rsync="$(which -p rsync) --recursive \
    --no-inc-recursive \
    --progress \
    --links \
    --human-readable \
    --times \
    --perms"

alias path-show='echo $PATH | tr ":" "\n"'

excludes=(
    .git
    node_modules
    .vscode
    vendor
    .next
    build
    dist
    coverage
    storybook-static
    .turbo
    generated
)

if [[ -x "$(command -v fd)" ]]; then
    alias ff="fd --type f --hidden $(printf -- '--exclude %s ' "${excludes[@]}") --color=always --glob "

    alias fdir="fd -t d -H $(printf -- '--exclude %s ' "${excludes[@]}")"
else
    # Using which because it might change in Windows
    alias ff="$(which -p find)  . $(printf -- '! -path \"**/%s/**\" ' "${excludes[@]}") -type f -name "

    alias fdir="$(which -p find) . \( $(printf -- '-path \"**/%s\" -o ' "${excludes[@]}") \) -prune -o -type d -print"
fi

alias cdf='P="$(fdir | fzf)"; test -d "$P" && cd "$P" || echo "No directory selected."'

alias ack='ack --context=2 \
    --smart-case \
    --ignore-dir={.vscode,node_modules,vendor,.next,build,dist,coverage,storybook-static,.turbo,generated,lib} \
    --ignore-file=ext:{tsbuildinfo} \
    --ignore-file=match:"/test|spec|junit-results|json-results/\.d\.ts" '

alias yf="yarn --frozen-lockfile "
alias yff="yf --force "
alias clear-node-modules="find . -type d -name node_modules -prune | awk '{print length(\$0), \$0}' | sort -rn | cut -d' ' -f2- | xargs -L 1 -I % sh -c 'echo %; rm -rf %'"

alias tree="tree -C --dirsfirst -I 'node_modules|build|public|dist|vendor'"

## adding watch so it can use other aliases
alias watch="watch "

if [ ! -z "$(command -v nvim)" ]; then
    alias v="nvim "
elif [ ! -z "$(command -v vim)" ]; then
    alias v="vim "
elif [ ! -z "$(command -v vi)" ]; then
    alias v="vi "
fi

if [ ! -z "$(command -v kitten)" ]; then
    alias s="kitten ssh --kitten forward_remote_control=yes "
fi

if command -v bat &>/dev/null; then
    alias cat="bat "
    _manpager_cmd="bat -l man -p"
elif command -v batcat &>/dev/null; then
    alias cat="batcat "
    _manpager_cmd="batcat -l man -p"
fi

if [ -n "$_manpager_cmd" ]; then
    if [ -n "$IS_MAC" ]; then
        export MANPAGER="col -bx | $_manpager_cmd"
    else
        export MANPAGER="$_manpager_cmd"
    fi
fi

# Fix for the fuzzy cd auto completion
# https://github.com/ajeetdsouza/zoxide/issues/513#issuecomment-2040488941
if [ ! -z "$(command -v zoxide)" ]; then
    if [ -n "$ZSH_VERSION" ]; then
        eval "$(zoxide init zsh)"
    else
        eval "$(zoxide init bash)"
    fi

    alias cd="z "
fi
