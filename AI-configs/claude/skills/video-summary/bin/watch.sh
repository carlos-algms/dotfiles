#!/usr/bin/env bash
# Orchestrator: download → frames → transcript → markdown report.
#
# Usage: watch.sh <url-or-path> [options]
#
# Options:
#   --max-frames N    override frame budget (cap 100)
#   --height H        frame height in px (omit / 0 = native, no scaling)
#   --fps F           override auto-fps (cap 2)
#   --start T         seconds or MM:SS or HH:MM:SS
#   --end T           seconds or MM:SS or HH:MM:SS
#   --language LANG   force whisperkit language (e.g. en, pt, es)
#   --out-dir DIR     work in a specific dir (skips cache-by-id)
#   --refresh         ignore cache, re-run download/extract/transcribe
#
# Working dir is derived from the video ID and cached under
# ~/.cache/video-summary/<id>/. Re-running on the same source reuses
# everything. Pass --refresh to force a clean run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${1:?usage: watch.sh <url-or-path> [options]}"
shift

OUT_DIR=""
LANGUAGE=""
REFRESH=0
PASS_THROUGH=()

while (($# > 0)); do
  case "$1" in
  --out-dir)
    OUT_DIR="$2"
    shift 2
    ;;
  --language)
    LANGUAGE="$2"
    shift 2
    ;;
  --refresh)
    REFRESH=1
    shift
    ;;
  --max-frames | --height | --fps | --start | --end)
    PASS_THROUGH+=("$1" "$2")
    shift 2
    ;;
  *)
    echo "[video-summary] unknown flag: $1" >&2
    exit 2
    ;;
  esac
done

CACHE_ROOT="${HOME}/.cache/video-summary"

