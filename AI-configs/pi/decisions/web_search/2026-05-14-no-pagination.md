---
date: 2026-05-14
status: accepted
---

# No pagination across backends; rephrase to explore

## Decision

`web_search` does not paginate. Re-running the same query returns the same
results. To explore further: rephrase the query.

## Why

None of the 4 backends support pagination, offset, page, cursor, or
next_token parameters. Verified against current API specs.

| backend    | offset/page/cursor | exclude_urls | exclude_domains |
| ---------- | ------------------ | ------------ | --------------- |
| tavily     | no                 | no           | `exclude_domains` (whole domains only) |
| exa        | no                 | no           | `excludeDomains` (whole domains only, max 1200) |
| langsearch | no                 | no           | no              |
| marginalia | no                 | no           | no              |

Exa explicitly states "contact sales" for results beyond `numResults`.

## Why no client-side workaround

- `excludeDomains` is domain-level. Excluding `stackoverflow.com` drops ALL
  SO results, not just seen ones.
- Tracking `seenUrls` client-side and re-querying still burns full quota on
  the excluded URLs (backend doesn't know to skip them, just doesn't have a
  filter for them).
- Backends return relevance-ranked top-N. "Page 2" is semantically not
  "next 10 relevant results" - it's lower-ranked content, often noise.

## Mitigation

- `DEFAULT_NUM_RESULTS=10` (was 3). More breadth in single call.
- Caller rephrases for different angles (different terms, more specific
  scope, alternative framing).
- Documented in `promptGuidelines`: agents should NOT retry web_search with
  the same query.

## Do NOT retry

- Build a pagination layer in the orchestrator. Backends fundamentally
  don't support it.
- Add a `seenUrls` param to filter results post-hoc. Wastes quota; trivial
  for caller to do client-side if needed.
- Add Perplexity Sonar as a backend hoping for "answer engine" continuity.
  Sonar is paid (no free tier as of 2026), all variants require a credit
  card. Unofficial wrappers (Puter.js, helallao/perplexity-ai) violate ToS.
