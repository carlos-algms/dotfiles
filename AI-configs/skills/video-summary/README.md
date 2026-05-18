# video-summary

Local-first video summarizer. Pastes a URL or local path, gets a structured
summary back: TLDR, Verdict, Summary, Key moments, Caveats, Pacing.

## What it ships

- yt-dlp pulls metadata and captions without media download
- yt-dlp falls back to audio-only download when captions are missing or unusable
- ffmpeg extracts auto-scaled frames only with `--with-frames`
- whisperkit-cli (CoreML, ANE-accelerated) transcribes local audio fallback
- watch.sh orchestrates and prints a markdown report
- summarize.sh pipes the report into a `claude -p` haiku subprocess that reads
  transcript plus optional frames and produces the structured summary

No external API, no Python venv, macOS / Apple Silicon only.

## Layout

- `SKILL.md` instructions for the agent
- `video-summary-prompt.md` haiku subprocess prompt template
- `setup.sh` one-time installer + model pre-download
- `bin/run.sh` cache-aware orchestrator (entry point, two-layer cache)
- `bin/watch.sh` pipeline (download -> transcript -> optional frames -> report)
- `bin/summarize.sh` pipes report into `claude -p` haiku subprocess
- `bin/download.sh`, `bin/extract-frames.py`, `bin/transcribe.{py,sh}` helpers
- `~/.cache/video-summary/<id>/` cached working dirs (one per video)
- `~/.cache/whisperkit/` model bundles

See `SKILL.md` for orchestration. See `video-summary-prompt.md` for the summary
template the subprocess executes. See `setup.sh` for what brew packages and
model files land where.

## Execution flow

```text
user source
  -> run.sh
  -> watch.sh cache
  -> download.sh
     -> URL: metadata + captions only
     -> no usable captions: audio-only download
     -> --with-frames: full video download
     -> local file: resolve path
  -> transcribe.py for VTT captions
  -> transcribe.sh + whisperkit-cli for audio fallback
  -> extract-frames.py only with --with-frames
  -> pre-summary-context.md
  -> summarize.sh
  -> summaries/summary-<signature>.md cache
  -> summary.md latest output
```

Default URL runs avoid full video download. Full video is a last resort for
visual summaries, requested with `--with-frames`.

All modes share one work dir per source. A later `--with-frames` run reuses
existing captions/transcript and adds only the missing video/frame artifacts.
Summaries are cached per option signature inside that same work dir.

## Edge cases observed or expected

- **No captions and no audio track.** Whisperkit hard-fails. Skill aborts with
  the error.
- **yt-dlp extractor breakage.** Common when YouTube changes internals.
  download.sh prints install age and suggests `brew upgrade yt-dlp` if older
  than 14 days.
- **Live streams or DRM-protected sources.** yt-dlp refuses; skill aborts.
- **Very short clips (under 30s).** With `--with-frames`, frame curve produces
  1-20 frames at up to 2 fps. No special-casing needed.
- **Very long videos (over 30 min).** With `--with-frames`, capped at 100
  frames sparsely sampled. Summary quality degrades on visual details. Use
  `--start/--end` to focus.
- **No chapters.** Most non-YouTube sources lack them. Report skips the Chapters
  section; summarizer still works fine.
- **Cached entry on re-run.** Skill replays cached `pre-summary-context.md` and
  the matching summary with no re-download or LLM call. Use `--refresh` to force
  re-process.
- **Same source, different flags.** Existing artifacts stay in the same work
  dir. Only affected downstream stages rebuild.
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
- **Visual-heavy content (slides, code, dense UI).** Use `--with-frames`.
  Haiku vision is weaker than opus on fine text. Working dir stays on disk;
  rerun an opus subagent on the same artifacts for higher fidelity.

## Replacing Claude

Pipeline is provider-agnostic. The only Claude-specific seam is the body of
`bin/summarize.sh`. To swap:

- Other agent CLI (Codex, Gemini, OpenCode) - edit `bin/summarize.sh` to invoke
  that CLI instead of `claude -p`. Pass it the prompt template as context
  (system prompt, file ref, or inline) and the report on stdin. The other bin/
  scripts and report shape do not change.
- Direct API or local model (LM Studio etc.) - same edit. Replace the `claude`
  invocation with curl + the chosen API. If `--with-frames` is used,
  base64-encode the frames yourself and parse the response.

`video-summary-prompt.md` works as-is across providers; it has no
Claude-specific syntax beyond the `Read` tool reference, which any multimodal
client can map to its own image-loading mechanism.

## Cost and latency

- Pipeline default: metadata + captions only when captions exist. If captions
  are missing or unusable, audio-only download + transcription.
- Pipeline with `--with-frames`: full video download + frame extraction. Codec
  preference (av01 > vp9 > avc1) cuts download size 2-3x vs earlier any-codec
  selection.
- Summarize subprocess (haiku): ~25-40s for a 5-min video. With frames, token
  usage is dominated by images. At default 480p (854x480, JPEG q4, ~550
  tokens/frame) expect ~30-40k tokens for 50-70 frames, around $0.03-0.10 per
  call.
- Two-layer cache:
  - Pipeline cache (watch.sh): replay `pre-summary-context.md`, instant, $0.
  - Summary cache (run.sh): replay `summaries/summary-<signature>.md`, instant,
    $0. No LLM call when the option signature matches.
  - `--refresh` invalidates pipeline (and implicitly summary).
  - `--refresh-summary` invalidates summary only (re-runs haiku on same
    report; useful after editing the prompt template).
