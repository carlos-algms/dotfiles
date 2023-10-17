# Remove all branches except for the master
alias gbda='git branch | grep -v master | xargs git branch -D'

# override git commit command to remove --verbose
## commenting for now to test Copilot suggestions
# alias gc="git commit"
