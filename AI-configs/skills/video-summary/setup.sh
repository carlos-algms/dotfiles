#!/usr/bin/env bash
# One-time setup for the video-summary skill.
# Installs required brew packages and pre-downloads the whisperkit model.

set -euo pipefail

MODEL="large-v3-v20240930"
MODEL_PREFIX="openai"
MODEL_DIR_NAME="${MODEL_PREFIX}_whisper-${MODEL}"
MODEL_CACHE="${HOME}/.cache/whisperkit"
MODEL_PATH="${MODEL_CACHE}/models/argmaxinc/whisperkit-coreml/${MODEL_DIR_NAME}"

declare -a BREW_NEEDED=()
for pkg in ffmpeg yt-dlp whisperkit-cli jq; do
  if ! brew list --formula "${pkg}" >/dev/null 2>&1; then
    BREW_NEEDED+=("${pkg}")
  fi
done

NEED_MODEL=0
[[ ! -d "${MODEL_PATH}" ]] && NEED_MODEL=1

if ((${#BREW_NEEDED[@]} == 0)) && ((NEED_MODEL == 0)); then
  echo "[video-summary] already set up:"
  echo "  - all brew packages installed"
  echo "  - model present at ${MODEL_PATH}"
  exit 0
fi

cat <<EOF
[video-summary] setup will:
EOF
for pkg in "${BREW_NEEDED[@]}"; do
  case "${pkg}" in
  ffmpeg) echo "  - brew install ffmpeg          (~50MB, frame + audio extraction)" ;;
  yt-dlp) echo "  - brew install yt-dlp          (~25MB, video + subtitle download)" ;;
  whisperkit-cli) echo "  - brew install whisperkit-cli  (~50MB, local transcription)" ;;
  jq) echo "  - brew install jq              (~1MB, JSON parsing)" ;;
  esac
done
if ((NEED_MODEL == 1)); then
  echo "  - download whisper model      (~626MB to ${MODEL_PATH}, 1-10 min depending on connection)"
fi

echo
read -r -p "[video-summary] proceed? (y/n) " confirm
if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
  echo "[video-summary] aborted"
  exit 1
fi

if ((${#BREW_NEEDED[@]} > 0)); then
  echo "[video-summary] installing: ${BREW_NEEDED[*]}"
  brew install "${BREW_NEEDED[@]}"
fi

if ((NEED_MODEL == 1)); then
  mkdir -p "${MODEL_CACHE}"
  echo "[video-summary] downloading model ${MODEL_DIR_NAME} -> ${MODEL_CACHE}"
  # whisperkit-cli has no dedicated download subcommand; pre-download by
  # invoking transcribe with --download-model-path on a tiny silent wav.
  TMP_WAV="$(mktemp -t video-summary-silence-XXXXXX).wav"
  trap 'rm -f "${TMP_WAV}"' EXIT
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i anullsrc=r=16000:cl=mono -t 0.5 "${TMP_WAV}"
  whisperkit-cli transcribe \
    --audio-path "${TMP_WAV}" \
    --model "${MODEL}" \
    --model-prefix "${MODEL_PREFIX}" \
    --download-model-path "${MODEL_CACHE}" \
    --download-tokenizer-path "${MODEL_CACHE}" \
    >/dev/null
  if [[ ! -d "${MODEL_PATH}" ]]; then
    echo "[video-summary] model download seemed to succeed but ${MODEL_PATH} not found" >&2
    echo "[video-summary] inspect ${MODEL_CACHE} to see where files landed" >&2
    exit 1
  fi
fi

echo "[video-summary] setup complete"
