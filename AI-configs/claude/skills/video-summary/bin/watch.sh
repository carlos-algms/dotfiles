#!/usr/bin/env bash
# Orchestrator: download -> frames -> transcript -> markdown report.
#
# Stage-based, resumable. Each stage is gated by its own output artifact:
#   download.json, frames.tsv, transcript.json, report.md.
# Re-running on the same source replays from cache. Delete any artifact (or
# pass the matching --refresh-* flag) to redo that stage and downstream.
#
# Usage: watch.sh <url-or-path> [options]
#
# Options:
#   --max-frames N        override frame budget (cap 100)
#   --height H            frame height in px (omit / 0 = native, no scaling)
#   --fps F               override auto-fps (cap 2)
#   --start T             seconds or MM:SS or HH:MM:SS
#   --end T               seconds or MM:SS or HH:MM:SS
#   --language LANG       force whisperkit language (e.g. en, pt, es)
#   --out-dir DIR         work in a specific dir (skips cache-by-id)
#   --refresh             wipe whole work dir, re-run everything
#   --refresh-download    re-download (cascades to frames + transcript + report)
#   --refresh-frames      re-extract frames (cascades to report)
#   --refresh-transcript  re-transcribe (cascades to report)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${1:?usage: watch.sh <url-or-path> [options]}"
shift

OUT_DIR=""
LANGUAGE=""
REFRESH=0
REFRESH_DOWNLOAD=0
REFRESH_FRAMES=0
REFRESH_TRANSCRIPT=0
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
  --refresh-download)
    REFRESH_DOWNLOAD=1
    shift
    ;;
  --refresh-frames)
    REFRESH_FRAMES=1
    shift
    ;;
  --refresh-transcript)
    REFRESH_TRANSCRIPT=1
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

# Per-stage artifacts (cache keys).
DL_JSON="${OUT_DIR}/download.json"
DL_DIR="${OUT_DIR}/download"
FRAMES_TSV="${OUT_DIR}/frames.tsv"
FRAMES_DIR="${OUT_DIR}/frames"
TRANSCRIPT_JSON="${OUT_DIR}/transcript.json"
AUDIO_WAV="${OUT_DIR}/audio.wav"
REPORT="${OUT_DIR}/pre-summary-context.md"
METRICS="${OUT_DIR}/metrics.json"
M_DOWNLOAD="${OUT_DIR}/download.metrics.json"
M_FRAMES="${OUT_DIR}/frames.metrics.json"
M_TRANSCRIBE="${OUT_DIR}/transcribe.metrics.json"

