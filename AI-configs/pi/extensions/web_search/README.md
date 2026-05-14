# web_search

Pi extension. Fans out to N backends in parallel, dedupes by URL, runs Haiku
post-pass, returns markdown + provenance footer.

## Behaviour

- `PRIORITY_ORDER = [exa, tavily, langsearch, marginalia]` (`registry.ts`).
- `DEFAULT_PARALLEL = 2`. Quota-blocked/errored backends auto-promote next in
  queue until 2 OK or queue empty.
- `provider` param forces single backend; on failure falls through to queue,
  footer reports bypass.
- Dedupe normalises URL: strip `utm_*`/`gclid`/`fbclid`, sort remaining params,
  drop fragment, trim trailing `/`. Scheme/host NOT normalised. Same URL from 2
  backends -> `sources: [exa, tavily]`.
- ai-summary: Haiku 4.5 pass filters, ranks, rewrites bodies. On failure -> raw
  `formatResults`. Footer: `ai-summary: ok | fallback (raw results)`.
- Output: `## Result N: <title>` + `- URL:` + `- provider:` + blank + body.
  Blocks joined by `\n========\n`. Footer prefixed `---`.
- TUI fold: snippet preview per result, footer + expand hint shown.
  `app.tools.expand` (ctrl+o) toggles. LLM always gets unfolded text.
- `renderCall`: `web_search "<query>" (provider: <name>)` when override set.

## Backends and quotas

| Backend    | Endpoint                                | Auth              | Code quotas (`usage.ts`)                |
| ---------- | --------------------------------------- | ----------------- | --------------------------------------- |
| Exa        | `POST api.exa.ai/search`                | `x-api-key`       | monthly 1000, RPM 600                   |
| Tavily     | `POST api.tavily.com/search`            | `api_key` in body | monthly 500, RPM 100 (advanced=2cr/req) |
| LangSearch | `POST api.langsearch.com/v1/web-search` | `Bearer`          | daily 1000, RPM 60                      |
| Marginalia | `GET api2.marginalia-search.com/search` | `API-Key`         | RPM 60 (vendor: unmetered shared pool)  |

Ordering rationale:

- exa: semantic, query-aware summary + highlights + 2000-char text in one call.
  Best on technical/niche.
- tavily: general/current events, freshness. Loses to exa on niche.
- langsearch: Bing-derived, 10/call, big daily pool. Spillover.
- marginalia: BM25, downranks commercial. Force via `provider="marginalia"` for
  indie/long-tail.

## Parameters

| Name         | Type        | Default | Notes                                           |
| ------------ | ----------- | ------- | ----------------------------------------------- |
| `query`      | string      | -       | required                                        |
| `numResults` | int 1-20    | 10      | per backend; total pre-dedupe = N x parallel    |
| `provider`   | enum        | -       | force single backend; bypasses to queue on fail |
| `timeoutMs`  | int 1k-300k | 30000   | backend fetch only; ai-summary has own 60s      |

## File layout

- Auth: `~/OneDrive/work/mac-pro/dotfiles/web-search-auth.json`. Override via
  `WEB_SEARCH_AUTH_PATH`. Shape:
  `{langsearch:{apiKey},tavily:{apiKey},exa:{apiKey},marginalia:{apiKey}}`.
  Marginalia defaults to `public`.
- Usage counter: `~/.pi/web-search-usage.json`. Shape per backend:
  `{day, monthKey, today, month}`. Lazy reset on stale day/monthKey. Per-minute
  window in-memory only.
- ai-summary prompt: `ai-summary-prompt.md` read at module load via
  `readFileSync`, passed inline through `--system-prompt`.

## ADRs (load-bearing why)

### numResults default 10

Backend quotas are request-based, not result-count-based. 10 costs same API
as 3. Canonical answer often at rank 4-8. Token cost paid downstream to cheap
Haiku pass.

### Tavily `search_depth: advanced` + `chunks_per_source: 3`

Basic returns ~250-char synth blob; advanced returns 3 x 500-char chunks from
relevant sections. 2cr/req halves monthly free to 500. Worth it for content
density; `usage.ts` reflects halved cap. See
`../../decisions/web_search/2026-05-14-provider-mix-per-query-type.md`.

### Exa max content

`contents: { summary:true, highlights:{numSentences:3, highlightsPerUrl:1}, text:{maxCharacters:2000} }`.
Multi-axis coverage in one call.

### LangSearch keeps `summary: true`

11x payload vs `snippet`. Body has broken tokenization upstream; Haiku post-pass
strips noise. Snippet alone too short to answer agent queries on long-form
pages. See `../../decisions/web_search/2026-05-14-langsearch-summary-kept.md`.

### ai-summary uses Haiku 4.5, `--thinking off`

- Haiku: ~16s for 10 results, ~$0.01-0.02/call. Sonnet adds latency, no quality
  delta on this task.
- `--thinking off`: tested off/low/medium. off matches low; medium is 2x slower.
  See `../../decisions/web_search/2026-05-14-thinking-level-tested.md`.
- Flags used:
  `--no-tools --no-extensions --no-session --no-skills --provider anthropic --print`.
- Failure modes: blank output, child error, 60s timeout -> raw `formatResults`
  fallback.
- `--system-prompt` takes string only. Prompt loaded with `readFileSync` and
  passed inline. See `../../decisions/web_search/2026-05-14-ai-summary-prompt-loading.md`.
- Requires `pi` on PATH + Anthropic key in pi auth
  (`~/.pi/agent/auth.json -> anthropic.key`). Missing -> fallback.

### URL normalisation scope

Strip `utm_*`/`gclid`/`fbclid`, fragment, trailing `/`. Skip scheme/host
normalisation: too aggressive vs cost.

### Auth in OneDrive JSON

Outside git repo. Syncs across machines without committing. JSON enables future
per-backend options.

### Single counter file + per-minute in-memory

`~/.pi/web-search-usage.json` for day/month (lazy reset). Per-minute lives in
process (60s window resets every minute anyway). Per-backend commit chain
serialises writes to avoid lost-increment race.

### Provider override falls through to queue

Hard-failing on quota-exhausted single backend is worse than fallback. Footer
notes the bypass.

### Marginalia defaults to `public` key

Public sample key works without signup. Often 503 under load. Replace via
`contact@marginalia-search.com` if 503s become routine.

### typebox over hand-written JSON Schema

Bundled with pi. `provider` enum uses `Type.Union(Type.Literal(...))` not
`StringEnum` (no Gemini driver).

### Untrusted response fields

Each adapter validates via `asString`/`asArray`/`asObject` (`http.ts`). Missing
`url` -> drop result, not crash. Vendor shape changes isolated to "fewer
results".

### Output separators: `========` blocks, `---` footer

Different separators avoid collision when bodies contain markdown `---` rules or
`##` headings. TUI splits body on `\n========\n` for fold.

### Provenance footer every call

Mirrors `web_fetch`. Reports query, dedupe count, ai-summary state, total ms,
per-backend status (ok/skipped-quota/skipped-rate/error + count + ms). `details`
object mirrors structurally for pi UI.

## Limitations

- Backends don't paginate; same query -> same results. Rephrase to explore. See
  `../../decisions/web_search/2026-05-14-no-pagination.md`.
- Tavily 500/month + Exa 1000/month -> heavy days exhaust. LangSearch 1000/day
  covers spillover.
- ai-summary adds ~16-30s latency. End-to-end ~25-45s.
- Marginalia English + BM25; bad for natural-language or non-English.
- Per-minute window resets on pi restart.
- No domain filter, no time-range, no pagination.
