---
name: video-summary
description:
  Summarize a video (URL or local path) by pulling captions first, falling back
  to audio-only transcription, and optionally extracting frames for visual
  summaries. Use when the user pastes a YouTube/Vimeo/X/etc URL, points at a
  local video file, or asks to summarize, watch, or extract takeaways from a
  video. Triggers on "summarize this video", "what's in this video", "watch
  this", URLs ending in /watch, /shorts, common video extensions
  (.mp4/.mov/.mkv/.webm).
allowed-tools:
  - Bash(bash ~/.claude/skills/video-summary/bin/run.sh *)
  - Bash(bash ~/.claude/skills/video-summary/setup.sh *)
---

# video-summary

Local-first video summarizer. For URLs, yt-dlp first pulls metadata and
captions without media download. If captions are missing or unusable, it
downloads audio only and transcribes on-device with whisperkit-cli. Full video
download and frame extraction happen only with `--with-frames`.

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

`run.sh` orchestrates `watch.sh` (metadata/captions -> audio fallback ->
optional frames -> transcript) and `summarize.sh` (haiku CLI subprocess that
writes the structured summary). Frame image tokens are used only when
`--with-frames` is passed.

Optional flags forwarded to `watch.sh`:

- `--with-frames` download full video and extract frames; off by default
- `--max-frames N` soft cap on frames; default 100. Applies only with
  `--with-frames`
- `--height H` caps full-video download resolution and frame scale (default
  480p). Applies only with `--with-frames`
- `--start T` / `--end T` focus on a section
- `--fps F` override auto-fps (cap 2)
- `--language LANG` force whisperkit language (`en`, `pt`, `es`, ...)
- `--refresh` wipe the whole work dir (download, frames, transcript, report,
  summary)
- `--refresh-download` re-download (cascades to frames + transcript + report +
  summary)
- `--refresh-frames` re-extract frames (cascades to report + summary)
- `--refresh-transcript` re-transcribe (cascades to report + summary)

### Unreadable frames

