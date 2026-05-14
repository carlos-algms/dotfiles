# web_fetch

Pi extension. Registers a `web_fetch` tool the LLM can call to retrieve URL
contents in an LLM-friendly form.

## What it does

- GET request via Node `fetch` with browser-like headers.
- Negotiates `Accept: text/markdown` so Cloudflare-Markdown-for-Agents sites
  return markdown directly.
- Branches on response `Content-Type`:
  - `text/markdown` / `text/x-markdown` -> returned as-is.
  - `application/json` / any `+json` suffix -> pretty-printed, fenced.
  - `text/html` / `application/xhtml+xml` -> piped through
    `defuddle parse /dev/stdin --md` for clean markdown.
  - other `text/*` -> raw body.
  - binary / unsupported -> saved to a temp file, returns the absolute path.
- Throws on non-2xx, on schemes other than `http`/`https`, on responses larger
  than 10MB, on TLS failures, and on missing `defuddle`.
- Reports `finalUrl` in both `details` and (when it differs from the input) as a
  trailing line in the returned text, so the agent learns about redirects.
- Appends a provenance footer (`source`, `url`, optional `final-url`,
  `duration`, `size`) only to the `cloudflare-md` and `defuddle` branches. JSON
  / text / binary / empty omit the footer to keep the payload clean.
- Enriched error messages on failure: thrown `Error.message` is multi-line and
  includes `url`, `phase` (`fetch` / `http` / `read` / `defuddle`), `elapsed`,
  configured `timeout`, and structured `cause` walked from `err.cause`
  (`code`, `syscall`, `host`, `addr`, `attempts` for AggregateError).
  Distinguishes timeout from host-cancel via `signal.aborted` checks.
- HTTP non-2xx adds a body excerpt (up to 8 KB read, 400 chars displayed) and
  a `final-url` line when redirected before the error. Body read is gated on
  textual content-type; binary responses skip the excerpt.
- TUI rendering folds long output by default. Collapsed view shows the first
  22 body lines, a `... (N more lines, M total)` truncation note, the full
  provenance footer, and a separate `ctrl+o to expand` key hint at the bottom.
  `app.tools.expand` (ctrl+o) toggles to the full view. The LLM always
  receives the unfolded content.
- `renderCall` displays `web_fetch <url>` while the request is in flight.

## Installation

`defuddle` must be on `PATH`:

```bash
npm install -g defuddle
```

Symlink the directory into pi's extensions folder:

```bash
ln -s $(pwd)/AI-configs/pi/extensions/web_fetch ~/.pi/agent/extensions/web_fetch
```

Restart pi or run `/reload`.

## Parameters

| Name        | Type           | Default | Notes                    |
| ----------- | -------------- | ------- | ------------------------ |
| `url`       | string         | -       | http or https only.      |
| `timeoutMs` | integer (opt.) | 30000   | 1000 <= value <= 300000. |

## ADRs

### Node `fetch` over `curl` subprocess

Native global on Node 18+ (undici). No spawn cost. `AbortSignal` from pi wires
in directly. Browser headers and TLS handled in-process.

Tradeoff: undici's TLS fingerprint (JA3) is not Chrome's. Sites with TLS
fingerprinting (Cloudflare Bot Fight on max, Akamai, PerimeterX) still 403
regardless of UA. Headless browser would be required, out of scope.

### Chrome User-Agent + browser-like headers

Defeats UA-string blocklists, which is the most common 403 cause. Includes
`Accept`, `Accept-Language`, `Accept-Encoding`, `Upgrade-Insecure-Requests`,
`Sec-Fetch-*`. Static UA string (latest Chrome stable on macOS) -- rotation not
worth the complexity for personal use.

### `Accept: text/markdown` first

Cloudflare's Markdown-for-Agents (opt-in by site owner) returns markdown
directly when this header is present. Cheapest win: skip HTML parsing entirely.
Listed first with highest q-value, then JSON, then HTML/text.

### `defuddle` via `/dev/stdin`, not the Node API

`defuddle parse /dev/stdin --md` accepts piped HTML and emits markdown. Keeps
the extension dependency-free (no `defuddle` + `linkedom` install in
`node_modules`). Trade-off: `/dev/stdin` is Unix-only -- fine for the macOS +
Linux dev hosts pi runs on; would need a temp file on Windows.

### JSON pretty-print, fenced

Single-line JSON kills readability and diff. `JSON.stringify(parsed, null, 2)`
inside a ` ```json ` fence helps the LLM and any future logs. On parse error
(malformed JSON behind a JSON content-type), the raw body is returned with
`source: "json-raw"` so the LLM still sees the payload.

### `application/json` + `+json` suffix

RFC 6839 -- structured suffixes such as `application/ld+json`,
`application/vnd.api+json` are JSON-shaped. Three-line regex, no downside.

### `text/markdown` + `text/x-markdown`

Cloudflare's spec uses `text/markdown`. Older PHP / shared-hosting setups
sometimes still serve `text/x-markdown`. Cheap to support both up front and
avoid revisiting.

### Binary content -> tmp file, not error

A binary `Content-Type` (PDF, image, archive) means the URL pointed at a file
the LLM may still want to read with a different tool. Saving to a
`mkdtemp(pi-webfetch-*)` path and returning that path lets the agent decide what
to do next (e.g. `read`, `bash pdftotext`).

### 10MB response cap

`fetch` returns a `ReadableStream`. We check `Content-Length` up-front and also
count bytes mid-stream, aborting if either crosses 10MB. Without the cap a
misclicked download URL (ISO, tarball) could pull GB into Node memory and crash
pi. 10MB is huge for any text response; binary downloads above that threshold
should be done with `bash curl -O`.

### Strict TLS, no `insecure` flag

Security default. Bad certs almost always mean MITM or misconfig. Real-world
self-signed needs (corp intranet, local dev) are rare and can fall back to
`bash curl -k`.

### GET only

Matches the tool name (`web_fetch`, not `http_request`). Keeps the parameter
surface small. POST / custom headers / cookies belong in a separate tool if the
need ever appears.

### Cap response size at fetch time, not LLM-input truncation

Pi's `truncateHead` / `truncateTail` exist precisely for this. We are not using
them here -- a normal markdown article (a few KB to tens of KB) is fine to dump
directly. If a fetched page produces hundreds of KB of markdown and hurts
context, revisit and add LLM-side truncation with a spill file.

### `typebox` over hand-written JSON Schema

`typebox` is bundled with pi (per the official Available Imports list). Gives
typed parameters and pi-recognized schema for free. No install.

## Limitations

- TLS fingerprinting (JA3-based bot protection) still 403s -- headless browser
  required for those.
- `/dev/stdin` path assumes Unix.
- Requires global `defuddle` on `PATH`.
- 10MB cap is hard, no override.
- GET only.
- No cookies, no auth, no custom request headers.
