alias Rsync="$(which -p rsync) --recursive --progress --links --human-readable --times --perms"

alias path-show='echo $PATH | tr ":" "\n"'

# Using which because it might change in Windows
alias ff='`which -p find` . ! -path "**node_modules/**" ! -path "**.vscode/**" ! -path "**vendor/**" -type f -name '

alias search='ack --context=2 --ignore-dir={.vscode,node_modules,vendor} '

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
    alias s="kitten ssh "
fi
