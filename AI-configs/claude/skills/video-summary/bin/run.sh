#!/usr/bin/env bash
# Cache-aware orchestrator: download → frames → transcribe → summarize.
#
# Composes bin/watch.sh + bin/summarize.sh. Two layers of cache:
#   - pipeline cache (watch.sh): pre-summary-context.md, frames, transcript, metrics.json
#   - summary cache (this script): summary.md (includes timings/cost table)
# Re-running on the same source replays summary.md with no LLM call.
#
# Usage:
#   bash run.sh <url-or-path> [watch.sh flags] [--refresh-summary]
#
# Flags forwarded to watch.sh: --max-frames, --height, --fps,
#   --start, --end, --language, --refresh, --refresh-download,
#   --refresh-frames, --refresh-transcript
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
UNREADABLE_FILE="${WORK_DIR}/frames_unreadable.txt"

# Surface FRAMES_UNREADABLE on stderr so the parent agent can detect escalation.
# Signal is persisted in a sidecar file (not in summary.md) so it survives
# cache replay without bleeding into user-facing output.
emit_unreadable_signal() {
  if [[ -s "${UNREADABLE_FILE}" ]]; then
    echo "[video-summary] $(cat "${UNREADABLE_FILE}")" >&2
    echo "[video-summary] re-run with --refresh --height 720 (or 1080) to escalate" >&2
  fi
}

# Summary cache hit: replay unchanged.
if [[ "${REFRESH_SUMMARY}" -eq 0 && -f "${SUMMARY}" ]]; then
  echo "[video-summary] summary cache hit: ${SUMMARY}" >&2
  emit_unreadable_signal
  cat "${SUMMARY}"
  exit 0
fi

# Cache miss: run summarize.sh, then assemble summary.md with metrics table.
SUMMARY_RAW="$(printf '%s\n' "${REPORT}" |
  bash "${SCRIPT_DIR}/summarize.sh" "${WORK_DIR}")"

# Extract the FRAMES_UNREADABLE line into a sidecar (escalation signal) and
# strip both that line and the WORK_DIR line from user-facing summary output.
rm -f "${UNREADABLE_FILE}"
unreadable_line="$(printf '%s\n' "${SUMMARY_RAW}" | grep -E '^FRAMES_UNREADABLE:' | head -n1 || true)"
if [[ -n "${unreadable_line}" ]]; then
  printf '%s\n' "${unreadable_line}" >"${UNREADABLE_FILE}"
fi
SUMMARY_TEXT="$(printf '%s\n' "${SUMMARY_RAW}" | grep -vE '^(FRAMES_UNREADABLE:|WORK_DIR:)' || true)"

METRICS="${WORK_DIR}/metrics.json"
CLAUDE_METRICS="${WORK_DIR}/claude_metrics.json"

if [[ ! -f "${METRICS}" || ! -f "${CLAUDE_METRICS}" ]]; then
  echo "[video-summary] metrics missing - stale cache dir (re-run with --refresh)" >&2
  exit 1
fi

format_secs() {
  awk -v s="$1" 'BEGIN {
    s = s + 0
    if (s >= 60) { m = int(s / 60); printf "%dm%02ds", m, s - m * 60 }
    else { printf "%ds", s }
  }'
}

format_stage() {
  # format_stage <seconds> <cached:true|false>
  if [[ "$2" == "true" ]]; then
    printf 'cached'
  else
    format_secs "$1"
  fi
}

PIPE_DOWNLOAD_S="$(jq -r '.download_s' "${METRICS}")"
PIPE_DOWNLOAD_CACHED="$(jq -r '.download_cached // false' "${METRICS}")"
PIPE_FRAMES_S="$(jq -r '.frames_s' "${METRICS}")"
PIPE_FRAMES_CACHED="$(jq -r '.frames_cached // false' "${METRICS}")"
PIPE_TRANSCRIBE_S="$(jq -r '.transcribe_s' "${METRICS}")"
PIPE_TRANSCRIBE_CACHED="$(jq -r '.transcribe_cached // false' "${METRICS}")"
PIPE_FRAMES="$(jq -r '.frame_count' "${METRICS}")"
PIPE_VIDEO_S="$(jq -r '.video_duration_s // empty' "${METRICS}")"
PIPE_TR_SOURCE="$(jq -r '.transcript_source' "${METRICS}")"

CLAUDE_COST="$(jq -r '.cost_usd // 0' "${CLAUDE_METRICS}")"
CLAUDE_IN="$(jq -r '.input_tokens // 0' "${CLAUDE_METRICS}")"
CLAUDE_OUT="$(jq -r '.output_tokens // 0' "${CLAUDE_METRICS}")"
CLAUDE_CR="$(jq -r '.cache_read_tokens // 0' "${CLAUDE_METRICS}")"
CLAUDE_CC="$(jq -r '.cache_create_tokens // 0' "${CLAUDE_METRICS}")"
CLAUDE_MS="$(jq -r '.duration_ms // 0' "${CLAUDE_METRICS}")"
CLAUDE_S=$((CLAUDE_MS / 1000))
CLAUDE_TURNS="$(jq -r '.num_turns // 0' "${CLAUDE_METRICS}")"

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
  echo "  - Download: $(format_stage "${PIPE_DOWNLOAD_S}" "${PIPE_DOWNLOAD_CACHED}")"
  echo "  - Frame extraction: $(format_stage "${PIPE_FRAMES_S}" "${PIPE_FRAMES_CACHED}") (${PIPE_FRAMES} frames)"
  echo "  - Transcribe (${PIPE_TR_SOURCE}): $(format_stage "${PIPE_TRANSCRIBE_S}" "${PIPE_TRANSCRIBE_CACHED}")"
  echo "- Summarize (claude haiku): $(format_secs "${CLAUDE_S}")"
} >"${SUMMARY}"

emit_unreadable_signal "${SUMMARY}"
cat "${SUMMARY}"
