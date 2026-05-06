#!/usr/bin/env bash
# Run the haiku CLI subprocess on a watch.sh report.
#
# Reads the full report from stdin, prepends the @-reference to the prompt
# template, and forwards to `claude -p`. Output is the structured summary
# (TLDR / Verdict / Summary / Key moments / Caveats / Pacing) plus a
# trailing WORK_DIR: line.
#
# Usage:
#   bash watch.sh <source> | bash summarize.sh
#
# Notes:
#   - --disable-slash-commands prevents the spawned CLI from auto-loading
#     the same skill (which would loop).
#   - --allowedTools Read restricts the subprocess to read-only filesystem.
#   - Prompt path is sibling-relative to this script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="${SCRIPT_DIR}/../video-summary-prompt.md"

if [[ ! -f "${PROMPT_FILE}" ]]; then
  echo "[video-summary] prompt template not found: ${PROMPT_FILE}" >&2
  exit 1
fi

{
  printf '@%s\n\nReport:\n\n' "${PROMPT_FILE}"
  cat
} | claude -p \
    --model haiku \
    --disable-slash-commands \
    --allowedTools Read
