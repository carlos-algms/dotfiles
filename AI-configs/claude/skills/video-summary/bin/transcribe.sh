#!/usr/bin/env bash
# Transcribe an audio file to JSON segments.
#
# Usage: transcribe.sh <audio.wav> <out.json> [language]
#
# Output JSON shape (matches transcribe.py output):
#   [{"start": 0.0, "end": 2.4, "text": "..."}, ...]
#
# Swap point: replace the body of `run_backend` to use a different transcriber.

set -euo pipefail

AUDIO="${1:?usage: transcribe.sh <audio.wav> <out.json> [language]}"
OUT="${2:?usage: transcribe.sh <audio.wav> <out.json> [language]}"
LANG="${3:-}"

MODEL="large-v3-v20240930"
MODEL_PREFIX="openai"
MODEL_CACHE="${HOME}/.cache/whisperkit"
MODEL_DIR_NAME="${MODEL_PREFIX}_whisper-${MODEL}"
MODEL_PATH="${MODEL_CACHE}/models/argmaxinc/whisperkit-coreml/${MODEL_DIR_NAME}"

if [[ ! -d "${MODEL_PATH}" ]]; then
  echo "[video-summary] model missing: ${MODEL_PATH}" >&2
  echo "[video-summary] run setup.sh to download (~1-10 min depending on connection)" >&2
  exit 1
fi

run_backend() {
  local audio="$1" report_dir="$2"
  local args=(
    transcribe
    --audio-path "${audio}"
    --model "${MODEL}"
    --model-prefix "${MODEL_PREFIX}"
    --model-path "${MODEL_PATH}"
    --skip-special-tokens
    --report
    --report-path "${report_dir}"
  )
  if [[ -n "${LANG}" ]]; then
    args+=(--language "${LANG}")
  fi
  whisperkit-cli "${args[@]}" >&2
}

REPORT_DIR="$(mktemp -d -t whisperkit-report-XXXXXX)"
trap 'rm -rf "${REPORT_DIR}"' EXIT

run_backend "${AUDIO}" "${REPORT_DIR}"

REPORT_JSON="$(find "${REPORT_DIR}" -maxdepth 2 -name '*.json' -print -quit)"
if [[ -z "${REPORT_JSON}" ]]; then
  echo "[video-summary] whisperkit-cli produced no JSON report in ${REPORT_DIR}" >&2
  exit 1
fi

jq '[.segments[] | {start: (.start|tonumber), end: (.end|tonumber), text: (.text|gsub("^\\s+|\\s+$"; ""))}]' \
  "${REPORT_JSON}" >"${OUT}"

SEG_COUNT="$(jq 'length' "${OUT}")"
echo "[video-summary] transcribed ${SEG_COUNT} segments -> ${OUT}" >&2
