---
date: 2026-05-14
status: accepted
---

# ai-summary: load prompt with readFileSync, pass inline

## Decision

Read `ai-summary-prompt.md` with `readFileSync` at module load. Pass content
as a string to `pi --system-prompt <content>`.

## Why

Pi's `@/path` expansion is **positional-args only**. Option values like
`--system-prompt "@/path"` are taken as literal strings. The file is never
read.

## How we found out

Symptoms: Haiku ignored every format directive. Output was always a
synthesised QA answer instead of `## Result N` blocks. Persisted across:

- `--append-system-prompt @path` -> ignored
- `--system-prompt @path` -> ignored
- Switch to Sonnet 4.6 -> still ignored

Smoking gun: added `CANARY-XYZZY-7421` to prompt with "include verbatim".
Output had no canary. Same call with inline string `--system-prompt "Reply
with literal canary CANARY-XYZZY-7421"` returned the canary fine.

Conclusion: file never reached the model.

## Do NOT retry

- `--system-prompt "@<path>"` - silently passes the literal `@<path>` string
  as the system prompt. No error.
- `--append-system-prompt "@<path>"` - same failure mode.
- Switching to a bigger model to "fix" format adherence. The model was never
  the problem; the file was never loaded.

## Side findings

- pi's positional message args DO expand `@<path>` - we use that for the
  results payload (`@${payloadPath}`) and it works.
- Module-level `readFileSync` means prompt edits require a pi restart to
  take effect. Acceptable; prompt is stable.
