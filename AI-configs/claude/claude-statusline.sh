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

# Check if current_usage exists and is not null
CURRENT_USAGE=$(echo "$input" | jq -r '.context_window.current_usage')

if [ "$CURRENT_USAGE" != "null" ]; then
  # Use current_usage when available
  INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
  OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
  CACHE_CREATE=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
  CACHE_READ=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
  TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS + CACHE_CREATE + CACHE_READ))
else
  # Fallback to totals when current_usage is null
  TOTAL_INPUT=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
  TOTAL_OUTPUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
  TOTAL_TOKENS=$((TOTAL_INPUT + TOTAL_OUTPUT))
fi

# Calculate percentage (0-100) with rounding, cap at 100
PERCENTAGE=$(((TOTAL_TOKENS * 100 + WINDOW_SIZE / 2) / WINDOW_SIZE))
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

echo "[$MODEL_NAME] 📁 ${DIR##*/} | $COST USD | $BAR ${PERCENTAGE}%"

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
