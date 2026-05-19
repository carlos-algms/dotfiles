---
date: 2026-05-14
status: accepted
---

# LangSearch: keep `summary: true` despite tokenization noise

## Decision

Backend keeps `summary: true` in request body. Haiku downstream cleans the
noise.

## Measurement

Same query (KeyCastr macOS Tahoe), 3 results each:

| field         | bytes total | per-result range  | content type                       |
| ------------- | ----------- | ----------------- | ---------------------------------- |
| snippet only  | 1932        | 203 each (fixed)  | brief excerpt                      |
| summary=true  | 21251       | 482-9426          | full extracted page body           |

11x payload increase. Per-result snippet is always 203 chars; summary
varies wildly by source length.

## Quality

- Snippets: too short to answer agent queries. Often just "folders and
  files... 328 commits..." style preamble for GitHub README pages.
- Summaries: full body present BUT broken tokenization throughout
  (`( 26 . x )`, `# 870`, `f - try cua`, `keycaster` -> `gter`). Spaces
  inserted around punctuation, parens, numbers, hash, hyphens.

## Why keep summary

- Where snippet is useless (3rd-party landing pages, GitHub README chrome),
  summary has the actual content even with tokenization noise.
- Haiku tolerates the noise and strips it during the post-pass.
- Without summary, the only fallback is web_fetch round-trips per result.

## Do NOT retry

- Drop summary to "save tokens". Net effect: snippet alone leaves Haiku with
  nothing to work from on long-form pages.
- Sanitize tokenization with regex in `langsearch.ts`. Noise is upstream
  (LangSearch's defuddler); regex would over-strip valid content. Haiku
  handles it.
- Replace LangSearch with another backend solely to escape the tokenization
  issue. LangSearch is the workhorse for daily quota (1000/day) and other
  free alternatives have worse or no tokenization either.

## Future

When Haiku pass becomes consistent, can experiment with `summary: false` +
opportunistic web_fetch on the top 1-2 results. Out of scope today.
