#!/usr/bin/env bash
# Resolve a video source into the smallest artifacts needed downstream.
#
# Usage: download.sh <url-or-path> <out-dir>
#
# Env:
#   NEED_VIDEO=1 downloads full video for frame extraction.
#   FORCE_AUDIO=1 skips subtitle-only success and downloads audio.
#   HEIGHT=480 caps full-video download resolution.
#
# Stdout: a single JSON manifest. Missing values are null.

set -euo pipefail

SOURCE="${1:?usage: download.sh <url-or-path> <out-dir>}"
OUT="${2:?usage: download.sh <url-or-path> <out-dir>}"
HEIGHT="${HEIGHT:-480}"
NEED_VIDEO="${NEED_VIDEO:-0}"
FORCE_AUDIO="${FORCE_AUDIO:-0}"

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

yt_dlp_failed() {
  local log="$1" exit_code="$2" stage="$3"
  echo "[video-summary] yt-dlp ${stage} failed (exit ${exit_code})" >&2
  echo "[video-summary] yt-dlp log: ${log}" >&2
  tail -n 40 "${log}" >&2 || true
  install_age_days=$((($(date +%s) - $(stat -f %m "$(command -v yt-dlp)")) / 86400))
  if ((install_age_days > 14)); then
    echo "[video-summary] yt-dlp install is ${install_age_days} days old - try: brew upgrade yt-dlp" >&2
  fi
}

emit_json() {
  local chapters_json="null"
  if [[ -n "${6:-}" && -f "${6}" ]]; then
    chapters_json="$(jq '.chapters // null' "${6}" 2>/dev/null || echo null)"
  fi
  jq -n \
    --arg video "${1:-}" \
    --arg audio "${2:-}" \
    --arg subtitle "${3:-}" \
    --arg subtitle_source "${4:-}" \
    --arg thumbnail "${5:-}" \
    --arg info "${6:-}" \
    --arg title "${7:-}" \
    --arg uploader "${8:-}" \
    --arg channel "${9:-}" \
    --arg description "${10:-}" \
    --arg categories "${11:-}" \
    --arg tags "${12:-}" \
    --arg upload_date "${13:-}" \
    --arg webpage_url "${14:-}" \
    --arg duration "${15:-}" \
    --arg download_mode "${16:-}" \
    --argjson chapters "${chapters_json}" \
    'def nonempty(s): if s == "" then null else s end;
     {
       video_path:      nonempty($video),
       audio_path:      nonempty($audio),
       subtitle_path:   nonempty($subtitle),
       subtitle_source: nonempty($subtitle_source),
       thumbnail_path:  nonempty($thumbnail),
       info_path:       nonempty($info),
       title:           nonempty($title),
       uploader:        nonempty($uploader),
       channel:         nonempty($channel),
       description:     nonempty($description),
       categories:      nonempty($categories),
       tags:            nonempty($tags),
       upload_date:     nonempty($upload_date),
       webpage_url:     nonempty($webpage_url),
       duration:        nonempty($duration),
       download_mode:   nonempty($download_mode),
       chapters:        $chapters
     }'
}

metadata() {
  title=""
  uploader=""
  channel=""
  description=""
  categories=""
  tags=""
  upload_date=""
  webpage_url=""
  duration=""
  if [[ -n "${info_path}" && -f "${info_path}" ]]; then
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
    duration="$(jq -r '.duration // empty' "${info_path}" 2>/dev/null || true)"
  fi
}

pick_lang_vtt() {
  local lang="$1"
  pick_first "video.${lang}.vtt" || pick_first "video.${lang}-*.vtt" || return 1
}

