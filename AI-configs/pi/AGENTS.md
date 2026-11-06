# Pi

Pi (`@earendil-works/pi-coding-agent`) configuration. Cross-CLI rules live in
`../AGENTS.md`; this file covers only this directory.

## Files

- `agent/models.json` - provider definitions and `modelOverrides`
- `agent/settings.json` - runtime settings, symlinked as
  `~/.pi/agent/settings.json`
- `agent/mcp.json` - MCP servers, empty on purpose
- `agent/keybindings.json` - key overrides, see `../AGENTS.md` for the `ctrl+p`
  trap
- `extensions/` - loaded `.ts` extensions, whole dir linked
- `extensions-disabled/` - kept around but not loaded
- `tsconfig.json` - maps pi packages to the managed install, bump the version
  after a pi update

## Quirks

- Pi rewrites `agent/settings.json` at runtime (`lastChangelogVersion`,
  `deviceId`), so diffs are expected. If `~/.pi/agent/settings.json` becomes a
  regular file, pi replaced the link: merge its content back here and relink
- A `modelOverrides` entry is inert unless the model id is in `enabledModels`
- `enabledModels` order is the model cycle order
- OpenRouter filters providers by requested output length before applying
  `openRouterRouting.order`. Set `maxTokens` to the lowest output limit among
  the chosen providers; otherwise Pi's inherited catalog limit can exclude
  preferred providers. This budget includes thinking and answer tokens and
  resets after each tool result starts a new model request
- `openRouterRouting.order` takes OpenRouter provider slugs from
  `https://openrouter.ai/api/v1/providers`, not endpoint tags: `baidu`, not
  `baidu/fp8`
- `allow_fallbacks: false` keeps routing deterministic. Drop it and a dead
  provider silently reroutes to whatever is cheapest

## Model roles

- `deepseek/deepseek-flash` - default provider and model, executor. Leads every
  measured execution benchmark: DeepSWE v1.1 77.0, NL2Repo 68.2, ProgramBench
  29.1, TB 4.0 42.3. Thinking `high` for day-to-day work. It has only `low`,
  `high`, `max`: `medium` maps up to `high`, so there is no cheaper middle step,
  and `off` has no measured baseline (72% at `low`, ~77% at default). Move to
  `low` by hand when executing an approved plan, where the reasoning is already
  done
- `z-ai/glm-5.3` - planner and reviewer, thinking `max`. Leads DeepSeek on
  breadth reasoning and knowledge, trails it on every execution benchmark. AA
  puts GLM-5.3 at 31.7 Intelligence Index (max), 41.9% Terminal-Bench 4.0 and
  79.7% AA-LCR; on the same index Haiku 5.5 is 36.5 and GPT-6 Luna 27.9, and
  DeepSeek V4.1 Flash has no AA Intelligence Index row. Z.ai recommends `max`
  for coding: 34.5% on its Code Bench at ~75K output tokens vs 31.4% at ~50K for
  `high`. `medium` is not a GLM-5.3 level; the API takes `low`, `high`, `max`
  only. 45-95 tok/s measured on the routed hosts; Novita and Z.AI are the 45
  tok/s floor
- `deepseek/deepseek-v4-pro` - candidate to replace GLM-5.3 for planning and
  review when Baidu's discount ends or GLM becomes materially more expensive.
  Compare actual costs, including cache reuse and reasoning tokens. Small
  benchmark gains alone do not justify the price spike. Validate review quality
  before relaxing the different-family reviewer rule
- `xiaomi/mimo-v2.6-pro` - long context and maths, not general planning. Loses
  to GLM on reasoning (50.2 vs 54.9) and knowledge (42.9 vs 53.9), wins on long
  context (68.1 vs 64.7), maths (65.9 vs 60.2) and cost. Only non-quantized host
  (bf16) and cache reads at $0.0032/M, but 27 tok/s p50, so a 5k-token plan
  takes ~3 min. Never make it the default. Thinking `xhigh`; async background
  work only
- Reviewer must come from a different family than the author. DeepSeek reviewing
  DeepSeek shares blind spots: use GLM, or MiMo for large-context diffs

## Finding models

`shell/bin/llm-models` lists public ids without auth. By default it keeps only
models priced at zero on both input and output:

```bash
llm-models                  # free models across all providers
llm-models -a openrouter    # every OpenRouter id, priced or not
llm-models -f 'glm-5' nous  # free GLM ids on Nous only
```

Providers: `zen`, `openrouter`, `nous`. Output is `<provider> <id>`.

## Finding pricing

OpenRouter prices per provider for one model:

```bash
curl -fsS "https://openrouter.ai/api/v1/models/z-ai/glm-5.3/endpoints" |
  jq -r '.data.endpoints[] | [.provider_name, .tag, .pricing.prompt,
    .pricing.completion, .pricing.input_cache_read, .pricing.discount,
    .quantization, .uptime_last_1d] | @tsv'
```

Rules

- Prices are per token, multiply by 1e6 for the `$/M` figure
- `pricing.prompt` and `pricing.completion` already include `pricing.discount`.
  `pricing_json` holds the undiscounted list price
- `latency_last_30m` and `throughput_last_30m` are always `null` in the API.
  Real p50 latency and throughput only exist in the stats blocks of the model
  page, keyed by endpoint id:

```bash
curl -fsSL "https://openrouter.ai/z-ai/glm-5.3" -o /tmp/page.html
python3 - <<'EOF'
import json, re
h = open('/tmp/page.html').read().replace('\\"', '"')
d = json.JSONDecoder()
for m in re.finditer(r'\{"endpoint_id":"[0-9a-f-]{36}"', h):
    o, _ = d.raw_decode(h[m.start():])
    print(o['endpoint_id'], o['p50_latency'], o['p50_throughput'],
          o['latency_request_count'])
EOF
```

- `latency_request_count` with `window_minutes: 30` is the sample size. Under
  ~1k requests the p50 is noise
- `fp4` and `nvfp4` endpoints are 4-bit quantized, `fp8` is closer to the
  reference model. Factor that in before trusting a price floor
- The aggregate `pricing` in `/api/v1/models` is a router default, not any real
  endpoint
- `zen` and `go` report `cost` directly in `$/M`. `nous` reports a single
  `pricing` per model id and has no per-provider split

## Promotional routes to revisit

Discounts end silently. Before trusting a cheap provider, check its
`pricing.discount` and its list price in `pricing_json`.

| Model          | Route order                                                                     | Why promo                                                       | When to remove                                                                                                                                                                           |
| -------------- | ------------------------------------------------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `z-ai/glm-5.3` | `baidu`, `tenstorrent/fp8`, `novita/fp8`, `wafer/us`, `wafer`, `decart`, `z-ai` | Baidu is 80% off at $0.28 in / $0.88 out; list is $1.40 / $4.40 | No published end date. Discount is time-of-day tiered (80% weekday 08:00-21:00, 90% weekend, 95% weekday nights, SGT): check before quoting a price, and confirm `discount` is still 0.8 |

To retire a promo: drop the provider from `order` and keep the rest. The
`z-ai/glm-5.3` fallback without Baidu is `tenstorrent/fp8`, `novita/fp8`,
`wafer/us`, `wafer`, `decart`, `z-ai`.
