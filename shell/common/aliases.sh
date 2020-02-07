alias Rsync="rsync -ravz"

alias ls='ls -F --color=auto --group-directories-first'
alias ll='ls -1a'

alias path-show='echo $PATH | tr ":" "\n"'

# Using which because it might change in Windows
alias _find='$(which find) . ! -path "**node_modules/**" ! -path "**.vscode/**" ! -path "**vendor/**" '
alias ff='_find -type f -name '

alias search='ack --context=2 --ignore-dir=.vscode --ignore-dir=node_modules --ignore-dir=vendor '
