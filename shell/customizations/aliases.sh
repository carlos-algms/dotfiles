alias Rsync="rsync -ravz"

alias ls='/usr/bin/ls -F --color=auto --group-directories-first'
alias ll='ls -1a'

alias path-show='echo $PATH | sed "s/:/\n/g"'


alias _find='/usr/bin/find . ! -path "**node_modules/**" ! -path "**.vscode/**" ! -path "**vendor/**" '
alias ff='_find -type f -name '

alias search='ack --context=2 --ignore-dir=.vscode --ignore-dir=node_modules --ignore-dir=vendor '
