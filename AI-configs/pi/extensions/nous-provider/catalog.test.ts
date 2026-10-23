import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  fetchFreeModels,
  isFree,
  NOUS_BASE_URL,
  parseModelList,
  toModel,
} from './catalog.ts';
import type { RawModel } from './catalog.ts';

const free: RawModel = {
  id: 'meituan/longcat-2.5-preview:free',
  name: 'Meituan: LongCat 2.5 Preview',
  pricing: { prompt: '0', completion: '0' },
  top_provider: { context_length: 1_048_576, max_completion_tokens: 131_072 },
  architecture: { input_modalities: ['text', 'image'] },
  reasoning: null,
};

function bodyOf(models: unknown[]): Response {
  return new Response(JSON.stringify({ data: models }), { status: 200 });
}

test('isFree requires both prices to be zero', () => {
  assert.equal(isFree(free), true);
  assert.equal(
    isFree({ ...free, pricing: { prompt: '0.0000001', completion: '0' } }),
    false,
  );
  assert.equal(
    isFree({ ...free, pricing: { prompt: '0', completion: '0.0000002' } }),
    false,
  );
  assert.equal(
    isFree({ ...free, pricing: { prompt: '0.0000000000', completion: '0.0' } }),
    true,
  );
});

test('isFree rejects missing or unparseable prices', () => {
  assert.equal(isFree({ ...free, pricing: undefined }), false);
  assert.equal(isFree({ ...free, pricing: { prompt: '0' } }), false);
  assert.equal(
    isFree({ ...free, pricing: { prompt: 'n/a', completion: '0' } }),
    false,
  );
});

test('toModel takes limits from top_provider', () => {
  const model = toModel(free, NOUS_BASE_URL);
  assert.equal(model?.contextWindow, 1_048_576);
  assert.equal(model?.maxTokens, 131_072);
});

test('toModel skips a model without a usable output limit', () => {
  assert.equal(
    toModel({ ...free, top_provider: { context_length: 1000 } }, NOUS_BASE_URL),
    undefined,
  );
  assert.equal(
    toModel(
      {
        ...free,
        top_provider: { context_length: 1000, max_completion_tokens: 0 },
      },
      NOUS_BASE_URL,
    ),
    undefined,
  );
});

test('toModel skips a model without a usable context window', () => {
  assert.equal(
    toModel(
      { ...free, top_provider: { max_completion_tokens: 1000 } },
      NOUS_BASE_URL,
    ),
    undefined,
  );
});

test('toModel sets reasoning only when the reasoning field is not null', () => {
  assert.equal(
    toModel({ ...free, reasoning: null }, NOUS_BASE_URL)?.reasoning,
    false,
  );
  assert.equal(
    toModel({ ...free, reasoning: undefined }, NOUS_BASE_URL)?.reasoning,
    false,
  );
  assert.equal(
    toModel({ ...free, reasoning: { mandatory: false } }, NOUS_BASE_URL)
      ?.reasoning,
    true,
  );
});

test('toModel keeps only text and image input', () => {
  const withVideo = {
    ...free,
    architecture: { input_modalities: ['text', 'image', 'video'] },
  };
  assert.deepEqual(toModel(withVideo, NOUS_BASE_URL)?.input, ['text', 'image']);
});

test('toModel falls back to text input', () => {
  assert.deepEqual(
    toModel({ ...free, architecture: undefined }, NOUS_BASE_URL)?.input,
    ['text'],
  );
  const videoOnly = { ...free, architecture: { input_modalities: ['video'] } };
  assert.deepEqual(toModel(videoOnly, NOUS_BASE_URL)?.input, ['text']);
});

test('toModel names the model by id when the name is missing', () => {
  assert.equal(
    toModel({ ...free, name: undefined }, NOUS_BASE_URL)?.name,
    free.id,
  );
});

test('toModel zeroes cost and targets the nous completions endpoint', () => {
  assert.deepEqual(toModel(free, NOUS_BASE_URL), {
    id: free.id,
    name: 'Meituan: LongCat 2.5 Preview',
    api: 'openai-completions',
    provider: 'nous',
    baseUrl: NOUS_BASE_URL,
    input: ['text', 'image'],
    reasoning: false,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 1_048_576,
    maxTokens: 131_072,
  });
});

test('parseModelList returns the data array', () => {
  assert.deepEqual(parseModelList({ data: [free] }), [free]);
});

test('parseModelList rejects a body without a data array', () => {
  assert.throws(() => parseModelList(null), /unexpected/);
  assert.throws(() => parseModelList([]), /unexpected/);
  assert.throws(() => parseModelList({ data: 'x' }), /unexpected/);
});

test('parseModelList drops entries without a string id', () => {
  assert.deepEqual(
    parseModelList({ data: [free, { name: 'no id' }, 7, null] }),
    [free],
  );
});

test('fetchFreeModels returns only free, complete models', async () => {
  const paid = {
    ...free,
    id: 'paid/model',
    pricing: { prompt: '0.000001', completion: '0.000002' },
  };
  const embedding = {
    ...free,
    id: 'embed/model',
    pricing: { prompt: '0', completion: '0.0000001' },
  };
  const noLimit = {
    ...free,
    id: 'free/no-limit:free',
    top_provider: { context_length: 10 },
  };
  const fetchStub = async () => bodyOf([paid, free, embedding, noLimit]);

  const models = await fetchFreeModels({
    fetch: fetchStub,
    signal: new AbortController().signal,
  });

  assert.deepEqual(
    models.map((model) => model.id),
    [free.id],
  );
});

test('fetchFreeModels requests /models without credentials', async () => {
  let seenUrl = '';
  let seenHeaders: Headers | undefined;
  const fetchStub = async (input: RequestInfo | URL, init?: RequestInit) => {
    seenUrl = String(input);
    seenHeaders = new Headers(init?.headers);
    return bodyOf([]);
  };

  await fetchFreeModels({
    fetch: fetchStub,
    signal: new AbortController().signal,
    baseUrl: 'https://example.test/v1/',
  });

  assert.equal(seenUrl, 'https://example.test/v1/models');
  assert.equal(seenHeaders?.has('authorization'), false);
});

test('fetchFreeModels uses the default base url', async () => {
  let seenUrl = '';
  const fetchStub = async (input: RequestInfo | URL) => {
    seenUrl = String(input);
    return bodyOf([]);
  };

  await fetchFreeModels({
    fetch: fetchStub,
    signal: new AbortController().signal,
  });

  assert.equal(seenUrl, `${NOUS_BASE_URL}/models`);
});

test('fetchFreeModels throws on a non-ok response', async () => {
  const fetchStub = async () => new Response('nope', { status: 503 });
  await assert.rejects(
    fetchFreeModels({ fetch: fetchStub, signal: new AbortController().signal }),
    /HTTP 503/,
  );
});

test('fetchFreeModels throws on an unexpected body', async () => {
  const fetchStub = async () =>
    new Response(JSON.stringify({ models: [] }), { status: 200 });
  await assert.rejects(
    fetchFreeModels({ fetch: fetchStub, signal: new AbortController().signal }),
    /unexpected/,
  );
});

test('fetchFreeModels forwards an aborted signal to fetch', async () => {
  const controller = new AbortController();
  controller.abort();
  const fetchStub = async (_input: RequestInfo | URL, init?: RequestInit) => {
    init?.signal?.throwIfAborted();
    return bodyOf([]);
  };
  await assert.rejects(
    fetchFreeModels({ fetch: fetchStub, signal: controller.signal }),
  );
});
