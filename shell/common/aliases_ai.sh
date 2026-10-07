# Enable dangerously-skipping-permissions without enabling it by default, shift-tab until you see it
alias cc="claude --allow-dangerously-skip-permissions "

if [[ -n "$IS_MAC" ]]; then
  claude() {
    if [[ "$PWD/" == "$HOME/work/"* ]]; then
      command claude "$@"
    else
      CLAUDE_CONFIG_DIR="$HOME/.claude-personal" command claude "$@"
    fi
  }
fi
