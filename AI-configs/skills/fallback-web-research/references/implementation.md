# fallback-web-research implementation notes

## Behavior

- `PRIORITY_ORDER = [exa, tavily, brave, langsearch, marginalia]`
- `DEFAULT_PARALLEL = 2`
- Quota-blocked or errored backends auto-promote next in queue until 2 OK or
  queue empty
- `--provider` forces single backend first
- Failed provider override falls through to queue
- URL dedupe strips `utm_*`, `gclid`, `fbclid`, fragments, and trailing `/`
- URL dedupe sorts remaining query params
- URL dedupe does not normalize scheme or host
- Same URL from multiple backends merges `sources`
- Same URL snippets concatenate with `\n\n---\n\n`
- Haiku post-pass filters, ranks, rewrites, and dedupes overlapping prose
- Failed Haiku post-pass returns raw formatted results
- Output blocks use `## Result N: <title>`, URL, provider, and body
- Result blocks are separated by `========`
- Provenance footer starts with `---`

## Backends and quotas

| Backend    | Endpoint                                     | Auth                   | Quotas                                  |
| ---------- | -------------------------------------------- | ---------------------- | --------------------------------------- |
| Exa        | `POST api.exa.ai/search`                     | `x-api-key`            | monthly 1000, RPM 600                   |
| Tavily     | `POST api.tavily.com/search`                 | `api_key` in body      | monthly 500, RPM 100 (advanced=2cr/req) |
| Brave      | `GET api.search.brave.com/res/v1/web/search` | `X-Subscription-Token` | monthly 1000, RPM 60                    |
| LangSearch | `POST api.langsearch.com/v1/web-search`      | `Bearer`               | daily 1000, RPM 60                      |
| Marginalia | `GET api2.marginalia-search.com/search`      | `API-Key`              | RPM 60                                  |

## Ordering rationale

- `exa`: semantic, query-aware summary, highlights, 2000-char text
- `tavily`: general/current web and freshness
- `brave`: independent mainstream English index
- `langsearch`: Bing-derived broad daily pool
- `marginalia`: BM25 and indie/small-web long-tail

## Runtime files

- Auth file: `~/OneDrive/work/mac-pro/dotfiles/web-search-auth.json`
- Auth override: `WEB_SEARCH_AUTH_PATH`
- Auth shape:
  `{langsearch:{apiKey},tavily:{apiKey},exa:{apiKey},brave:{apiKey},marginalia:{apiKey}}`
- Marginalia defaults to `public`
- Usage counter:
  `${XDG_STATE_HOME:-~/.local/state}/fallback-web-research/usage.json`
- Usage shape per backend: `{day, monthKey, today, month}`
- Per-minute window is in-memory only
- Summary prompt: `ai-summary-prompt.md`

## Load-bearing decisions

### `numResults` default 10

Backend quotas are request-based, not result-count-based. 10 costs the same API
request as 3. Canonical answers often appear at rank 4-8.

### Tavily advanced mode

`search_depth: advanced` and `chunks_per_source: 3` returns denser page chunks.
The 2cr/request cost is reflected by the 500/month quota cap.

### Exa max content

Exa requests `summary`, one 3-sentence highlight, and 2000 chars of page text.
The three content axes give Haiku better raw material.

### LangSearch keeps `summary: true`

Snippets are too short for long-form pages. Summary output is noisy but usable
after Haiku cleanup.

### Haiku summary pass

The summary pass reduces token volume, filters off-topic records, and
normalizes provider output. It uses `claude-haiku-4-5`, `--thinking off`,
`--no-tools`, `--no-extensions`, `--no-session`, and `--no-skills`.

`--system-prompt` takes an inline string. Do not pass `@path` to
`--system-prompt`; Pi only expands `@path` for positional message args.

### No pagination

Backends do not provide useful pagination. Re-running the same query returns the
same results. Rephrase the query to explore another angle.

### Provider override falls through

Hard-failing on a quota-exhausted provider is worse than fallback. Footer
reports the bypass.

### Public Marginalia key

The `public` key works without signup. It is often 503 under load.

### Output separators

`========` separates result blocks. `---` starts the footer. Different markers
avoid collisions with markdown headings and horizontal rules in result bodies.

### Provenance footer

Footer reports query, dedupe count, summary state, total duration, and
per-backend status.

## Limitations

- No domain filter
- No time range
- No pagination
- Tavily and Exa monthly quotas can exhaust on heavy days
- Haiku pass adds about 16-30s latency
- Marginalia is weak for natural-language or non-English queries
- Per-minute window resets on process restart
