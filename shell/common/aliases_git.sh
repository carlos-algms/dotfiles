# Remove all branches except for the master
# I'm disabling this for now, as it's dangerous
# alias gbda='git branch | grep -v $(git_main_branch) | xargs git branch -D'

# Delete local branches whose upstream is gone; report ones a worktree still holds
gbdg() {
  local branch kept=''
  for branch in $(git branch --format='%(refname:short) %(upstream:track)' | awk '$2 == "[gone]" {print $1}'); do
    git branch -D "$branch" || kept="$kept $branch"
  done
  if [ -n "$kept" ]; then
    echo 'Not deleted, still attached to a worktree:'
    for branch in $kept; do
      echo "  $branch"
    done
  fi
}


# show all files, not truncated by top-level folders
alias gsa="git status --short --untracked-files=all"

# override git commit command to remove --verbose
## commenting for now to test Copilot suggestions
# alias gc="git commit"
