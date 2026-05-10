#!/usr/bin/env bash
# Cache-aware orchestrator: download → frames → transcribe → summarize.
#
# Composes bin/watch.sh + bin/summarize.sh. Two layers of cache:
#   - pipeline cache (watch.sh): report.md, frames, transcript, metrics.json
#   - summary cache (this script): summary.md (includes timings/cost table)
# Re-running on the same source replays summary.md with no LLM call.
#
# Usage:
#   bash run.sh <url-or-path> [watch.sh flags] [--refresh-summary]
#
# Flags forwarded to watch.sh: --max-frames, --height, --fps,
#   --start, --end, --language, --refresh
# Local flag:
#   --refresh-summary    re-run summarize.sh, ignore cached summary.md
#                        (use when video-summary-prompt.md changed)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REFRESH_SUMMARY=0
WATCH_ARGS=()
SOURCE=""

for arg in "$@"; do
  case "$arg" in
  --refresh-summary) REFRESH_SUMMARY=1 ;;
  *)
    if [[ -z "${SOURCE}" ]]; then
      SOURCE="$arg"
    else
      WATCH_ARGS+=("$arg")
    fi
    ;;
  esac
done

if [[ -z "${SOURCE}" ]]; then
  echo "usage: run.sh <url-or-path> [watch.sh flags] [--refresh-summary]" >&2
  exit 2
fi

# Run the pipeline. watch.sh's own cache handles the heavy work.
T0_PIPE="${SECONDS}"
REPORT="$(bash "${SCRIPT_DIR}/watch.sh" "${SOURCE}" "${WATCH_ARGS[@]}")"
T_PIPELINE=$((SECONDS - T0_PIPE))

# Pull the work dir out of the report's footer.
WORK_DIR="$(printf '%s\n' "${REPORT}" | awk -F'`' '/Work dir:/ { print $2; exit }')"
if [[ -z "${WORK_DIR}" || ! -d "${WORK_DIR}" ]]; then
  echo "[video-summary] could not parse Work dir from report" >&2
  exit 1
fi

SUMMARY="${WORK_DIR}/summary.md"

# Summary cache hit: replay unchanged.
if [[ "${REFRESH_SUMMARY}" -eq 0 && -f "${SUMMARY}" ]]; then
  echo "[video-summary] summary cache hit: ${SUMMARY}" >&2
  cat "${SUMMARY}"
  exit 0
fi

# Cache miss: run summarize.sh, then assemble summary.md with metrics table.
SUMMARY_TEXT="$(printf '%s\n' "${REPORT}" |
  bash "${SCRIPT_DIR}/summarize.sh" "${WORK_DIR}")"

METRICS="${WORK_DIR}/metrics.json"
CLAUDE_METRICS="${WORK_DIR}/claude_metrics.json"

format_secs() {
  awk -v s="$1" 'BEGIN {
    s = s + 0
    if (s >= 60) { m = int(s / 60); printf "%dm%02ds", m, s - m * 60 }
    else { printf "%ds", s }
  }'
}

PIPE_DOWNLOAD_S="$(jq -r '.download_s' "${METRICS}")"
PIPE_FRAMES_S="$(jq -r '.frames_s' "${METRICS}")"
PIPE_TRANSCRIBE_S="$(jq -r '.transcribe_s' "${METRICS}")"
PIPE_FRAMES="$(jq -r '.frame_count' "${METRICS}")"
PIPE_VIDEO_S="$(jq -r '.video_duration_s // empty' "${METRICS}")"
PIPE_TR_SOURCE="$(jq -r '.transcript_source' "${METRICS}")"

CLAUDE_COST="$(jq -r '.cost_usd' "${CLAUDE_METRICS}")"
CLAUDE_IN="$(jq -r '.input_tokens' "${CLAUDE_METRICS}")"
CLAUDE_OUT="$(jq -r '.output_tokens' "${CLAUDE_METRICS}")"
CLAUDE_CR="$(jq -r '.cache_read_tokens' "${CLAUDE_METRICS}")"
CLAUDE_CC="$(jq -r '.cache_create_tokens' "${CLAUDE_METRICS}")"
CLAUDE_MS="$(jq -r '.duration_ms' "${CLAUDE_METRICS}")"
CLAUDE_S=$((CLAUDE_MS / 1000))
CLAUDE_TURNS="$(jq -r '.num_turns' "${CLAUDE_METRICS}")"

T_TOTAL=$((T_PIPELINE + CLAUDE_S))

{
  printf '%s\n' "${SUMMARY_TEXT}"
  echo
  echo "---"
  echo
  echo "## Run metrics"
  echo
  echo "**Cost**"
  echo
  echo "- Total: \$${CLAUDE_COST}"
  echo
  echo "**Tokens (claude haiku)**"
  echo
  echo "- Input: ${CLAUDE_IN}"
  echo "- Output: ${CLAUDE_OUT}"
  echo "- Cache read: ${CLAUDE_CR}"
  echo "- Cache create: ${CLAUDE_CC}"
  echo "- Turns: ${CLAUDE_TURNS}"
  echo
  echo "**Time**"
  echo
  [[ -n "${PIPE_VIDEO_S}" ]] && echo "- Video duration: $(format_secs "${PIPE_VIDEO_S}")"
  echo "- Total wall time: $(format_secs "${T_TOTAL}")"
  echo "- Pipeline (watch.sh): $(format_secs "${T_PIPELINE}")"
  echo "  - Download: $(format_secs "${PIPE_DOWNLOAD_S}")"
  echo "  - Frame extraction: $(format_secs "${PIPE_FRAMES_S}") (${PIPE_FRAMES} frames)"
  echo "  - Transcribe (${PIPE_TR_SOURCE}): $(format_secs "${PIPE_TRANSCRIBE_S}")"
  echo "- Summarize (claude haiku): $(format_secs "${CLAUDE_S}")"
} >"${SUMMARY}"

cat "${SUMMARY}"