is_url() { [[ "$1" =~ ^https?:// ]]; }

extract_youtube_id() {
  # YouTube IDs are exactly 11 chars from [A-Za-z0-9_-].
  # Regex stored in vars per bash recommendation (no quoting inside [[ =~ ]]).
  local src="$1" id=""
  local re_short='youtu\.be/([A-Za-z0-9_-]{11})'
  local re_query='[?&]v=([A-Za-z0-9_-]{11})'
  local re_path='youtube\.com/(shorts|embed|live|v)/([A-Za-z0-9_-]{11})'
  if [[ "${src}" =~ $re_short ]]; then
    id="${BASH_REMATCH[1]}"
  elif [[ "${src}" =~ $re_query ]]; then
    id="${BASH_REMATCH[1]}"
  elif [[ "${src}" =~ $re_path ]]; then
    id="${BASH_REMATCH[2]}"
  fi
  printf '%s' "${id}"
}

derive_id() {
  local src="$1"
  if is_url "${src}"; then
    local raw_id
    raw_id="$(extract_youtube_id "${src}")"
    if [[ -z "${raw_id}" ]]; then
      # Non-YouTube URL: fall back to yt-dlp for the canonical ID.
      if ! command -v yt-dlp >/dev/null 2>&1; then
        echo "[video-summary] yt-dlp missing - run setup.sh" >&2
        exit 1
      fi
      raw_id="$(yt-dlp --get-id --no-playlist --no-warnings "${src}" 2>/dev/null | head -n1 || true)"
    fi
    if [[ -z "${raw_id}" ]]; then
      raw_id="$(printf '%s' "${src}" | shasum -a 1 | cut -c1-12)"
    fi
    printf 'url-%s' "${raw_id//[^A-Za-z0-9_-]/_}"
  else
    local abs hash
    abs="$(cd "$(dirname "${src}")" && pwd)/$(basename "${src}")"
    hash="$(printf '%s' "${abs}" | shasum -a 1 | cut -c1-12)"
    printf 'file-%s-%s' "$(basename "${src%.*}" | tr -c 'A-Za-z0-9_-' _)" "${hash}"
  fi
}

if [[ -z "${OUT_DIR}" ]]; then
  ID="$(derive_id "${SOURCE}")"
  OUT_DIR="${CACHE_ROOT}/${ID}"
fi
mkdir -p "${OUT_DIR}"

MARKER="${OUT_DIR}/.complete"
REPORT="${OUT_DIR}/report.md"

# Cache hit: replay the report unchanged. No frame/transcript regen.
if [[ "${REFRESH}" -eq 0 && -f "${MARKER}" && -f "${REPORT}" ]]; then
  echo "[video-summary] cache hit: ${OUT_DIR}" >&2
  cat "${REPORT}"
  exit 0
fi

if [[ "${REFRESH}" -eq 1 ]]; then
  rm -rf "${OUT_DIR}"
  mkdir -p "${OUT_DIR}"
fi

echo "[video-summary] working dir: ${OUT_DIR}" >&2

# 1. Download.
DL_JSON="${OUT_DIR}/download.json"
T0_DL="${SECONDS}"
"${SCRIPT_DIR}/download.sh" "${SOURCE}" "${OUT_DIR}/download" >"${DL_JSON}"
T_DOWNLOAD=$((SECONDS - T0_DL))

video_path="$(jq -r '.video_path // ""' "${DL_JSON}")"
subtitle_path="$(jq -r '.subtitle_path // ""' "${DL_JSON}")"
thumbnail_path="$(jq -r '.thumbnail_path // ""' "${DL_JSON}")"
title="$(jq -r '.title // ""' "${DL_JSON}")"
uploader="$(jq -r '.uploader // ""' "${DL_JSON}")"
channel="$(jq -r '.channel // ""' "${DL_JSON}")"
categories="$(jq -r '.categories // ""' "${DL_JSON}")"
tags="$(jq -r '.tags // ""' "${DL_JSON}")"
has_description="$(jq -r 'if (.description // "") != "" then "1" else "" end' "${DL_JSON}")"
has_chapters="$(jq -r 'if (.chapters // [] | length) > 0 then "1" else "" end' "${DL_JSON}")"

if [[ -z "${video_path}" || ! -f "${video_path}" ]]; then
  echo "[video-summary] no video file produced" >&2
  exit 1
fi

# 2. Probe duration for the report header.
DURATION="$(ffprobe -v quiet -print_format json -show_format "${video_path}" |
  jq -r '.format.duration // empty' | head -n1)"

# 3. Extract frames.
FRAMES_TSV="${OUT_DIR}/frames.tsv"
T0_FR="${SECONDS}"
python3 "${SCRIPT_DIR}/extract-frames.py" "${video_path}" "${OUT_DIR}/frames" "${PASS_THROUGH[@]}" >"${FRAMES_TSV}"
T_FRAMES=$((SECONDS - T0_FR))
FRAME_COUNT="$(wc -l <"${FRAMES_TSV}" | tr -d ' ')"

# 4. Transcript: prefer manual VTT subs, else whisperkit-cli.
TRANSCRIPT_JSON="${OUT_DIR}/transcript.json"
TRANSCRIPT_SOURCE=""

T0_TR="${SECONDS}"
if [[ -n "${subtitle_path}" && -f "${subtitle_path}" ]]; then
  if python3 "${SCRIPT_DIR}/transcribe.py" "${subtitle_path}" "${TRANSCRIPT_JSON}"; then
    TRANSCRIPT_SOURCE="manual captions"
  fi
fi

if [[ -z "${TRANSCRIPT_SOURCE}" ]]; then
  AUDIO_WAV="${OUT_DIR}/audio.wav"
  ffmpeg -hide_banner -loglevel error -y \
    -i "${video_path}" -vn -ac 1 -ar 16000 "${AUDIO_WAV}" >&2
  "${SCRIPT_DIR}/transcribe.sh" "${AUDIO_WAV}" "${TRANSCRIPT_JSON}" "${LANGUAGE}"
  TRANSCRIPT_SOURCE="whisperkit (large-v3-turbo)"
fi
T_TRANSCRIBE=$((SECONDS - T0_TR))

# 5. Apply --start/--end filter to transcript if set, by scanning PASS_THROUGH.
START_SEC=""
END_SEC=""
i=0
while ((i < ${#PASS_THROUGH[@]})); do
  case "${PASS_THROUGH[$i]}" in
  --start) START_SEC="${PASS_THROUGH[$((i + 1))]}" ;;
  --end) END_SEC="${PASS_THROUGH[$((i + 1))]}" ;;
  esac
  i=$((i + 2))
done

format_ts() {
  awk -v s="$1" 'BEGIN {
    s = s + 0
    h = int(s / 3600); s -= h * 3600
    m = int(s / 60);   sec = int(s - m * 60 + 0.5)
    if (h > 0) printf "%d:%02d:%02d", h, m, sec
    else       printf "%02d:%02d", m, sec
  }'
}

format_ts_simple() {
  awk -v s="$1" 'BEGIN {
    s = int(s + 0.5)
    m = int(s / 60); sec = s - m * 60
    printf "%02d:%02d", m, sec
  }'
}

# 6. Build markdown report (write to disk, then cat).
{
  echo "# video-summary report"
  echo
  echo "- **Source:** ${SOURCE}"
  [[ -n "${title}" ]] && echo "- **Title:** ${title}"
  [[ -n "${uploader}" ]] && echo "- **Uploader:** ${uploader}"
  if [[ -n "${DURATION}" && "${DURATION}" != "null" ]]; then
    echo "- **Duration:** $(format_ts "${DURATION}") (${DURATION}s)"
  fi
  echo "- **Frames:** ${FRAME_COUNT}"
  echo "- **Transcript source:** ${TRANSCRIPT_SOURCE}"
  [[ -n "${thumbnail_path}" ]] && echo "- **Thumbnail:** \`${thumbnail_path}\`"
  echo
  if [[ -n "${thumbnail_path}" ]]; then
    echo "## Thumbnail"
    echo
    echo "Read the thumbnail to see the title-card framing the publisher chose:"
    echo
    echo "- \`${thumbnail_path}\`"
    echo
  fi
  if [[ -n "${channel}" || -n "${categories}" || -n "${tags}" || -n "${has_description}" ]]; then
    echo "## Channel and metadata"
    echo
    [[ -n "${channel}" ]] && echo "- **Channel:** ${channel}"
    [[ -n "${categories}" ]] && echo "- **Categories:** ${categories}"
    [[ -n "${tags}" ]] && echo "- **Tags:** ${tags}"
    if [[ -n "${has_description}" ]]; then
      echo
      echo "**Description (truncated to ~1800 chars):**"
      echo
      echo '```'
      jq -r '.description // ""' "${DL_JSON}"
      echo '```'
    fi
    echo
  fi
  if [[ -n "${has_chapters}" ]]; then
    echo "## Chapters"
    echo
    echo "_Author-supplied. Use these as the structural index when summarizing._"
    echo
    jq -r '
      def fmt(s):
        (s | floor / 60 | floor | tostring | (if length < 2 then "0" + . else . end))
        + ":" +
        (s | floor % 60 | tostring | (if length < 2 then "0" + . else . end));
      .chapters[] |
      "[" + fmt(.start_time) + "-" + fmt(.end_time) + "] " + .title
    ' "${DL_JSON}"
    echo
  fi
  echo "## Frames"
  echo
  echo "Read each frame path below with the Read tool. Frames are chronological; \`t=MM:SS\` is the absolute timestamp."
  echo
  while IFS=$'\t' read -r ts path; do
    echo "- \`${path}\` (t=$(format_ts_simple "${ts}"))"
  done <"${FRAMES_TSV}"
  echo
  echo "## Transcript"
  echo
  echo "_Source: ${TRANSCRIPT_SOURCE}._"
  echo
  echo '```'
  jq -r --arg start "${START_SEC}" --arg end "${END_SEC}" '
    map(select(
      ($start == "" or .end >= ($start | tonumber)) and
      ($end == "" or .start <= ($end | tonumber))
    ))
    | .[]
    | "[" + (
        (.start | floor / 60 | floor | tostring | (if length < 2 then "0" + . else . end))
        + ":" +
        (.start | floor % 60 | tostring | (if length < 2 then "0" + . else . end))
      ) + "] " + .text
  ' "${TRANSCRIPT_JSON}"
  echo '```'
  echo
  echo "---"
  echo "_Work dir: \`${OUT_DIR}\` — cached. Re-runs on this source replay this report. Use \`--refresh\` to force re-process._"
} >"${REPORT}"

jq -n \
  --arg duration "${DURATION:-}" \
  --arg transcript_source "${TRANSCRIPT_SOURCE}" \
  --argjson frame_count "${FRAME_COUNT:-0}" \
  --argjson t_download "${T_DOWNLOAD:-0}" \
  --argjson t_frames "${T_FRAMES:-0}" \
  --argjson t_transcribe "${T_TRANSCRIBE:-0}" \
  '{
    video_duration_s: ($duration | if . == "" then null else tonumber end),
    transcript_source: $transcript_source,
    frame_count: $frame_count,
    download_s: $t_download,
    frames_s: $t_frames,
    transcribe_s: $t_transcribe
  }' >"${OUT_DIR}/metrics.json"

touch "${MARKER}"
cat "${REPORT}"
