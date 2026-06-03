#!/usr/bin/env bash
# Nudge model to honor TERSE-MODE block already in system context.
# Wired into UserPromptSubmit + PostToolUse.
# UserPromptSubmit: always fires (user-initiated, rare).
# PostToolUse: 5s per-session debounce. First PostToolUse of a session is
# skipped (it usually fires immediately after a user prompt, which already
# nudged).

set -euo pipefail

payload=$(cat)
event=$(jq -r '.hook_event_name // ""' <<<"$payload")
session=$(jq -r '.session_id // "default"' <<<"$payload")

NUDGE='TERSE-MODE IS ACTIVE AND MANDATORY, not a reminder.
Before sending: no preamble, no narration of what you did, no praise.
Bullets/fragments only, no prose paragraphs.
ONE idea per line: break on every period, semicolon, or "and" joining clauses. Never pack multiple sentences on one line.
Answer first. Every clause must change the answer or be cut.'
STATE_DIR="${TMPDIR:-/tmp}"
STATE_FILE="${STATE_DIR%/}/terse-nudge-${session}.last"
DEBOUNCE_SECONDS=5

emit() {
  jq -n --arg evt "$event" --arg msg "$NUDGE" \
    '{hookSpecificOutput: {hookEventName: $evt, additionalContext: $msg}}'
}

case "$event" in
UserPromptSubmit)
  emit
  ;;
PostToolUse)
  now=$(date +%s)
  if [[ ! -f "$STATE_FILE" ]]; then
    # First PostToolUse this session: skip nudge, seed timestamp so the
    # next call inside the 5s window also stays quiet.
    echo "$now" >"$STATE_FILE"
    exit 0
  fi
  last=$(<"$STATE_FILE")
  if ((now - last >= DEBOUNCE_SECONDS)); then
    echo "$now" >"$STATE_FILE"
    emit
  fi
  ;;
esac
