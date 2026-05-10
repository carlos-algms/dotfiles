#!/usr/bin/env bash
# Run the haiku CLI subprocess on a watch.sh report.
#
# Reads the full report from stdin, prepends the @-reference to the prompt
# template, and forwards to `claude -p`. Output is the structured summary
# (TLDR / Verdict / Summary / Key moments / Caveats / Pacing).
#
# Usage:
#   bash watch.sh <source> | bash summarize.sh <work_dir>
#
# Side effect: writes <work_dir>/claude_metrics.json with cost/tokens/duration.
#
# Notes:
#   - --disable-slash-commands prevents the spawned CLI from auto-loading
#     the same skill (which would loop).
#   - --allowedTools Read restricts the subprocess to read-only filesystem.
#   - Prompt path is sibling-relative to this script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="${SCRIPT_DIR}/../video-summary-prompt.md"
WORK_DIR="${1:?usage: summarize.sh <work_dir>}"

if [[ ! -f "${PROMPT_FILE}" ]]; then
  echo "[video-summary] prompt template not found: ${PROMPT_FILE}" >&2
  exit 1
fi

RESPONSE_JSON="$({
  printf '@%s\n\nReport:\n\n' "${PROMPT_FILE}"
  cat
} | claude -p \
    --model haiku \
    --output-format json \
    --disable-slash-commands \
    --allowedTools Read)"

jq -r '.result' <<<"${RESPONSE_JSON}"

jq '{
  cost_usd: .total_cost_usd,
  input_tokens: .usage.input_tokens,
  output_tokens: .usage.output_tokens,
  cache_read_tokens: (.usage.cache_read_input_tokens // 0),
  cache_create_tokens: (.usage.cache_creation_input_tokens // 0),
  duration_ms: .duration_ms,
  num_turns: .num_turns
}' <<<"${RESPONSE_JSON}" >"${WORK_DIR}/claude_metrics.json"
