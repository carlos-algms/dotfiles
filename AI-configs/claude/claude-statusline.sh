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
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
SESSION_NAME=$(echo "$input" | jq -r '.session_name // empty')

BRANCH=$(git --no-optional-locks -C "$DIR" branch --show-current 2>/dev/null)

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

# Generate BAR_WIDTH-char bar (0-BAR_WIDTH filled chars)
BAR_WIDTH=16
make_bar() {
  local pct=$1 bar="" i
  [ "$pct" -gt 100 ] && pct=100
  local filled=$((pct * BAR_WIDTH / 100))
  for ((i = 0; i < BAR_WIDTH; i++)); do
    if [ $i -lt $filled ]; then bar="${bar}█"; else bar="${bar}░"; fi
  done
  echo "$bar"
}

BAR=$(make_bar "$PERCENTAGE")

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

MODEL_LABEL="$MODEL_NAME"
[ -n "$EFFORT" ] && MODEL_LABEL="$MODEL_LABEL/$EFFORT"

DIR_LABEL="${DIR##*/}"
GIT_ICON=$''
[ -n "$BRANCH" ] && DIR_LABEL="$DIR_LABEL ($GIT_ICON $BRANCH)"

echo " $DIR_LABEL"
[ -n "$SESSION_NAME" ] && echo "$SESSION_NAME"
echo "$MODEL_LABEL | $COST USD | $BAR ${PERCENTAGE}% ${TOKENS_FORMATTED}/${WINDOW_FORMATTED}"

FIVE_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty | round')
FIVE_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty | strflocaltime("%H:%M")')
WEEK_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty | round')

LIMITS=""
[ -n "$FIVE_PCT" ] && LIMITS="5h $(make_bar "$FIVE_PCT") ${FIVE_PCT}% (resets $FIVE_RESET)"
[ -n "$WEEK_PCT" ] && LIMITS="${LIMITS:+$LIMITS | }7d $(make_bar "$WEEK_PCT") ${WEEK_PCT}%"
if [ -n "$LIMITS" ]; then echo "$LIMITS"; fi

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