subtitle_source_for_lang() {
  local lang="$1"
  if [[ -z "${info_path}" || ! -f "${info_path}" ]]; then
    printf 'captions'
    return 0
  fi
  if jq -e --arg lang "${lang}" '
    (.subtitles // {}) | keys[]? | select(. == $lang or startswith($lang + "-"))
  ' "${info_path}" >/dev/null; then
    printf 'manual captions'
    return 0
  fi
  if jq -e --arg lang "${lang}" '
    (.automatic_captions // {}) | keys[]? | select(. == $lang or startswith($lang + "-"))
  ' "${info_path}" >/dev/null; then
    printf 'auto captions'
    return 0
  fi
  printf 'captions'
}

pick_subtitle() {
  subtitle_path=""
  subtitle_source=""
  subtitle_lang=""
  if [[ -n "${info_path}" && -f "${info_path}" ]]; then
    src_lang="$(jq -r '.language // empty' "${info_path}" 2>/dev/null || true)"
    if [[ -n "${src_lang}" ]]; then
      subtitle_path="$(pick_lang_vtt "${src_lang}" || true)"
      subtitle_lang="${src_lang}"
    fi
  fi
  if [[ -z "${subtitle_path}" ]]; then
    subtitle_path="$(pick_lang_vtt en || true)"
    subtitle_lang="en"
  fi
  if [[ -z "${subtitle_path}" ]]; then
    subtitle_path="$(pick_lang_vtt pt || true)"
    subtitle_lang="pt"
  fi
  if [[ -n "${subtitle_path}" ]]; then
    subtitle_source="$(subtitle_source_for_lang "${subtitle_lang}")"
  fi
}

pick_thumbnail() {
  raw_thumb="$(pick_first 'thumbnail.jpg' ||
    pick_first 'video.jpg' ||
    pick_first 'video.webp' ||
    pick_first 'video.png' ||
    true)"
  thumbnail_path=""
  if [[ -n "${raw_thumb}" ]]; then
    ext="${raw_thumb##*.}"
    thumbnail_path="${OUT}/thumbnail.${ext}"
    if [[ "${raw_thumb}" != "${thumbnail_path}" ]]; then
      mv -f "${raw_thumb}" "${thumbnail_path}"
    fi
  fi
}

pick_audio() {
  audio_path=""
  for ext in m4a webm opus mp3 mp4 aac wav; do
    if f="$(pick_first "audio.${ext}")"; then
      audio_path="$f"
      break
    fi
  done
}

pick_video() {
  video_path=""
  for ext in mp4 mkv webm mov m4v; do
    if f="$(pick_first "video.${ext}")"; then
      video_path="$f"
      break
    fi
  done
}

if is_url "${SOURCE}"; then
  if ! command -v yt-dlp >/dev/null 2>&1; then
    echo "[video-summary] yt-dlp not installed - run setup.sh" >&2
    exit 1
  fi

  info_path="$(pick_first 'video.info.json' || true)"
  pick_subtitle
  pick_thumbnail
  pick_audio
  pick_video

  sub_exit=0
  SUB_LOG="${OUT}/yt-dlp-subtitles.log"
  if [[ -z "${info_path}" || -z "${subtitle_path}" ]]; then
    set +e
    yt-dlp \
      --skip-download \
      --write-info-json \
      --write-subs \
      --write-auto-subs \
      --sub-langs 'all,-live_chat' \
      --sub-format vtt \
      --convert-subs vtt \
      --write-thumbnail \
      --convert-thumbnails jpg \
      --no-playlist \
      --ignore-errors \
      -o "${OUT}/video.%(ext)s" \
      "${SOURCE}" >"${SUB_LOG}" 2>&1
    sub_exit=$?
    set -e

    info_path="$(pick_first 'video.info.json' || true)"
    pick_subtitle
    pick_thumbnail
  fi

  download_mode="subtitles"

  if [[ "${NEED_VIDEO}" == "1" ]]; then
    if [[ -z "${video_path}" ]]; then
      VIDEO_LOG="${OUT}/yt-dlp-video.log"
      FORMAT="bv*[vcodec^=av01][height<=${HEIGHT}]+ba/bv*[vcodec^=vp9][height<=${HEIGHT}]+ba/bv*[height<=${HEIGHT}]+ba/b[height<=${HEIGHT}]/bv[height<=1080]+ba/b[height<=1080]"
      set +e
      yt-dlp \
        -N 4 \
        -f "${FORMAT}" \
        --merge-output-format mp4 \
        --write-info-json \
        --write-subs \
        --write-auto-subs \
        --sub-langs 'all,-live_chat' \
        --sub-format vtt \
        --convert-subs vtt \
        --write-thumbnail \
        --convert-thumbnails jpg \
        --no-playlist \
        --ignore-errors \
        -o "${OUT}/video.%(ext)s" \
        "${SOURCE}" >"${VIDEO_LOG}" 2>&1
      video_exit=$?
      set -e
      pick_video
      if [[ -z "${video_path}" ]]; then
        yt_dlp_failed "${VIDEO_LOG}" "${video_exit}" "video download"
        exit 1
      fi
    fi
    info_path="$(pick_first 'video.info.json' || true)"
    pick_subtitle
    pick_thumbnail
    download_mode="video"
  elif [[ "${FORCE_AUDIO}" == "1" || -z "${subtitle_path}" ]]; then
    if [[ -z "${audio_path}" ]]; then
      AUDIO_LOG="${OUT}/yt-dlp-audio.log"
      set +e
      yt-dlp \
        -N 4 \
        -f 'ba/bestaudio' \
        --no-playlist \
        --ignore-errors \
        -o "${OUT}/audio.%(ext)s" \
        "${SOURCE}" >"${AUDIO_LOG}" 2>&1
      audio_exit=$?
      set -e
      pick_audio
      if [[ -z "${audio_path}" ]]; then
        if [[ -z "${subtitle_path}" ]]; then
          yt_dlp_failed "${SUB_LOG}" "${sub_exit}" "subtitle download"
        fi
        yt_dlp_failed "${AUDIO_LOG}" "${audio_exit}" "audio download"
        exit 1
      fi
    fi
    download_mode="audio"
  fi

  metadata
  emit_json "${video_path}" "${audio_path}" "${subtitle_path}" "${subtitle_source}" \
    "${thumbnail_path}" "${info_path}" "${title}" "${uploader}" "${channel}" \
    "${description}" "${categories}" "${tags}" "${upload_date}" "${webpage_url}" \
    "${duration}" "${download_mode}"
else
  src="$(cd "$(dirname "${SOURCE}")" && pwd)/$(basename "${SOURCE}")"
  if [[ ! -f "${src}" ]]; then
    echo "[video-summary] file not found: ${SOURCE}" >&2
    exit 1
  fi
  emit_json "${src}" "" "" "" "" "" "$(basename "${src}")" "" "" "" "" "" "" "" "" "local"
fi
