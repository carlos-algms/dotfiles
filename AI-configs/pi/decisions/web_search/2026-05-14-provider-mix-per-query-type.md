---
date: 2026-05-14
status: accepted
---

# Provider mix: exa+tavily parallel default, query-type tradeoffs

## Decision

`DEFAULT_PARALLEL=2` with `PRIORITY_ORDER=[exa, tavily, langsearch,
marginalia]`. Both top-2 fire on every default call. Haiku post-pass filters.

## Per-provider behaviour by query type

Measured on 4 smoke queries: KeyCastr macOS Tahoe issue, dogs+grapes,
Array.fill identity-map, searxng broken engines.

| query type                       | exa                          | tavily                                  |
| -------------------------------- | ---------------------------- | --------------------------------------- |
| technical / niche (github issue) | pins canonical issue         | SEO bait, off-topic                     |
| general / popular (vet content)  | authoritative (PetMD/AKC)    | strong; complementary canonical refs    |
| stackoverflow-shaped             | nails exact SO thread        | adds MDN reference                      |
| github-issue-tracker query       | finds the issues             | SEO/blog noise; Haiku drops all 10      |

## Why both run by default

- exa-only would miss MDN-style canonical refs on general queries.
- tavily-only would dump SEO bait on niche queries.
- Haiku filters; cost of "both ran" is one extra backend call, not extra
  token cost (Haiku compresses).

## Why exa first (not tavily)

- Exa's content payload (summary + highlights + 2000-char text) is
  multi-axis; tavily advanced returns 3x500-char chunks. Exa text is more
  useful raw material for Haiku.
- Order matters for dedupe `sources` tag insertion order, not for fan-out
  parallelism. Cosmetic but consistent.

## Do NOT retry

- Drop tavily because "it was useless on this query". n=1 is not enough.
  Tavily is useful on general queries; the searxng test was a niche
  outlier.
- Drop langsearch from PRIORITY_ORDER entirely. Keep as fallback (3rd in
  queue) for when exa or tavily fail.
- Reorder by "freshness of last test". Reorder only with multi-query data.

## Outstanding gaps

- Marginalia not measured in this batch. Held last per design (BM25,
  downranks commercial).
- Langsearch never fired in default fan-out at `DEFAULT_PARALLEL=2`. Acts
  purely as fallback now.
