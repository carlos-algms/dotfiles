# web_search

Pi extension. Fans out to 2 backends in parallel, dedupes by URL, returns
markdown (provider summaries/snippets) + provenance footer.

Also exposes a standalone CLI at `run.ts` (symlinked to
`~/.local/bin/web-search-ai-summary`) so non-pi agents can shell out to the
same logic via the `multi-provider-web-search` skill. Pi loads `index.ts`
in-process; CLI imports the same modules and prints to stdout.

## Behaviour

- `PRIORITY_ORDER = [exa, tavily, brave, langsearch, marginalia]`
  (`registry.ts`).
- `DEFAULT_PARALLEL = 2`. Quota-blocked/errored backends auto-promote next in
  queue until 2 OK or queue empty.
- `provider` param forces single backend; on failure falls through to queue,
  footer reports bypass.
- Dedupe normalises URL: strip `utm_*`/`gclid`/`fbclid`, sort remaining params,
  drop fragment, trim trailing `/`. Scheme/host NOT normalised. Same URL from 2
  backends -> `sources: [exa, tavily]`. Snippets concatenated with `\n\n---\n\n`
  (skip if already a substring of existing).
- No post-processing: results are returned in backend order (exa first), as the
  providers send them. No relevance filter, no rewrite.
- Output: `## Result N: <title>` + `- URL:` + `- provider:` + blank + body.
  Blocks joined by `\n========\n`. Footer prefixed `---`.
- TUI fold: snippet preview per result, footer + expand hint shown.
  `app.tools.expand` (ctrl+o) toggles. LLM always gets unfolded text.
- `renderCall`: `web_search "<query>" (provider: <name>)` when override set.

## Backends and quotas

| Backend    | Endpoint                                     | Auth                   | Code quotas (`usage.ts`)                |
| ---------- | -------------------------------------------- | ---------------------- | --------------------------------------- |
| Exa        | `POST api.exa.ai/search`                     | `x-api-key`            | monthly 1000, RPM 600                   |
| Tavily     | `POST api.tavily.com/search`                 | `api_key` in body      | monthly 500, RPM 100 (advanced=2cr/req) |
| Brave      | `GET api.search.brave.com/res/v1/web/search` | `X-Subscription-Token` | monthly 1000, RPM 60 (Free $5 cap)      |
| LangSearch | `POST api.langsearch.com/v1/web-search`      | `Bearer`               | daily 1000, RPM 60                      |
| Marginalia | `GET api2.marginalia-search.com/search`      | `API-Key`              | RPM 60 (vendor: unmetered shared pool)  |

Ordering rationale:

- exa: semantic, query-aware summary + highlights in one call.
  Best on technical/niche.
- tavily: general/current events, freshness. Loses to exa on niche.
- brave: independent ~30B-page index (not Google/Bing). Mainstream English. Free
  cap pauses at $5/mo (~1000 req). Above langsearch since not Bing-derived;
  diversifies the pool.
- langsearch: Bing-derived, 10/call, big daily pool. Spillover.
- marginalia: BM25, downranks commercial. Force via `provider="marginalia"` for
  indie/long-tail.

## Parameters

| Name         | Type        | Default | Notes                                           |
| ------------ | ----------- | ------- | ----------------------------------------------- |
| `query`      | string      | -       | required                                        |
| `numResults` | int 1-5     | 3       | per backend; total pre-dedupe = N x parallel    |
| `provider`   | enum        | -       | force single backend; bypasses to queue on fail |
| `timeoutMs`  | int 1k-300k | 30000   | backend fetch                                   |

## File layout

- Auth: `~/OneDrive/work/mac-pro/dotfiles/web-search-auth.json`. Override via
  `WEB_SEARCH_AUTH_PATH`. Shape:
  `{langsearch:{apiKey},tavily:{apiKey},exa:{apiKey},brave:{apiKey},marginalia:{apiKey}}`.
  Marginalia defaults to `public`.
- Usage counter: `~/.pi/web-search-usage.json`. Shape per backend:
  `{day, monthKey, today, month}`. Lazy reset on stale day/monthKey. Per-minute
  window in-memory only.

## ADRs (load-bearing why)

### numResults default 3, max 5

Raw provider content goes to the agent with no compression, so context size is
the constraint. 3 per backend = ~6 results per call. Max 5 (~10 per call) is a
hard guard: if results miss, rephrase the query; more results of the same query
do not improve relevance. Constants live in `registry.ts`, shared by
`index.ts` and `run.ts`.

### Tavily `search_depth: advanced` + `chunks_per_source: 2`

Basic returns ~250-char synth blob; advanced returns 2 x 500-char chunks from
relevant sections. 2cr/req halves monthly free to 500. Worth it for content
density; `usage.ts` reflects halved cap. See
`../../decisions/web_search/2026-05-14-provider-mix-per-query-type.md`.

### Exa content: summary + highlights, no text

`contents: { summary:true, highlights:{maxCharacters:800} }`.
Highlights capped at 800 chars (Exa ignores numSentences: ~3-4k chars/result uncapped). Full `text` dropped (was 2000 chars/result) since nothing compresses output
anymore; agent uses `web_fetch` for depth.

### LangSearch: `snippet` only

Tested 2026-10: `summary: true` returns the same text as `snippet` (20/20
results identical, same total chars), so the flag is a no-op and is not sent.
LangSearch returns ~1.3k chars/result and sometimes off-topic results (no
filter anymore). It is 4th in priority, spillover only.

### Haiku summary pass removed

Previously a nested `pi --print` (Haiku 4.5) filtered, ranked and rewrote
results. Removed to cut latency (~16-30s), cost and the nested-pi dependency.
Consequences: raw provider text reaches the main agent (no injection buffer),
no relevance filter, duplicate-URL snippets are concatenated unmerged.

### URL normalisation scope

Strip `utm_*`/`gclid`/`fbclid`, fragment, trailing `/`. Skip scheme/host
normalisation: too aggressive vs cost.

### Dedupe concatenates snippets

Same URL from N backends -> one row, `sources: [exa, tavily, ...]`, snippets
joined with `\n\n---\n\n` (skip if substring of existing). No length/priority
heuristic to pick "best" snippet. Each backend often complements the others
(exa semantic summary, tavily chunk picks, brave description); merging
preserves all angles.

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

Mirrors `web_fetch`. Reports query, dedupe count, total ms,
per-backend status (ok/skipped-quota/skipped-rate/error + count + ms). `details`
object mirrors structurally for pi UI.

## Limitations

- Backends don't paginate; same query -> same results. Rephrase to explore. See
  `../../decisions/web_search/2026-05-14-no-pagination.md`.
- Tavily 500/month + Exa 1000/month -> heavy days exhaust. LangSearch 1000/day
  covers spillover.
- Marginalia English + BM25; bad for natural-language or non-English.
- Per-minute window resets on pi restart.
- No domain filter, no time-range, no pagination.
