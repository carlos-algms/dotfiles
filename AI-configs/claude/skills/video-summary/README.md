# video-summary

Local-first video summarizer. Pastes a URL or local path, gets a structured
summary back: TLDR, Verdict, Summary, Key moments, Caveats.

## What it ships

- yt-dlp downloads video + manual subs + thumbnail + chapters + info.json
- ffmpeg extracts auto-scaled frames at a tiered budget
- whisperkit-cli (CoreML, ANE-accelerated) transcribes locally when no manual
  subs exist
- watch.sh orchestrates and prints a markdown report
- A haiku subagent reads frames + transcript and produces the summary

No external API, no Python venv, macOS / Apple Silicon only.

## Layout

- `SKILL.md` instructions for the agent
- `setup.sh` one-time installer + model pre-download
- `bin/` orchestrator and helpers
- `~/.cache/video-summary/<id>/` cached working dirs (one per video)
- `~/.cache/whisperkit/` model bundles

See `SKILL.md` for the full subagent prompt and report shape. See `setup.sh` for
what brew packages and model files land where.

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
               │   haiku subagent     │ ◀── reads frames + thumbnail
               │   (6-check prompt)   │     + transcript
               └──────────┬───────────┘
                          │
                          ▼
        TLDR / Verdict / Summary / Key moments / Caveats
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
- **Vendor-marketing videos without explicit sponsor signals.** Subagent
  classifies as `Uncertain` per the publisher rule, not affiliated.
- **Visual-heavy content (slides, code, dense UI).** Haiku vision is weaker than
  opus on fine text. Working dir stays on disk - rerun an opus subagent on the
  same artifacts for higher fidelity.

## Replacing Claude

Pipeline is provider-agnostic. Only the subagent dispatch in SKILL.md Step 3 is
harness-specific. To swap:

- Other agent CLI (Codex, Gemini, OpenCode) - rewrite Step 3 in that CLI's
  subagent syntax. The bin/ scripts and report shape do not change.
- Direct API or local model (LM Studio etc.) - write a wrapper script that loads
  SKILL.md as the system prompt, sends the report + base64 frames, and parses
  the response.

## Cost and latency

- Pipeline (download + frames + transcribe): seconds to ~1 min depending on
  network.
- Haiku subagent: ~25-40s for a 5-min video, ~50k tokens, around $0.05-0.07 per
  call.
- Cache hit: instant, $0.
