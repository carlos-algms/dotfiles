---
name: video-summary
description:
  Summarize a video (URL or local path) by downloading it, extracting frames,
  transcribing audio locally with whisperkit-cli, and producing a TLDR + verdict
  + key moments. Use when the user pastes a YouTube/Vimeo/X/etc URL, points at a
  local video file, or asks to summarize, watch, or extract takeaways from a
  video. Triggers on "summarize this video", "what's in this video", "watch
  this", URLs ending in /watch, /shorts, common video extensions
  (.mp4/.mov/.mkv/.webm).
allowed-tools:
  Bash(bash ~/.claude/skills/video-summary/bin/run.sh:*) Bash(bash
  ~/.claude/skills/video-summary/setup.sh:*)
---

# video-summary

Local-first video summarizer. yt-dlp downloads + pulls manual subs; ffmpeg
extracts frames; whisperkit-cli transcribes audio on-device when manual subs are
missing. A haiku subagent reads the frames + transcript and returns the summary
so you do not eat 50+ image tokens per call.

No external API, no Python venv. macOS / Apple Silicon only.

## Step 0: setup check (silent on success)

Skip if you already ran the script once this session.

```bash
test -d ~/.cache/whisperkit/models/argmaxinc/whisperkit-coreml/openai_whisper-large-v3-v20240930 \
  && command -v ffmpeg >/dev/null \
  && command -v yt-dlp >/dev/null \
  && command -v whisperkit-cli >/dev/null \
  && command -v jq >/dev/null \
  && echo OK
```

If output is `OK`, proceed. Otherwise tell the user:

> Setup is incomplete. Run `bash ~/.claude/skills/video-summary/setup.sh` once.
> First-time model download is ~626MB (1-10 min depending on connection).

Do not run setup.sh yourself. The user reviews and confirms.

## Step 1: parse the user input

Separate the video source from any specific question.

- `summarize https://youtu.be/abc` -> source = URL, question = none
- `https://youtu.be/abc what's the main argument?` -> source = URL, question =
  "what's the main argument?"
- `~/Movies/talk.mp4` -> source = path, question = none

## Step 2: run the skill

```bash
bash ~/.claude/skills/video-summary/bin/run.sh "<source>"
```

`run.sh` orchestrates `watch.sh` (download + frames + transcribe) and
`summarize.sh` (haiku CLI subprocess that reads frames + thumbnail and writes
the structured summary). Frame image tokens never enter your context - they only
live inside the subprocess.

Optional flags forwarded to `watch.sh`:

- `--max-frames N` lower the budget (default tier curve, hard cap 100)
- `--resolution W` frame width in px (default 480)
- `--start T` / `--end T` focus on a section
- `--fps F` override auto-fps (cap 2)
- `--language LANG` force whisperkit language (`en`, `pt`, `es`, ...)
- `--refresh` ignore the pipeline cache (re-download, re-transcribe)

Local flag handled by `run.sh`:

- `--refresh-summary` ignore the summary cache only (re-run the haiku pass;
  useful after editing `video-summary-prompt.md`)

Two cache layers under `~/.cache/video-summary/<id>/`:

- pipeline cache: `report.md`, `frames/`, `transcript.json`
- summary cache: `summary.md`

Both replay instantly on re-run. `--refresh` invalidates pipeline (which
implicitly invalidates summary). `--refresh-summary` only invalidates the haiku
pass.

Stdout of `run.sh` is the structured summary (TLDR / Verdict / Summary / Key
moments / Caveats / Pacing) plus a final `WORK_DIR:` line. Strip the `WORK_DIR:`
line from the user-facing reply but remember the path for follow-ups.

The legacy alternative if `claude` CLI is unavailable: use the Agent tool with
`subagent_type: general-purpose` and `model: haiku`, and pass the contents of
`video-summary-prompt.md` plus `report.md` as the prompt body.

## Step 3: handle follow-ups

The user may ask follow-ups about the same video:

- **"What was on screen at 2:15?"** Read the relevant frame from
  `<work_dir>/frames/frame_NNNN.jpg` directly. Do not re-dispatch the subagent
  for one frame.
- **"Re-summarize focused on the demo section"** Re-run `run.sh` with
  `--start/--end`; pipeline cache hit on the same source means only frames
  re-extract.
- **"Check the transcript around MM:SS"** Read `<work_dir>/transcript.json`
  directly.

If the user asks about a _different_ video, run `run.sh` on the new source.
Working dirs are independent per video ID.

## Step 4: cleanup

Cache lives at `~/.cache/video-summary/`. Do not delete entries proactively -
they are the cache. The user can `rm -rf ~/.cache/video-summary/<id>` themselves
when they want to drop one.

## Failure modes

- **Setup incomplete** -> point to `setup.sh`. Do not run it yourself.
- **yt-dlp fails on a URL** -> the script prints the install age. If
  > 14 days, suggest `brew upgrade yt-dlp` and ask the user to retry.
- **whisperkit-cli fails** -> hard fail. Surface the error verbatim. Do not fall
  back to frames-only.
- **No audio track** -> ffmpeg audio extract fails; same hard-fail path.
- **Subagent returns malformed output** -> surface what it returned and ask the
  user whether to retry, fall back to direct (you read frames), or accept as-is.

## Bundled scripts

- `bin/run.sh` cache-aware orchestrator (entry point)
- `bin/watch.sh` pipeline (download → frames → transcribe), cache-by-id
- `bin/summarize.sh` stdin report → claude -p haiku → stdout summary
- `bin/download.sh` yt-dlp wrapper / local path resolver
- `bin/extract-frames.py` ffprobe + ffmpeg, tiered fps curve
- `bin/transcribe.sh` whisperkit-cli wrapper (the swap point)
- `bin/transcribe.py` WebVTT parser (system python3, no venv)
- `video-summary-prompt.md` haiku subprocess prompt template
- `setup.sh` one-time install + model pre-download