Frames are disabled by default. When `--with-frames` is used, frames default to
480p. Do NOT lower this default - past runs at 240p caused VLM OCR failures
(couldn't read code/slides/captions).

The summarizer subagent flags unreadable frames in its output via a
`FRAMES_UNREADABLE:` line, and `run.sh` echoes the same signal to stderr:

```
[video-summary] FRAMES_UNREADABLE: <path1>, <path2>, ...
[video-summary] re-run with --refresh --height 720 (or 1080) to escalate
```

When you see this signal, do NOT silently accept the summary. Tell the user
which frames were unreadable and offer to re-run at higher resolution:

```bash
bash ~/.claude/skills/video-summary/bin/run.sh "<source>" --with-frames --refresh-frames --height 720
```

Higher tiers: 720 -> 1080. Network cost roughly 2-3x per step. The cached video
is invalidated by `--refresh` and re-downloaded at the new cap.

Local flag handled by `run.sh`:

- `--refresh-summary` ignore the summary cache only (re-run the haiku pass;
  useful after editing `video-summary-prompt.md`)

### Resume points

Pipeline is composable. Each stage is gated by its own artifact under
`~/.cache/video-summary/<id>/`:

| Stage      | Artifact                      | Refresh flag           |
| ---------- | ----------------------------- | ---------------------- |
| download   | `download.json` + `download/` | `--refresh-download`   |
| frames     | `frames.tsv` + `frames/`      | `--refresh-frames`     |
| transcribe | `transcript.json`             | `--refresh-transcript` |
| summarize  | `summaries/summary-*.md`      | `--refresh-summary`    |

Cascade rule: each `--refresh-*` wipes its own stage and everything downstream.
Re-running on the same source replays cached stages instantly. Delete any
artifact directly (e.g. `rm transcript.json`) to redo that stage without passing
a flag.

Decision tree (pick the matching flag for the user's intent):

- "Re-summarize, transcript is fine" -> `--refresh-summary`
- You edited `video-summary-prompt.md` -> `--refresh-summary`
- "Transcript is bad, re-transcribe and re-summarize" -> `--refresh-transcript`
- "Need visual context" -> `--with-frames`
- "Frames are unreadable" -> `--with-frames --refresh-frames --height 720`
- "Re-download at higher resolution" ->
  `--with-frames --refresh-download --height 720`
- "Wipe everything" -> `--refresh`

Stdout of `run.sh` is the clean structured summary (TLDR / Verdict / Summary /
Key moments / Caveats / Pacing) plus `## Processing strategy` and
`## Run metrics` blocks. The `FRAMES_UNREADABLE:` and `WORK_DIR:` subagent
lines are stripped before output.

The work dir path is in the footer of `pre-summary-context.md` earlier in the
pipeline. To recover it for follow-ups, parse `Work dir:` from that file or use
the cache root `~/.cache/video-summary/<id>/` where `<id>` is derived from the
source URL/path.

The legacy alternative if `claude` CLI is unavailable: use the Agent tool with
`subagent_type: general-purpose` and `model: haiku`, and pass the contents of
`video-summary-prompt.md` plus `pre-summary-context.md` as the prompt body.

### Artifacts

After a complete run, `~/.cache/video-summary/<id>/` contains reusable stages
for both text-only and `--with-frames` runs:

- `download/video.mp4` - source video. Present only with `--with-frames`.
- `download/video.info.json` - full yt-dlp metadata dump.
- `download/video.<lang>.vtt` - manual or auto captions, when available.
- `download/audio.<ext>` - audio-only fallback when captions are missing or
  unusable.
- `download/thumbnail.<ext>` - thumbnail image, when yt-dlp provides one.
- `download.json` - manifest with paths + title/channel/chapters/description.
- `frames/frame_NNNN.jpg` - extracted frames at the chosen height/fps. Present
  only with `--with-frames`.
- `frames.tsv` - `<seconds>\t<absolute path>` per frame. Use this to map a frame
  to its timestamp - do NOT estimate from `frame_NNNN` indices.
- `audio.wav` - 16kHz mono PCM. Only present for whisper fallback input.
- `transcript.json` - `[{start, end, text}]`. Canonical transcript for the
  video. Read directly for transcript follow-ups.
- `pre-summary-context.md` - assembled markdown consumed by the haiku subagent.
  It includes frame paths only with `--with-frames`.
- `summaries/summary-<signature>.md` - final structured output for each option
  set.
- `summary.md` - copy of the latest emitted summary for convenience.
- `download.metrics.json` / `frames.metrics.json` / `transcribe.metrics.json` -
  per-stage `{seconds, cached, ...}`.
- `metrics.json` - merged per-stage view for `run.sh`.
- `claude_metrics.json` - haiku subprocess cost / tokens / duration.
- `frames_unreadable.txt` - sidecar; present only when the subagent flagged
  unreadable frames on the last run.

## Step 3: handle follow-ups

The user may ask follow-ups about the same video:

- **"What was on screen at 2:15?"** Re-run with `--with-frames` if frames are
  absent. If frames exist, read the relevant
  `<work_dir>/frames/frame_NNNN.jpg` directly. Do not re-dispatch the subagent
  for one frame.
- **"Re-summarize focused on the demo section"** Re-run `run.sh` with
  `--start/--end`; pipeline cache hit on the same source reuses cached media.
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
- **No captions and no audio track** -> ffmpeg audio extract fails; same
  hard-fail path.
- **Subagent returns malformed output** -> surface what it returned and ask the
  user whether to retry, fall back to direct (you read frames), or accept as-is.

## Bundled scripts

- `bin/run.sh` cache-aware orchestrator (entry point)
- `bin/watch.sh` pipeline (download -> transcribe -> optional frames),
  cache-by-id
- `bin/summarize.sh` stdin report → claude -p haiku → stdout summary
- `bin/download.sh` yt-dlp wrapper / local path resolver
- `bin/extract-frames.py` ffprobe + ffmpeg, tiered fps curve
- `bin/transcribe.sh` whisperkit-cli wrapper (the swap point)
- `bin/transcribe.py` WebVTT parser (system python3, no venv)
- `video-summary-prompt.md` haiku subprocess prompt template
- `setup.sh` one-time install + model pre-download
