#!/usr/bin/env bash
# Download a video via yt-dlp, or resolve a local file path.
#
# Usage: download.sh <url-or-path> <out-dir>
#
# Env: HEIGHT (default 480) caps download resolution. Do not lower the
# default below 480 - past 240p runs caused VLM OCR failures on frames.
# Agent escalation path: re-run with --refresh --height 720 (or higher).
#
# Stdout: a single JSON object with keys: video_path, subtitle_path,
# thumbnail_path, info_path, title, uploader. Missing values are null.

set -euo pipefail

SOURCE="${1:?usage: download.sh <url-or-path> <out-dir>}"
OUT="${2:?usage: download.sh <url-or-path> <out-dir>}"
HEIGHT="${HEIGHT:-480}"

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
    --arg upload_date "${11:-}" \
    --arg webpage_url "${12:-}" \
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
       upload_date:    nonempty($upload_date),
       webpage_url:    nonempty($webpage_url),
       chapters:       $chapters
     }'
}

if is_url "${SOURCE}"; then
  if ! command -v yt-dlp >/dev/null 2>&1; then
    echo "[video-summary] yt-dlp not installed - run setup.sh" >&2
    exit 1
  fi

  YTDLP_LOG="${OUT}/yt-dlp.log"
  # Format selector: prefer av01 (smallest), then vp9, then any (avc1 fallback).
  # Frames are extracted locally so codec choice is bandwidth-only.
  # Final fallback is capped at 1080p to prevent 4K downloads on sources with
  # missing/unreliable height tagging (some live VODs, edge-case extractors).
  FORMAT="bv*[vcodec^=av01][height<=${HEIGHT}]+ba/bv*[vcodec^=vp9][height<=${HEIGHT}]+ba/bv*[height<=${HEIGHT}]+ba/b[height<=${HEIGHT}]/bv[height<=1080]+ba/b[height<=1080]"
  set +e
  yt-dlp \
    -N 4 \
    -f "${FORMAT}" \
    --merge-output-format mp4 \
    --write-info-json \
    --write-subs \
    --sub-langs 'all' \
    --sub-format vtt \
    --convert-subs vtt \
    --write-thumbnail \
    --convert-thumbnails jpg \
    --no-playlist \
    --ignore-errors \
    -o "${OUT}/video.%(ext)s" \
    "${SOURCE}" >"${YTDLP_LOG}" 2>&1
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
    echo "[video-summary] yt-dlp log: ${YTDLP_LOG}" >&2
    tail -n 40 "${YTDLP_LOG}" >&2 || true
    install_age_days=$((($(date +%s) - $(stat -f %m "$(command -v yt-dlp)")) / 86400))
    if ((install_age_days > 14)); then
      echo "[video-summary] yt-dlp install is ${install_age_days} days old - try: brew upgrade yt-dlp" >&2
    fi
    exit 1
  fi

  # Subtitle picker. With --sub-langs all, yt-dlp writes video.<lang>.vtt for
  # every available manual sub language. Picking first-alphabetical silently
  # grabs Arabic (ar) over English (en) - hence the explicit chain below.
  #
  # 1. info.json .language (source language tag) -> video.<lang>*.vtt
  # 2. en -> en-* (English heuristic for sources without .language)
  # 3. pt -> pt-* (Portuguese heuristic, user's secondary language)
  # 4. nothing -> fall through to whisperkit
  info_path="$(pick_first 'video.info.json' || true)"
  pick_lang_vtt() {
    local lang="$1"
    pick_first "video.${lang}.vtt" || pick_first "video.${lang}-*.vtt" || return 1
  }
  subtitle_path=""
  if [[ -n "${info_path}" ]]; then
    src_lang="$(jq -r '.language // empty' "${info_path}" 2>/dev/null || true)"
    if [[ -n "${src_lang}" ]]; then
      subtitle_path="$(pick_lang_vtt "${src_lang}" || true)"
    fi
  fi
  if [[ -z "${subtitle_path}" ]]; then
    subtitle_path="$(pick_lang_vtt en || pick_lang_vtt pt || true)"
  fi
  raw_thumb="$(pick_first 'video.jpg' || pick_first 'video.webp' || pick_first 'video.png' || true)"
  thumbnail_path=""
  if [[ -n "${raw_thumb}" ]]; then
    ext="${raw_thumb##*.}"
    thumbnail_path="${OUT}/thumbnail.${ext}"
    mv "${raw_thumb}" "${thumbnail_path}"
  fi

  title=""
  uploader=""
  channel=""
  description=""
  categories=""
  tags=""
  upload_date=""
  webpage_url=""
  if [[ -n "${info_path}" ]]; then
    title="$(jq -r '.title // empty' "${info_path}" 2>/dev/null || true)"
    uploader="$(jq -r '.uploader // .channel // empty' "${info_path}" 2>/dev/null || true)"
    channel="$(jq -r '.channel // .uploader // empty' "${info_path}" 2>/dev/null || true)"
    description="$(jq -r '.description // empty | .[0:1800]' "${info_path}" 2>/dev/null || true)"
    categories="$(jq -r '(.categories // []) | join(", ")' "${info_path}" 2>/dev/null || true)"
    tags="$(jq -r '(.tags // []) | join(", ")' "${info_path}" 2>/dev/null || true)"
    raw_date="$(jq -r '.upload_date // empty' "${info_path}" 2>/dev/null || true)"
    if [[ "${raw_date}" =~ ^[0-9]{8}$ ]]; then
      upload_date="${raw_date:0:4}-${raw_date:4:2}-${raw_date:6:2}"
    fi
    webpage_url="$(jq -r '.webpage_url // empty' "${info_path}" 2>/dev/null || true)"
  fi

  emit_json "${video_path}" "${subtitle_path}" "${thumbnail_path}" "${info_path}" "${title}" "${uploader}" "${channel}" "${description}" "${categories}" "${tags}" "${upload_date}" "${webpage_url}"
else
  src="$(cd "$(dirname "${SOURCE}")" && pwd)/$(basename "${SOURCE}")"
  if [[ ! -f "${src}" ]]; then
    echo "[video-summary] file not found: ${SOURCE}" >&2
    exit 1
  fi
  emit_json "${src}" "" "" "" "$(basename "${src}")" "" "" "" "" "" "" ""
fi
