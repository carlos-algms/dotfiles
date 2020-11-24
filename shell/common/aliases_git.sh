# Remove all branches except for the master
alias gbda='git branch | grep -v master | xargs git branch -D'
