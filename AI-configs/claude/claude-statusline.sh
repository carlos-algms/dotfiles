#!/bin/bash
# Read JSON input once
input=$(cat)

# Debug: write to temp file
# echo "$input" >/tmp/claude-statusline-debug.json

# Extract data
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd')
COST=$(printf "%.2f" "$COST")
MODEL_NAME=$(echo "$input" | jq -r '.model.display_name')

# Context window data
WINDOW_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

# Use pre-calculated percentage from Claude (most accurate)
PERCENTAGE=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Calculate tokens from percentage (reverse calculation)
TOTAL_TOKENS=$((WINDOW_SIZE * PERCENTAGE / 100))

# Cap percentage at 100
if [ $PERCENTAGE -gt 100 ]; then
  PERCENTAGE=100
fi

# Generate 20-char bar (0-20 filled chars)
FILLED=$((PERCENTAGE / 5))
if [ $FILLED -gt 20 ]; then
  FILLED=20
fi
UNFILLED=$((20 - FILLED))

BAR=""
for ((i = 0; i < FILLED; i++)); do BAR="${BAR}█"; done
for ((i = 0; i < UNFILLED; i++)); do BAR="${BAR}░"; done

# Format tokens with K suffix for readability
format_tokens() {
  local tokens=$1
  if [ $tokens -ge 1000 ]; then
    echo "$((tokens / 1000))k"
  else
    echo "$tokens"
  fi
}

TOKENS_FORMATTED=$(format_tokens $TOTAL_TOKENS)
WINDOW_FORMATTED=$(format_tokens $WINDOW_SIZE)

echo "[$MODEL_NAME] 📁 ${DIR##*/} | $COST USD | $BAR ${PERCENTAGE}% | ${TOKENS_FORMATTED}/${WINDOW_FORMATTED}"

### Don't change from here ###
# https://code.claude.com/docs/en/statusline
#
# Example input: JSON
# {
#   "session_id": "abc123...",
#   "transcript_path": "/path/to/transcript.json",
#   "cwd": "/current/working/directory",
#   "model": {
#     "id": "claude-opus-4-5-20251101",
#     "display_name": "Opus 4.5"
#   },
#   "workspace": {
#     "current_dir": "/current/working/directory",
#     "project_dir": "/original/project/directory"
#   },
#   "version": "2.1.3",
#   "output_style": {
#     "name": "default"
#   },
#   "cost": {
#     "total_cost_usd": 0.01234,
#     "total_duration_ms": 45000,
#     "total_api_duration_ms": 2300,
#     "total_lines_added": 156,
#     "total_lines_removed": 23
#   },
#   "context_window": {
#     "total_input_tokens": 15234,
#     "total_output_tokens": 4521,
#     "context_window_size": 200000,
#     "current_usage": {
#       "input_tokens": 8500,
#       "output_tokens": 1200,
#       "cache_creation_input_tokens": 5000,
#       "cache_read_input_tokens": 2000
#     }
#   },
#   "exceeds_200k_tokens": false,
#   "vim": { "mode": "INSERT" }
# }
