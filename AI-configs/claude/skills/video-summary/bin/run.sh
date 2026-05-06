#!/usr/bin/env bash
# Cache-aware orchestrator: download → frames → transcribe → summarize.
#
# Composes bin/watch.sh + bin/summarize.sh. Two layers of cache:
#   - pipeline cache (watch.sh): report.md, frames, transcript
#   - summary cache (this script): summary.md
# Re-running on the same source replays summary.md with no LLM call.
#
# Usage:
#   bash run.sh <url-or-path> [watch.sh flags] [--refresh-summary]
#
# Flags forwarded to watch.sh: --max-frames, --resolution, --fps,
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
REPORT="$(bash "${SCRIPT_DIR}/watch.sh" "${SOURCE}" "${WATCH_ARGS[@]}")"

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

# Cache miss: run summarize.sh, tee to disk and stdout.
printf '%s\n' "${REPORT}" |
  bash "${SCRIPT_DIR}/summarize.sh" |
  tee "${SUMMARY}"
