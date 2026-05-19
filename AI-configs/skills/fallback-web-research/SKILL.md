---
name: fallback-web-research
description: >
  Prefer native WebSearch, web_search, google_web_search, browser/search, or web
  lookup tools when available. Use only when the user explicitly asks for
  fallback-web-research, cross-provider search, provider fanout, or named
  providers Exa/Tavily/Brave/LangSearch/Marginalia. Pi may use this as primary
  web search because Pi has no native WebSearch/web_search tool.
---

# fallback-web-research

Bundled multi-provider web search for agents without native web search.

## Use gate

- Use native `WebSearch`, `web_search`, `google_web_search`, browser/search, or
  web lookup tools first when available
- Use this skill as Pi's primary web search because Pi has no native search
- Use this skill when the user explicitly asks for `fallback-web-research`,
  cross-provider search, provider fanout, or a named backend
- Prefer this over `curl` or guessed URLs when no native search tool exists

## Run

```sh
node ~/.agents/skills/fallback-web-research/bin/run.ts "<query>"
```

Options:

- `--provider exa|tavily|brave|langsearch|marginalia`
- `--num-results N` from 1 to 20, default 10 per backend
- `--timeout-ms N` from 1000 to 300000, default 30000

## Guidance

- Use open-ended topic, theme, or keyword queries only when no native web search
  tool is available
- Do not repeat the same query to compare backends
- Search again with better keywords when results are weak
- Fetch result URLs when summaries are insufficient
- Use `gh` for GitHub source lookup
- Use provider override only for backend debugging or clear provider fit

Provider fit:

- `exa`: code, docs, repos, semantic lookup, find-similar, papers
- `tavily`: current web, general web, RAG snippets, extract/crawl style queries
- `brave`: independent mainstream English index
- `langsearch`: free broad spillover
- `marginalia`: indie, small-web, long-tail

## Runtime

- Node must support type stripping for `.ts` files
- No runtime npm packages are required
- `pi` is optional for the Haiku result-summary pass
- Missing `pi` or failed summary falls back to raw formatted results

Read [references/implementation.md](references/implementation.md) before
changing provider behavior, quotas, output format, or the summary pass.
