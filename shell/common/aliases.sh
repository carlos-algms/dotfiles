alias Rsync="$(which -p rsync) --recursive \
    --no-inc-recursive \
    --progress \
    --links \
    --human-readable \
    --times \
    --perms"

alias path-show='echo $PATH | tr ":" "\n"'

# Using which because it might change in Windows
alias ff='`which -p find` . ! -path "**node_modules/**" ! -path "**.vscode/**" ! -path "**vendor/**" -type f -name '
# consider using `fd -t d -H` instead
# it also respects .gitignore and seems to be faster
# I must add some sane excludes in case the cwd isn't a git repo and it cant find a ignore file
alias fdir='find . \( -path "**/node_modules" -o -path "**/.git" \) -prune -o -type d -print'

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

if [ ! -z "$(command -v bat)" ]; then
    alias cat="bat "
    export MANPAGER='bat -l man -p'
elif [ ! -z "$(command -v batcat)" ]; then
    alias cat="batcat "
    export MANPAGER='batcat -l man -p'
fi

# Fix for the fuzzy cd auto completion
# https://github.com/ajeetdsouza/zoxide/issues/513#issuecomment-2040488941
if [ ! -z "$(command -v zoxide)" ]; then
    eval "${$(zoxide init zsh):s#_files -/#_cd#}"
    alias cd="z "
fi
