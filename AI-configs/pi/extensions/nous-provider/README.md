# nous-provider

Pi extension. Registers the provider `nous` (Nous Portal) and fills its model
list with the free models, fetched live from Nous. There is no static model
list.

## How it works

1. Pi calls `fetchModels` on startup in interactive mode, when `/model` opens,
   after `/login`, and in RPC mode
2. `GET https://inference-api.nousresearch.com/v1/models` runs. The endpoint is
   public, so no credential is sent
3. Models with `pricing.prompt == 0` and `pricing.completion == 0` are kept.
   Embedding models (input only) fail the `completion` check
4. Pi stores the result in `~/.pi/agent/models-store.json`. It restores it at
   startup and offline. This extension has no cache of its own

Chat requests use `NOUS_API_KEY` or a key stored by `/login nous`.

## Field mapping

- `contextWindow`: `top_provider.context_length`. The top-level `context_length`
  often differs
- `maxTokens`: `top_provider.max_completion_tokens`
- `reasoning`: `true` when the `reasoning` field is not `null`
- `input`: `architecture.input_modalities` limited to `text` and `image`. Falls
  back to `text`
- `cost`: always zero
- A model without a positive context window or output limit is skipped

## Files

- `catalog.ts` - filter, mapper, and `fetchFreeModels` with an injectable
  `fetch`. No runtime `pi-ai` import, so `node --test` runs it
- `provider.ts` - builds the provider with `createProvider`
- `index.ts` - entry point, calls `pi.registerProvider`
- `catalog.test.ts` - tests for `catalog.ts`

Run the tests:

```bash
node --test AI-configs/pi/extensions/nous-provider/catalog.test.ts
```

## Limits

- `pi update --models` does not refresh this provider. It starts a runtime
  without extensions
- A `nous` block in `~/.pi/agent/models.json` overrides fetched models with the
  same id. Keep only `name`, `baseUrl`, `api`, and `apiKey` there
- Not verified: whether Nous takes `max_tokens` or `max_completion_tokens`. Pi's
  default compat applies

## List the free models from a terminal

```bash
curl -fsS https://inference-api.nousresearch.com/v1/models | jq -r '.data[] | select((.pricing.prompt|tonumber? // 1)==0 and (.pricing.completion|tonumber? // 1)==0) | [.id, .top_provider.context_length] | @tsv' | sort | column -t -s $'\t'
```
