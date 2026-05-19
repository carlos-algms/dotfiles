---
date: 2026-05-14
status: accepted
---

# ai-summary: `--thinking off`

## Decision

Use `--thinking off` for the ai-summary Haiku call.

## Test matrix

Same fixture (18 deduped results, searxng query), same prompt, same model
(claude-haiku-4-5). Replay-only, no backend calls.

| thinking | duration | output bytes | results kept | format | ranking | content density |
| -------- | -------- | ------------ | ------------ | ------ | ------- | --------------- |
| medium   | 35.3s    | 5.8KB        | 10           | ok     | ok      | dense           |
| low      | 18.4s    | 5.1KB        | 10           | ok     | ok      | dense           |
| off      | 18.5s    | 4.7KB        | 10           | ok     | ok      | dense           |

Note: `low` and `off` measured within noise of each other; `medium` is ~2x
slower with no quality delta.

## Why off, not low

Identical timings, identical output quality on this task. Cheaper accounting
(no reasoning tokens billed). Format adherence holds from a clear prompt
contract; reasoning chain adds nothing.

## Why not high / xhigh

Not tested. No reason to. Format-following + light filtering is not a
reasoning-heavy task.

## Do NOT retry

- `--thinking medium` for plain post-processing - 2x slower with no quality
  gain.
- Reasoning levels to "fix" format adherence. If output drifts, fix the
  prompt; reasoning is the wrong knob.

## Caveat

Tested with `--thinking off` AFTER prompt-loading bug was fixed
(see 2026-05-14-ai-summary-prompt-loading.md). Earlier "Haiku ignores
prompt" symptoms were the file bug, not a thinking-level issue.
