---
name: multi-provider-web-search
description: >
  Multi-provider web search fanout across Exa, Tavily, Brave, LangSearch, and
  Marginalia with parallel dispatch, dedupe, and AI summary. Use ONLY on
  explicit user intent for a named provider (Exa, Tavily, Brave, LangSearch,
  Marginalia), cross-provider fanout, semantic code/paper search, indie
  small-web search, or when native web search returned weak results. Do NOT
  auto-pick on generic search queries; native WebSearch is preferred for those.
---

# multi-provider-web-search

Thin shell to `web-search-ai-summary` CLI on PATH.

## Use gate

- Use only on explicit user intent matching one of:
  - Named provider request: Exa, Tavily, Brave, LangSearch, Marginalia
  - Provider-fit query: code/docs/repos/papers (exa), current web/RAG (tavily),
    independent mainstream (brave), free broad (langsearch), indie/small-web
    long-tail (marginalia)
  - Native WebSearch returned weak/empty results and user asks to try harder
- Do not use on generic "search the web" queries. Prefer native WebSearch,
  web_search.

## Run

```sh
web-search-ai-summary "<query>"
```

Options:

- `--provider exa|tavily|brave|langsearch|marginalia`
- `--num-results N` from 1 to 20, default 10 per backend
- `--timeout-ms N` from 1000 to 300000, default 30000

## Guidance

- Do not repeat the same query to compare backends.
- Search again with better keywords when results are weak.
- Fetch result URLs when summaries are insufficient.
- Use `gh` for GitHub source lookup, not this tool.
- Use `--provider` only for backend debugging or clear provider fit.

## Runtime

- CLI binary symlinked to `~/.local/bin/web-search-ai-summary`. Source of truth:
  `AI-configs/pi/extensions/web_search/run.ts`.
