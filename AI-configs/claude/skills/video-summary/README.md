# video-summary

Local-first video summarizer. Pastes a URL or local path, gets a structured
summary back: TLDR, Verdict, Summary, Key moments, Caveats, Pacing.

## What it ships

- yt-dlp downloads video + manual subs + thumbnail + chapters + info.json
- ffmpeg extracts auto-scaled frames at a tiered budget
- whisperkit-cli (CoreML, ANE-accelerated) transcribes locally when no manual
  subs exist
- watch.sh orchestrates and prints a markdown report
- summarize.sh pipes the report into a `claude -p` haiku subprocess that reads
  frames + transcript and produces the structured summary

No external API, no Python venv, macOS / Apple Silicon only.

## Layout

- `SKILL.md` instructions for the agent
- `video-summary-prompt.md` haiku subprocess prompt template
- `setup.sh` one-time installer + model pre-download
- `bin/watch.sh` orchestrator (download → frames → transcript → report)
- `bin/summarize.sh` pipes report into `claude -p` haiku subprocess
- `bin/download.sh`, `bin/extract-frames.py`, `bin/transcribe.{py,sh}` helpers
- `~/.cache/video-summary/<id>/` cached working dirs (one per video)
- `~/.cache/whisperkit/` model bundles

See `SKILL.md` for orchestration. See `video-summary-prompt.md` for the summary
template the subprocess executes. See `setup.sh` for what brew packages and
model files land where.

## Execution flow

```
                       user pastes URL or local path
                                    │
                                    ▼
                          ┌──────────────────┐
                          │     watch.sh     │
                          │  (orchestrator)  │
                          └─────────┬────────┘
                                    │
                ┌───────────────────┴───────────────────┐
                │                                       │
            cache hit                               cache miss
                │                                       │
                ▼                                       ▼
        replay report.md                       ┌──────────────────┐
            (instant)                          │   download.sh    │
                                               └─────────┬────────┘
                                                         │
                          ┌──────────────────┬───────────┤
                          │                  │           │
                          ▼                  ▼           ▼
                       yt-dlp           local file   fail loud
                          │              resolved
                          ▼
                  video + subs +
                  thumbnail +
                  info.json (chapters)
                          │
                          ▼
                ┌──────────────────┐
                │  extract-frames  │ ── ffprobe + ffmpeg ──▶ frames/*.jpg
                └─────────┬────────┘
                          │
                          ▼
             ┌──────────────────────────┐
             │   manual VTT present?    │
             └────────────┬─────────────┘
                          │
               yes ───────┴─────── no
                │                  │
                ▼                  ▼
          transcribe.py     transcribe.sh
           (parse VTT)     (whisperkit-cli)
                │                  │
                └────────┬─────────┘
                         │
                         ▼
                  transcript.json
                         │
                         ▼
               ┌──────────────────────┐
               │  report.md emitted   │
               │  (.complete marker)  │
               └──────────┬───────────┘
                          │
                          ▼
               ┌──────────────────────┐
               │    summarize.sh      │
               │  (claude -p haiku    │ ◀── reads frames + thumbnail
               │   subprocess, 7-check│     + transcript via Read tool
               │   prompt template)   │
               └──────────┬───────────┘
                          │
                          ▼
   TLDR / Verdict / Summary / Key moments / Caveats / Pacing
```

## Edge cases observed or expected

- **No manual subs and no audio track.** Whisperkit hard-fails. Skill aborts
  with the error.
- **yt-dlp extractor breakage.** Common when YouTube changes internals.
  download.sh prints install age and suggests `brew upgrade yt-dlp` if older
  than 14 days.
- **Live streams or DRM-protected sources.** yt-dlp refuses; skill aborts.
- **Very short clips (under 30s).** Frame curve produces 1-20 frames at up to 2
  fps. No special-casing needed.
- **Very long videos (over 30 min).** Capped at 100 frames sparsely sampled.
  Summary quality degrades on visual details. Use `--start/--end` to focus.
- **No chapters.** Most non-YouTube sources lack them. Report skips the Chapters
  section; summarizer still works fine.
- **Cached entry on re-run.** Skill replays cached `report.md` with no
  re-download. Use `--refresh` to force re-process.
- **Local file with same name in different paths.** Hash differs because derived
  from absolute path. Two cache entries.
- **Transcription hallucinations on very quiet or noisy audio.** Whisperkit may
  emit empty or repeated segments. Output passes through as-is; agent may flag
  in Caveats.
- **Vendor-marketing videos.** Publisher rule classifies between Owner/employee,
  Affiliated (paid), Channel-marketing, Uncertain, and Independent.
  Channel-marketing is the typical fit for a company channel covering
  third-party tools as part of its content strategy. Affiliated requires a
  quoted signal (sponsor card, promo code, "#ad", etc).
- **Visual-heavy content (slides, code, dense UI).** Haiku vision is weaker than
  opus on fine text. Working dir stays on disk - rerun an opus subagent on the
  same artifacts for higher fidelity.

## Replacing Claude

Pipeline is provider-agnostic. The only Claude-specific seam is the body of
`bin/summarize.sh`. To swap:

- Other agent CLI (Codex, Gemini, OpenCode) - edit `bin/summarize.sh` to invoke
  that CLI instead of `claude -p`. Pass it the prompt template as context
  (system prompt, file ref, or inline) and the report on stdin. The other bin/
  scripts and report shape do not change.
- Direct API or local model (LM Studio etc.) - same edit. Replace the `claude`
  invocation with curl + the chosen API, base64-encode the frames yourself, and
  parse the response.

`video-summary-prompt.md` works as-is across providers; it has no
Claude-specific syntax beyond the `Read` tool reference, which any multimodal
client can map to its own image-loading mechanism.

## Cost and latency

- Pipeline (download + frames + transcribe): seconds to ~1 min depending on
  network.
- Summarize subprocess (haiku): ~25-40s for a 5-min video. Token usage is
  dominated by frames (~50k for 50 frames at 480px, around $0.05-0.07 per call).
  Roughly an order of magnitude cheaper than running the same prompt on opus on
  the same artifacts.
- Cache hit on watch.sh: instant, $0. Re-running summarize.sh on a cached report
  still costs an LLM call - the cache is on the pipeline side, not the summary
  side.
