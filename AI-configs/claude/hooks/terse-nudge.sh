#!/usr/bin/env bash
# UserPromptSubmit hook: nudge model to honor TERSE-MODE block already in system context.
# Uses additionalContext so the message stays out of the visible transcript.

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "TERSE-MODE active in system context. You MUST respect it unless user says \"verbose\" or \"normal mode\"."
  }
}
JSON
