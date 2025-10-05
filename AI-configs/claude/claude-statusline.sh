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
# Example input: JSON
# {
#   "cost": {
#     "total_api_duration_ms": 236622,
#     "total_cost_usd": 0.84030105,
#     "total_duration_ms": 389999,
#     "total_lines_added": 3,
#     "total_lines_removed": 0
#   },
#   "cwd": "/current/working/directory",
#   "exceeds_200k_tokens": false,
#   "model": {
#     "display_name": "Sonnet 4.5 (with 1M token context)",
#     "id": "claude-sonnet-4-5-20250929[1m]"
#   },
#   "output_style": {
#     "name": "default"
#   },
#   "session_id": "abc123-uuid",
#   "transcript_path": "/path/to/transcript.json",
#   "version": "2.0.0",
#   "workspace": {
#     "current_dir": "/current/working/directory",
#     "project_dir": "/original/project/directory"
#   }
# }
