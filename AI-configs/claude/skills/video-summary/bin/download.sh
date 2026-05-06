#!/usr/bin/env bash
# Download a video via yt-dlp, or resolve a local file path.
#
# Usage: download.sh <url-or-path> <out-dir>
#
# Stdout: a single JSON object with keys: video_path, subtitle_path,
# thumbnail_path, info_path, title, uploader. Missing values are null.

set -euo pipefail

SOURCE="${1:?usage: download.sh <url-or-path> <out-dir>}"
OUT="${2:?usage: download.sh <url-or-path> <out-dir>}"

mkdir -p "${OUT}"

is_url() {
  [[ "$1" =~ ^https?:// ]]
}

pick_first() {
  local pattern="$1"
  for f in "${OUT}"/${pattern}; do
    [[ -f "$f" ]] && {
      printf '%s\n' "$f"
      return 0
    }
  done
  return 1
}

emit_json() {
  local chapters_json="null"
  if [[ -n "${4:-}" && -f "${4}" ]]; then
    chapters_json="$(jq '.chapters // null' "${4}" 2>/dev/null || echo null)"
  fi
  jq -n \
    --arg video "${1:-}" \
    --arg subtitle "${2:-}" \
    --arg thumbnail "${3:-}" \
    --arg info "${4:-}" \
    --arg title "${5:-}" \
    --arg uploader "${6:-}" \
    --arg channel "${7:-}" \
    --arg description "${8:-}" \
    --arg categories "${9:-}" \
    --arg tags "${10:-}" \
    --argjson chapters "${chapters_json}" \
    'def nonempty(s): if s == "" then null else s end;
     {
       video_path:     nonempty($video),
       subtitle_path:  nonempty($subtitle),
       thumbnail_path: nonempty($thumbnail),
       info_path:      nonempty($info),
       title:          nonempty($title),
       uploader:       nonempty($uploader),
       channel:        nonempty($channel),
       description:    nonempty($description),
       categories:     nonempty($categories),
       tags:           nonempty($tags),
       chapters:       $chapters
     }'
}

if is_url "${SOURCE}"; then
  if ! command -v yt-dlp >/dev/null 2>&1; then
    echo "[video-summary] yt-dlp not installed - run setup.sh" >&2
    exit 1
  fi

  set +e
  yt-dlp \
    -N 8 \
    -f 'bv*[height<=480]+ba/b[height<=480]/bv+ba/b' \
    --merge-output-format mp4 \
    --write-info-json \
    --write-subs \
    --sub-langs 'en,en-US,en-GB,en-orig' \
    --sub-format vtt \
    --convert-subs vtt \
    --write-thumbnail \
    --convert-thumbnails jpg \
    --no-playlist \
    --ignore-errors \
    -o "${OUT}/video.%(ext)s" \
    "${SOURCE}" >&2
  ytdlp_exit=$?
  set -e

  video_path=""
  for ext in mp4 mkv webm mov m4v; do
    if f="$(pick_first "video.${ext}")"; then
      video_path="$f"
      break
    fi
  done

  if [[ -z "${video_path}" ]]; then
    echo "[video-summary] yt-dlp did not produce a video file (exit ${ytdlp_exit})" >&2
    install_age_days=$((($(date +%s) - $(stat -f %m "$(command -v yt-dlp)")) / 86400))
    if ((install_age_days > 14)); then
      echo "[video-summary] yt-dlp install is ${install_age_days} days old - try: brew upgrade yt-dlp" >&2
    fi
    exit 1
  fi

  subtitle_path="$(pick_first 'video.*.vtt' || true)"
  thumbnail_path="$(pick_first 'video.jpg' || pick_first 'video.webp' || pick_first 'video.png' || true)"
  info_path="$(pick_first 'video.info.json' || true)"

  title=""
  uploader=""
  channel=""
  description=""
  categories=""
  tags=""
  if [[ -n "${info_path}" ]]; then
    title="$(jq -r '.title // empty' "${info_path}" 2>/dev/null || true)"
    uploader="$(jq -r '.uploader // .channel // empty' "${info_path}" 2>/dev/null || true)"
    channel="$(jq -r '.channel // .uploader // empty' "${info_path}" 2>/dev/null || true)"
    description="$(jq -r '.description // empty | .[0:1800]' "${info_path}" 2>/dev/null || true)"
    categories="$(jq -r '(.categories // []) | join(", ")' "${info_path}" 2>/dev/null || true)"
    tags="$(jq -r '(.tags // []) | join(", ")' "${info_path}" 2>/dev/null || true)"
  fi

  emit_json "${video_path}" "${subtitle_path}" "${thumbnail_path}" "${info_path}" "${title}" "${uploader}" "${channel}" "${description}" "${categories}" "${tags}"
else
  src="$(cd "$(dirname "${SOURCE}")" && pwd)/$(basename "${SOURCE}")"
  if [[ ! -f "${src}" ]]; then
    echo "[video-summary] file not found: ${SOURCE}" >&2
    exit 1
  fi
  emit_json "${src}" "" "" "" "$(basename "${src}")" "" "" "" "" ""
fi
