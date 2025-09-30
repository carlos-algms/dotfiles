# Remove all branches except for the master
# I'm disabling this for now, as it's dangerous
# alias gbda='git branch | grep -v $(git_main_branch) | xargs git branch -D'

# Delete all local branches that have been removed from the remote (gone)
alias gbdg="git branch -vv | grep ': gone]' | awk '{print \$1}' | tee /dev/stderr | xargs git branch -D"

# override git commit command to remove --verbose
## commenting for now to test Copilot suggestions
# alias gc="git commit"