# Resolve --height for download cap and frame scale (single source of truth).
HEIGHT_VAL="480"
i=0
while ((i < ${#PASS_THROUGH[@]})); do
  if [[ "${PASS_THROUGH[$i]}" == "--height" ]]; then
    HEIGHT_VAL="${PASS_THROUGH[$((i + 1))]}"
    break
  fi
  i=$((i + 2))
done

# Ensure --height is in PASS_THROUGH so extract-frames.py always receives it.
has_height=0
i=0
while ((i < ${#PASS_THROUGH[@]})); do
  [[ "${PASS_THROUGH[$i]}" == "--height" ]] && has_height=1
  i=$((i + 2))
done
if ((has_height == 0)); then
  PASS_THROUGH+=("--height" "${HEIGHT_VAL}")
fi

# --- Cascade refresh: top-down. Each level wipes itself + everything below.
if ((REFRESH == 1)); then
  rm -rf "${OUT_DIR}"
  mkdir -p "${OUT_DIR}"
fi
if ((REFRESH_DOWNLOAD == 1)); then
  rm -rf "${DL_DIR}" "${DL_JSON}" \
    "${FRAMES_DIR}" "${FRAMES_TSV}" "${M_FRAMES}" \
    "${TRANSCRIPT_JSON}" "${AUDIO_WAV}" "${M_TRANSCRIBE}" \
    "${M_DOWNLOAD}" "${REPORT}" "${METRICS}" \
    "${OUT_DIR}/summary.md"
fi
if ((REFRESH_FRAMES == 1)); then
  rm -rf "${FRAMES_DIR}" "${FRAMES_TSV}" "${M_FRAMES}" \
    "${REPORT}" "${METRICS}" "${OUT_DIR}/summary.md"
fi
if ((REFRESH_TRANSCRIPT == 1)); then
  rm -f "${TRANSCRIPT_JSON}" "${AUDIO_WAV}" "${M_TRANSCRIBE}" \
    "${REPORT}" "${METRICS}" "${OUT_DIR}/summary.md"
fi

echo "[video-summary] working dir: ${OUT_DIR}" >&2

write_stage_metrics() {
  # write_stage_metrics <metrics_file> <seconds> <cached:true|false> [extra_jq_args...]
  local file="$1" secs="$2" cached="$3"
  shift 3
  jq -n --argjson seconds "${secs}" --argjson cached "${cached}" "$@" \
    '{seconds: $seconds, cached: $cached} + ($ARGS.named // {})' >"${file}"
}

# ----- Stage 1: download -----
stage_download() {
  if [[ -f "${DL_JSON}" ]]; then
    echo "[video-summary] download: cache hit" >&2
    write_stage_metrics "${M_DOWNLOAD}" 0 true
    return 0
  fi
  local t0=${SECONDS}
  HEIGHT="${HEIGHT_VAL}" "${SCRIPT_DIR}/download.sh" "${SOURCE}" "${DL_DIR}" >"${DL_JSON}"
  write_stage_metrics "${M_DOWNLOAD}" $((SECONDS - t0)) false
}

# ----- Stage 2: frames -----
stage_frames() {
  if [[ -s "${FRAMES_TSV}" && -d "${FRAMES_DIR}" ]]; then
    echo "[video-summary] frames: cache hit" >&2
    local count
    count="$(wc -l <"${FRAMES_TSV}" | tr -d ' ')"
    write_stage_metrics "${M_FRAMES}" 0 true --argjson frame_count "${count}"
    return 0
  fi
  if [[ ! -f "${DL_JSON}" ]]; then
    echo "[video-summary] frames: missing download.json - run --refresh-download" >&2
    exit 1
  fi
  local video_path
  video_path="$(jq -r '.video_path // ""' "${DL_JSON}")"
  if [[ -z "${video_path}" || ! -f "${video_path}" ]]; then
    echo "[video-summary] frames: video file missing - run --refresh-download" >&2
    exit 1
  fi
  local duration
  duration="$(ffprobe -v quiet -print_format json -show_format "${video_path}" |
    jq -r '.format.duration // empty' | head -n1)"
  local args=("${PASS_THROUGH[@]}")
  if [[ -n "${duration}" && "${duration}" != "null" && "${duration}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    args+=("--duration" "${duration}")
  fi
  local t0=${SECONDS}
  python3 "${SCRIPT_DIR}/extract-frames.py" "${video_path}" "${FRAMES_DIR}" "${args[@]}" >"${FRAMES_TSV}"
  local count
  count="$(wc -l <"${FRAMES_TSV}" | tr -d ' ')"
  write_stage_metrics "${M_FRAMES}" $((SECONDS - t0)) false \
    --argjson frame_count "${count}"
}

# ----- Stage 3: transcribe -----
stage_transcribe() {
  if [[ -f "${TRANSCRIPT_JSON}" ]]; then
    echo "[video-summary] transcribe: cache hit" >&2
    local source="whisperkit (large-v3-turbo)"
    if [[ -f "${M_TRANSCRIBE}" ]]; then
      source="$(jq -r '.source // empty' "${M_TRANSCRIBE}")"
      [[ -z "${source}" ]] && source="whisperkit (large-v3-turbo)"
    elif [[ -f "${DL_JSON}" ]]; then
      local sub
      sub="$(jq -r '.subtitle_path // ""' "${DL_JSON}")"
      [[ -n "${sub}" && -f "${sub}" ]] && source="manual captions"
    fi
    write_stage_metrics "${M_TRANSCRIBE}" 0 true --arg source "${source}"
    return 0
  fi
  if [[ ! -f "${DL_JSON}" ]]; then
    echo "[video-summary] transcribe: missing download.json - run --refresh-download" >&2
    exit 1
  fi
  local video_path subtitle_path source=""
  video_path="$(jq -r '.video_path // ""' "${DL_JSON}")"
  subtitle_path="$(jq -r '.subtitle_path // ""' "${DL_JSON}")"
  local t0=${SECONDS}
  if [[ -n "${subtitle_path}" && -f "${subtitle_path}" ]]; then
    if python3 "${SCRIPT_DIR}/transcribe.py" "${subtitle_path}" "${TRANSCRIPT_JSON}"; then
      source="manual captions"
    fi
  fi
  if [[ -z "${source}" ]]; then
    if [[ -z "${video_path}" || ! -f "${video_path}" ]]; then
      echo "[video-summary] transcribe: video file missing - run --refresh-download" >&2
      exit 1
    fi
    ffmpeg -hide_banner -loglevel error -y \
      -i "${video_path}" -vn -ac 1 -ar 16000 "${AUDIO_WAV}" >&2
    "${SCRIPT_DIR}/transcribe.sh" "${AUDIO_WAV}" "${TRANSCRIPT_JSON}" "${LANGUAGE}"
    source="whisperkit (large-v3-turbo)"
  fi
  write_stage_metrics "${M_TRANSCRIBE}" $((SECONDS - t0)) false --arg source "${source}"
}

# ----- Stage 4: report (rebuilt when missing; cascades delete it upstream) -----
stage_report() {
  if [[ -f "${REPORT}" && -f "${METRICS}" ]]; then
    echo "[video-summary] report: cache hit" >&2
    return 0
  fi
  local title uploader channel categories tags upload_date webpage_url thumbnail_path
  local has_description has_chapters duration frame_count transcript_source
  title="$(jq -r '.title // ""' "${DL_JSON}")"
  uploader="$(jq -r '.uploader // ""' "${DL_JSON}")"
  channel="$(jq -r '.channel // ""' "${DL_JSON}")"
  categories="$(jq -r '.categories // ""' "${DL_JSON}")"
  tags="$(jq -r '.tags // ""' "${DL_JSON}")"
  upload_date="$(jq -r '.upload_date // ""' "${DL_JSON}")"
  webpage_url="$(jq -r '.webpage_url // ""' "${DL_JSON}")"
  thumbnail_path="$(jq -r '.thumbnail_path // ""' "${DL_JSON}")"
  has_description="$(jq -r 'if (.description // "") != "" then "1" else "" end' "${DL_JSON}")"
  has_chapters="$(jq -r 'if (.chapters // [] | length) > 0 then "1" else "" end' "${DL_JSON}")"

  local video_path
  video_path="$(jq -r '.video_path // ""' "${DL_JSON}")"
  duration=""
  if [[ -n "${video_path}" && -f "${video_path}" ]]; then
    duration="$(ffprobe -v quiet -print_format json -show_format "${video_path}" |
      jq -r '.format.duration // empty' | head -n1)"
  fi

  frame_count="$(wc -l <"${FRAMES_TSV}" | tr -d ' ')"
  transcript_source="$(jq -r '.source // "unknown"' "${M_TRANSCRIBE}")"

  # --start/--end filter for transcript view.
  local start_sec="" end_sec=""
  i=0
  while ((i < ${#PASS_THROUGH[@]})); do
    case "${PASS_THROUGH[$i]}" in
    --start) start_sec="${PASS_THROUGH[$((i + 1))]}" ;;
    --end) end_sec="${PASS_THROUGH[$((i + 1))]}" ;;
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

  {
    echo "# video-summary pre-summary context"
    echo
    if [[ -n "${webpage_url}" ]]; then
      echo "- **Video URL:** ${webpage_url}"
    else
      echo "- **Source:** ${SOURCE}"
    fi
    [[ -n "${title}" ]] && echo "- **Title:** ${title}"
    [[ -n "${uploader}" ]] && echo "- **Uploader:** ${uploader}"
    [[ -n "${upload_date}" ]] && echo "- **Published:** ${upload_date}"
    if [[ -n "${duration}" && "${duration}" != "null" ]]; then
      echo "- **Duration:** $(format_ts "${duration}") (${duration}s)"
    fi
    echo "- **Frames:** ${frame_count}"
    echo "- **Transcript source:** ${transcript_source}"
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
    echo "_Source: ${transcript_source}._"
    echo
    echo '```'
    jq -r --arg start "${start_sec}" --arg end "${end_sec}" '
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
    echo "_Work dir: \`${OUT_DIR}\` - cached. Re-runs on this source replay this context. Use \`--refresh\` to force re-process._"
  } >"${REPORT}"

  # Merge per-stage metrics into a single metrics.json for run.sh.
  jq -n \
    --arg duration "${duration:-}" \
    --slurpfile dl "${M_DOWNLOAD}" \
    --slurpfile fr "${M_FRAMES}" \
    --slurpfile tr "${M_TRANSCRIBE}" \
    '{
      video_duration_s: ($duration | if . == "" then null else tonumber end),
      transcript_source: ($tr[0].source // "unknown"),
      frame_count: ($fr[0].frame_count // 0),
      download_s: $dl[0].seconds,
      download_cached: $dl[0].cached,
      frames_s: $fr[0].seconds,
      frames_cached: $fr[0].cached,
      transcribe_s: $tr[0].seconds,
      transcribe_cached: $tr[0].cached
    }' >"${METRICS}"
}

stage_download
stage_frames
stage_transcribe
stage_report

cat "${REPORT}"
