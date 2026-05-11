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

set +e
RESPONSE_JSON="$({
  printf '@%s\n\nReport:\n\n' "${PROMPT_FILE}"
  cat
} | claude -p \
    --model haiku \
    --output-format json \
    --disable-slash-commands \
    --allowedTools Read)"
claude_exit=$?
set -e

if ((claude_exit != 0)); then
  echo "[video-summary] claude -p exited ${claude_exit}" >&2
  printf '%s\n' "${RESPONSE_JSON}" >&2
  exit "${claude_exit}"
fi

# Check JSON-level error flag even when exit was 0.
is_error="$(jq -r '.is_error // false' <<<"${RESPONSE_JSON}" 2>/dev/null || echo true)"
if [[ "${is_error}" == "true" ]]; then
  echo "[video-summary] claude returned is_error=true" >&2
  jq -r '.result // .error // "no error detail"' <<<"${RESPONSE_JSON}" >&2 || true
  exit 1
fi

# Guard against null .result (CLI succeeded but produced no body).
result="$(jq -r '.result // empty' <<<"${RESPONSE_JSON}")"
if [[ -z "${result}" ]]; then
  echo "[video-summary] claude returned empty result" >&2
  exit 1
fi
printf '%s\n' "${result}"

jq '{
  cost_usd: .total_cost_usd,
  input_tokens: .usage.input_tokens,
  output_tokens: .usage.output_tokens,
  cache_read_tokens: (.usage.cache_read_input_tokens // 0),
  cache_create_tokens: (.usage.cache_creation_input_tokens // 0),
  duration_ms: .duration_ms,
  num_turns: .num_turns
}' <<<"${RESPONSE_JSON}" >"${WORK_DIR}/claude_metrics.json"
