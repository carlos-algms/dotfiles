#!/bin/bash
# Read JSON input once
input=$(cat)

# MODEL=$(echo "$input" | jq -r '.model.id')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd')
DURATION=$(echo "$input" | jq -r '.cost.total_duration_ms')

MODEL_NAME=$(echo "$input" | jq -r '.model.display_name')
# PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir')
# VERSION=$(echo "$input" | jq -r '.version')
# LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added')
# LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed')

echo "[$MODEL_NAME] 📁 ${DIR##*/} | $COST USD | $DURATION ms"

### Don't change from here ###
# https://code.claude.com/docs/en/statusline
#
# Example input: JSON
# {
#   "hook_event_name": "Status",
#   "session_id": "abc123...",
#   "transcript_path": "/path/to/transcript.json",
#   "cwd": "/current/working/directory",
#   "model": {
#     "id": "claude-opus-4-1",
#     "display_name": "Opus"
#   },
#   "workspace": {
#     "current_dir": "/current/working/directory",
#     "project_dir": "/original/project/directory"
#   },
#   "version": "1.0.80",
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
#   }
# }
