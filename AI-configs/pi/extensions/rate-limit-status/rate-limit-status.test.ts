import assert from 'node:assert/strict';
import {
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { mock, test } from 'node:test';
import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent';
import rateLimitStatus from './index.ts';
import { getRateLimitProvider } from './internal/registry.ts';
import { readSnapshot, writeSnapshot } from './internal/snapshot-store.ts';
import type { HeaderMap, Snapshot } from './internal/types.ts';
import { anthropic } from './providers/anthropic.ts';
import {
  deepseek,
  isPeak,
  OFF_PEAK_RATES,
  PEAK_RATES,
  syncDeepSeekCost,
} from './providers/deepseek.ts';
import { nous } from './providers/nous.ts';
import { openaiCodex } from './providers/openai-codex.ts';

/** Unregistered provider used as the "no rate-limit data" fixture. */
const UNREGISTERED = 'kimi-coding';

/** Friday, off-peak UTC. */
const OFF_PEAK_AT = '2025-01-03T22:49:00Z';

const FLASH_MODEL = {
  provider: 'deepseek',
  id: 'deepseek-flash',
  cost: { input: 0.3, output: 1.2, cacheRead: 0.006 },
};

/** fg wraps text in tags so nested colouring is detectable. */
function fakeCtx(provider = 'nous', hasUI = true, modelId?: string) {
  const statuses: (string | undefined)[] = [];
  const model = { provider, id: modelId, cost: { ...FLASH_MODEL.cost } };
  const ctx = {
    hasUI,
    model,
    ui: {
      theme: {
        fg: (color: string, text: string) => `<${color}>${text}</${color}>`,
      },
      setStatus(key: string, text: string | undefined) {
        assert.equal(key, 'rate-limits');
        statuses.push(text);
      },
    },
  } as unknown as ExtensionContext;
  function selectProvider(nextProvider: string): void {
    model.provider = nextProvider;
  }
  return { ctx, statuses, model, selectProvider };
}

const { ctx } = fakeCtx();

function snap(headers: HeaderMap, at = Date.now()): Snapshot {
  return { at, headers };
}

function futureReset(): string {
  return String(Date.now() / 1000 + 3600);
}
function pastReset(): string {
  return String(Date.now() / 1000 - 3600);
}

/** Point HOME at a throwaway dir so the store never touches the real file. */
function withHome(run: (home: string) => void): void {
  const previous = process.env.HOME;
  const home = mkdtempSync(join(tmpdir(), 'rate-limits-'));
  process.env.HOME = home;
  try {
    run(home);
  } finally {
    process.env.HOME = previous;
    rmSync(home, { recursive: true, force: true });
  }
}

const NOUS_HEADERS = {
  'x-ratelimit-limit-requests': '800',
  'x-ratelimit-remaining-requests': '795',
  'x-ratelimit-reset-requests': '45.5',
  'x-ratelimit-limit-requests-1h': '33600',
  'x-ratelimit-remaining-requests-1h': '33590',
  'x-ratelimit-reset-requests-1h': '3500',
  'x-ratelimit-limit-tokens': '8000000',
  'x-ratelimit-remaining-tokens': '49',
  'x-ratelimit-reset-tokens': '58.2',
  'x-ratelimit-limit-tokens-1h': '336000000',
  'x-ratelimit-remaining-tokens-1h': '335999000',
  'x-ratelimit-reset-tokens-1h': '3500',
};

test('registry resolves providers by id and restricts deepseek to deepseek-flash', () => {
  assert.equal(getRateLimitProvider('anthropic')?.provider, 'anthropic');
  assert.equal(getRateLimitProvider('nous')?.provider, 'nous');
  assert.equal(getRateLimitProvider('openai-codex')?.provider, 'openai-codex');
  assert.equal(getRateLimitProvider(UNREGISTERED), undefined);
  assert.equal(getRateLimitProvider('openai'), undefined);
  assert.equal(getRateLimitProvider('constructor'), undefined);
  assert.equal(getRateLimitProvider(undefined), undefined);
  assert.equal(
    getRateLimitProvider('deepseek', 'deepseek-flash')?.provider,
    'deepseek',
  );
  assert.equal(getRateLimitProvider('deepseek', 'deepseek-v4-pro'), undefined);
  assert.equal(getRateLimitProvider('deepseek'), undefined);
  // Providers without a model list match regardless of id.
  assert.equal(
    getRateLimitProvider('anthropic', 'claude')?.provider,
    'anthropic',
  );
});

test('anthropic pick lowercases and keeps only unified headers', () => {
  assert.deepEqual(
    anthropic.pick({
      'Anthropic-RateLimit-Unified-5h-Utilization': '0.1',
      'anthropic-ratelimit-unified-5h-reset': '123',
      'x-ratelimit-limit-requests': '800',
      authorization: 'Bearer x',
    }),
    {
      'anthropic-ratelimit-unified-5h-utilization': '0.1',
      'anthropic-ratelimit-unified-5h-reset': '123',
    },
  );
});

test('anthropic format renders each live window once, coloured', () => {
  const text = anthropic.format(
    ctx,
    snap({
      'anthropic-ratelimit-unified-5h-utilization': '0.12',
      'anthropic-ratelimit-unified-5h-reset': futureReset(),
      'anthropic-ratelimit-unified-7d-utilization': '0.85',
      'anthropic-ratelimit-unified-7d-reset': futureReset(),
    }),
  );
  assert.match(text ?? '', /^<dim>5h .*12%.*<\/dim>/);
  assert.match(text ?? '', /<warning>7d .*85%.*<\/warning>$/);
  assert.doesNotMatch(text ?? '', /<\w+>[^<]*<\w+>/);
});

test('anthropic format is undefined when no window is live or usable', () => {
  assert.equal(anthropic.format(ctx, snap({})), undefined);
  assert.equal(
    anthropic.format(
      ctx,
      snap({ 'anthropic-ratelimit-unified-5h-utilization': '0.1' }),
    ),
    undefined,
  );
  assert.equal(
    anthropic.format(
      ctx,
      snap({
        'anthropic-ratelimit-unified-5h-utilization': '0.1',
        'anthropic-ratelimit-unified-5h-reset': pastReset(),
      }),
    ),
    undefined,
  );
});

test('nous pick keeps only x-ratelimit headers', () => {
  assert.deepEqual(
    nous.pick({
      'X-RateLimit-Limit-Requests': '800',
      'x-ratelimit-remaining-requests': '795',
      authorization: 'Bearer x',
      'anthropic-ratelimit-unified-5h-reset': futureReset(),
    }),
    {
      'x-ratelimit-limit-requests': '800',
      'x-ratelimit-remaining-requests': '795',
    },
  );
});

test('nous format renders the four windows with used/limit', () => {
  const text = nous.format(ctx, snap(NOUS_HEADERS));
  assert.match(text ?? '', /RPM .*5\/800 \(46s\)/);
  assert.match(text ?? '', /RPH .*10\/33,600/);
  assert.match(text ?? '', /TPM .*7,999,951\/8,000,000/);
  assert.match(text ?? '', /TPH/);
  assert.doesNotMatch(text ?? '', /<\w+>[^<]*<\w+>/);

  const longReset = nous.format(
    ctx,
    snap({ ...NOUS_HEADERS, 'x-ratelimit-reset-requests': '5400' }),
  );
  assert.match(longReset ?? '', /RPM .*\(1h 30m\)/);
});

test('nous format shows expired buckets as 0/limit', () => {
  const twoMinutesAgo = Date.now() - 120_000;
  const text = nous.format(ctx, snap(NOUS_HEADERS, twoMinutesAgo));
  assert.match(text ?? '', /RPM .*0\/800/);
  assert.match(text ?? '', /TPM .*0\/8,000,000/);
  assert.match(text ?? '', /RPH/);

  const yesterday = Date.now() - 86_400_000;
  const expired = nous.format(ctx, snap(NOUS_HEADERS, yesterday));
  assert.match(expired ?? '', /RPM 0\/800<\/dim>/);
  assert.match(expired ?? '', /RPH 0\/33,600<\/dim>/);
  assert.match(expired ?? '', /TPM 0\/8,000,000<\/dim>/);
  assert.match(expired ?? '', /TPH 0\/336,000,000<\/dim>/);
  assert.doesNotMatch(expired ?? '', /[()]/);
});

test('nous format is undefined without any usable window', () => {
  assert.equal(nous.format(ctx, snap({})), undefined);
  assert.equal(
    nous.format(ctx, snap({ 'x-ratelimit-remaining-requests': '795' })),
    undefined,
  );
  assert.equal(
    nous.format(
      ctx,
      snap({
        'x-ratelimit-limit-requests': '0',
        'x-ratelimit-remaining-requests': '0',
        'x-ratelimit-reset-requests': '45',
      }),
    ),
    undefined,
  );
});

/** Shape captured from a real `openai-codex` WebSocket stream. */
function codexEvent(secondaryMinutes = 10080, reset = Number(futureReset())) {
  return {
    type: 'codex.rate_limits',
    plan_type: 'plus',
    rate_limits: {
      allowed: true,
      limit_reached: false,
      primary: {
        used_percent: 7,
        window_minutes: 300,
        reset_after_seconds: 3600,
        reset_at: reset,
      },
      secondary: {
        used_percent: 95,
        window_minutes: secondaryMinutes,
        reset_after_seconds: 3600,
        reset_at: reset,
      },
    },
  };
}

test('openai-codex pickEvent flattens usable windows and drops zero-length ones', () => {
  const reset = Number(futureReset());
  assert.deepEqual(openaiCodex.pickEvent(codexEvent(10080, reset)), {
    '5h-used': '7',
    '5h-reset': String(reset),
    '7d-used': '95',
    '7d-reset': String(reset),
  });
  assert.deepEqual(Object.keys(openaiCodex.pickEvent(codexEvent(0)) ?? {}), [
    '5h-used',
    '5h-reset',
  ]);
});

test('openai-codex pickEvent ignores other or malformed events', () => {
  for (const data of [
    undefined,
    null,
    'x',
    { type: 'response.created' },
    { type: 'codex.rate_limits' },
    { type: 'codex.rate_limits', rate_limits: { primary: { used: 1 } } },
  ]) {
    assert.equal(openaiCodex.pickEvent(data), undefined, JSON.stringify(data));
  }
});

test('openai-codex format renders both windows, each coloured once', () => {
  const text = openaiCodex.format(
    ctx,
    snap(openaiCodex.pickEvent(codexEvent()) ?? {}),
  );
  assert.match(text ?? '', /^<dim>5h .*7% \(.*\)<\/dim>/);
  assert.match(text ?? '', /<error>7d .*95% \(.*\)<\/error>$/);
  assert.doesNotMatch(text ?? '', /<\w+>[^<]*<\w+>/);
});

test('openai-codex format is undefined when every reset has passed', () => {
  const expired = openaiCodex.pickEvent(codexEvent(10080, Number(pastReset())));
  assert.equal(openaiCodex.format(ctx, snap(expired ?? {})), undefined);
  assert.equal(openaiCodex.format(ctx, snap({})), undefined);
});

test('snapshot store keys each provider independently', () => {
  withHome(() => {
    const first = writeSnapshot('anthropic', { a: '1' });
    writeSnapshot('nous', { b: '2' });
    assert.deepEqual(readSnapshot('anthropic'), first);
    assert.deepEqual(readSnapshot('nous')?.headers, { b: '2' });
    assert.equal(readSnapshot('openai'), undefined);
  });
});

test('snapshot store ignores corrupt and legacy-shaped files', () => {
  withHome((home) => {
    mkdirSync(join(home, '.pi'));
    const file = join(home, '.pi', 'rate-limits.json');
    for (const content of ['null', '[]', '"x"', '{', '{"anthropic":"0.5"}']) {
      writeFileSync(file, content);
      assert.equal(readSnapshot('anthropic'), undefined, content);
    }
    writeFileSync(file, '{"legacy-key":"0.5"}');
    writeSnapshot('nous', { b: '2' });
    assert.deepEqual(Object.keys(JSON.parse(readFileSync(file, 'utf8'))), [
      'nous',
    ]);
  });
});

function installExtension() {
  const handlers = new Map<string, (event: unknown, ctx: unknown) => void>();
  rateLimitStatus({
    on(name: string, handler: (event: unknown, ctx: unknown) => void) {
      handlers.set(name, handler);
    },
  } as unknown as ExtensionAPI);
  return handlers;
}

test('response hook writes the snapshot, then ignores irrelevant headers and unknown providers', () => {
  withHome((home) => {
    const { ctx: nousCtx, statuses } = fakeCtx('nous');
    const handler = installExtension().get('after_provider_response');
    const upperCased = Object.fromEntries(
      Object.entries(NOUS_HEADERS).map(([key, value]) => [
        key.toUpperCase(),
        value,
      ]),
    );
    handler?.({ status: 200, headers: upperCased }, nousCtx);
    assert.match(statuses.at(-1) ?? '', /RPM/);
    const snapshot = readSnapshot('nous');
    assert.ok(snapshot);

    const before = [...statuses];
    handler?.(
      { status: 502, headers: { 'content-type': 'text/html' } },
      nousCtx,
    );
    assert.deepEqual(statuses, before);
    assert.deepEqual(readSnapshot('nous'), snapshot);

    const { ctx: unknownCtx, statuses: unknownStatuses } = fakeCtx('openai');
    unknownCtx.ui.setStatus('rate-limits', 'existing footer');
    const file = join(home, '.pi', 'rate-limits.json');
    const stored = readFileSync(file, 'utf8');
    handler?.({ status: 200, headers: NOUS_HEADERS }, unknownCtx);
    assert.deepEqual(unknownStatuses, ['existing footer']);
    assert.deepEqual(statuses, before);
    assert.equal(readFileSync(file, 'utf8'), stored);
    assert.equal(readSnapshot('openai'), undefined);
  });
});

test('poll tick re-renders expired Nous buckets as 0/limit', () => {
  withHome(() => {
    mock.timers.enable({ apis: ['setInterval', 'Date'], now: Date.now() });
    const { ctx: uiCtx, statuses } = fakeCtx('nous');
    const handlers = installExtension();
    try {
      writeSnapshot('nous', NOUS_HEADERS);
      handlers.get('session_start')?.({}, uiCtx);
      assert.match(statuses.at(-1) ?? '', /RPM/);
      mock.timers.tick(120_000);
      assert.match(statuses.at(-1) ?? '', /RPM .*0\/800/);
      assert.match(statuses.at(-1) ?? '', /RPH/);
    } finally {
      handlers.get('session_shutdown')?.({}, uiCtx);
      mock.timers.reset();
    }
  });
});

test('model switches start, reuse, stop, and restart polling for the active provider', (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  withHome(() => {
    const { ctx: uiCtx, statuses, selectProvider } = fakeCtx(UNREGISTERED);
    const handlers = installExtension();
    writeSnapshot('nous', NOUS_HEADERS);
    writeSnapshot('anthropic', {
      'anthropic-ratelimit-unified-5h-utilization': '0.12',
      'anthropic-ratelimit-unified-5h-reset': futureReset(),
    });
    writeSnapshot('openai-codex', openaiCodex.pickEvent(codexEvent()) ?? {});
    handlers.get('session_start')?.({}, uiCtx);
    for (const provider of [
      'nous',
      'nous',
      'anthropic',
      'openai-codex',
      UNREGISTERED,
      'nous',
    ]) {
      selectProvider(provider);
      const before = statuses.length;
      handlers.get('model_select')?.({ model: { provider } }, uiCtx);
      const formatter = getRateLimitProvider(provider);
      const snapshot = readSnapshot(provider);
      if (formatter) {
        assert.ok(snapshot);
      }
      const expected =
        formatter && snapshot ? formatter.format(uiCtx, snapshot) : undefined;
      assert.equal(statuses.length, before + 1);
      assert.equal(statuses.at(-1), expected);
      t.mock.timers.tick(6000);
      assert.equal(
        statuses.length,
        before + (provider === UNREGISTERED ? 1 : 4),
      );
      assert.equal(statuses.at(-1), expected);
    }
    handlers.get('session_shutdown')?.({}, uiCtx);
  });
});

test('repeated session start replaces polling, and shutdown or an unregistered provider stops it', (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  withHome(() => {
    const first = fakeCtx();
    const second = fakeCtx();
    const handlers = installExtension();
    handlers.get('session_start')?.({}, first.ctx);
    handlers.get('session_start')?.({}, second.ctx);
    t.mock.timers.tick(6000);
    assert.equal(first.statuses.length, 1);
    assert.equal(second.statuses.length, 4);

    handlers.get('session_shutdown')?.({}, second.ctx);
    t.mock.timers.tick(6000);
    assert.equal(second.statuses.length, 4);

    second.selectProvider(UNREGISTERED);
    handlers.get('session_start')?.({}, second.ctx);
    t.mock.timers.tick(6000);
    assert.equal(second.statuses.length, 5);
    assert.equal(first.statuses.length, 1);
  });
});

test('headless session start and model selection do not render or poll', (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  withHome(() => {
    const { ctx: headlessCtx, statuses } = fakeCtx('nous', false);
    const handlers = installExtension();
    handlers.get('session_start')?.({}, headlessCtx);
    handlers.get('model_select')?.(
      { model: { provider: 'nous' } },
      headlessCtx,
    );
    t.mock.timers.tick(6000);
    assert.deepEqual(statuses, []);
  });
});

test('late Codex stream events preserve the active nous footer', (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  withHome(() => {
    const { ctx: uiCtx, statuses, selectProvider } = fakeCtx('openai-codex');
    const handlers = installExtension();
    writeSnapshot('nous', NOUS_HEADERS);
    handlers.get('session_start')?.({}, uiCtx);
    selectProvider('nous');
    handlers.get('model_select')?.({ model: { provider: 'nous' } }, uiCtx);
    const before = [...statuses];
    const data = codexEvent();
    handlers.get('provider_stream_event')?.(
      { provider: 'openai-codex', data },
      uiCtx,
    );
    assert.deepEqual(statuses, before);
    assert.deepEqual(
      readSnapshot('openai-codex')?.headers,
      openaiCodex.pickEvent(data),
    );
    t.mock.timers.tick(6000);
    assert.equal(statuses.at(-1), before.at(-1));
    selectProvider('openai-codex');
    handlers.get('model_select')?.(
      { model: { provider: 'openai-codex' } },
      uiCtx,
    );
    assert.match(statuses.at(-1) ?? '', /5h .*7d/);
    handlers.get('session_shutdown')?.({}, uiCtx);
  });
});

test('headless stream events store snapshots without rendering', () => {
  withHome(() => {
    const { ctx: headlessCtx, statuses } = fakeCtx('openai-codex', false);
    const data = codexEvent();
    installExtension().get('provider_stream_event')?.(
      { provider: 'openai-codex', data },
      headlessCtx,
    );
    assert.deepEqual(statuses, []);
    assert.deepEqual(
      readSnapshot('openai-codex')?.headers,
      openaiCodex.pickEvent(data),
    );
  });
});

test('stream hook writes the codex snapshot and sets the footer', () => {
  withHome(() => {
    const { ctx: uiCtx, statuses } = fakeCtx('openai-codex');
    const handler = installExtension().get('provider_stream_event');
    handler?.({ provider: 'openai-codex', data: { type: 'x' } }, uiCtx);
    handler?.({ provider: UNREGISTERED, data: codexEvent() }, uiCtx);
    assert.deepEqual(statuses, []);
    assert.equal(readSnapshot(UNREGISTERED), undefined);
    handler?.({ provider: 'openai-codex', data: codexEvent() }, uiCtx);
    assert.equal(statuses.length, 1);
    assert.match(statuses[0] ?? '', /5h .*7d/);
    assert.ok(readSnapshot('openai-codex'));
  });
});

test('isPeak marks Mon-Fri 01:00-04:00 and 06:00-10:00 UTC', () => {
  const peak = (iso: string) => assert.equal(isPeak(new Date(iso)), true, iso);
  const off = (iso: string) => assert.equal(isPeak(new Date(iso)), false, iso);
  peak('2025-01-03T01:00:00Z'); // Friday, window start
  peak('2025-01-03T03:59:00Z');
  off('2025-01-03T04:00:00Z'); // end exclusive
  peak('2025-01-03T06:00:00Z');
  peak('2025-01-03T09:59:00Z');
  off('2025-01-03T10:00:00Z');
  off(OFF_PEAK_AT); // evening off-peak
  off('2025-01-04T02:00:00Z'); // Saturday
  off('2025-01-05T02:00:00Z'); // Sunday
});

test('syncDeepSeekCost applies the current rate only to deepseek-flash', () => {
  const offPeak = { ...FLASH_MODEL, cost: { ...PEAK_RATES } };
  syncDeepSeekCost(offPeak, new Date(OFF_PEAK_AT));
  assert.deepEqual(offPeak.cost, OFF_PEAK_RATES);

  const peak = { ...FLASH_MODEL, cost: { ...OFF_PEAK_RATES } };
  syncDeepSeekCost(peak, new Date('2025-01-03T02:00:00Z'));
  assert.deepEqual(peak.cost, PEAK_RATES);

  const untouched = [
    { ...FLASH_MODEL, id: 'deepseek-v4-pro', cost: { ...FLASH_MODEL.cost } },
    {
      ...FLASH_MODEL,
      provider: 'openrouter',
      id: 'deepseek/deepseek-v4.1-flash-1017',
      cost: { ...FLASH_MODEL.cost },
    },
    { ...FLASH_MODEL, provider: 'openrouter', cost: { ...FLASH_MODEL.cost } },
  ];
  for (const model of untouched) {
    syncDeepSeekCost(model);
    assert.deepEqual(model.cost, FLASH_MODEL.cost, model.id);
  }

  syncDeepSeekCost(undefined);
});

test('deepseek renders a time line and no header line', (t) => {
  t.mock.timers.enable({ apis: ['Date'], now: Date.parse(OFF_PEAK_AT) });
  assert.equal(deepseek.formatTime?.(ctx), '<dim>deepseek off-peak −50%</dim>');
  t.mock.timers.setTime(Date.parse('2025-01-03T06:00:00Z'));
  assert.equal(deepseek.formatTime?.(ctx), '<warning>deepseek peak</warning>');
  assert.equal(deepseek.format(ctx, snap(NOUS_HEADERS)), undefined);
});

test('deepseek-flash polls and shows the time-based line', (t) => {
  t.mock.timers.enable({
    apis: ['setInterval', 'Date'],
    now: Date.parse(OFF_PEAK_AT),
  });
  withHome(() => {
    const { ctx: uiCtx, statuses } = fakeCtx(
      'deepseek',
      true,
      'deepseek-flash',
    );
    const handlers = installExtension();
    handlers.get('session_start')?.({}, uiCtx);
    assert.match(statuses.at(-1) ?? '', /deepseek off-peak/);
    t.mock.timers.tick(6000);
    assert.equal(statuses.length, 4);

    handlers.get('model_select')?.(
      { model: { provider: 'deepseek', id: 'deepseek-v4-pro' } },
      uiCtx,
    );
    assert.equal(statuses.at(-1), undefined);
    t.mock.timers.tick(6000);
    assert.equal(statuses.length, 5); // polling stopped for the unmatched model

    handlers.get('session_shutdown')?.({}, uiCtx);
    t.mock.timers.tick(6000);
    assert.equal(statuses.length, 5);
  });
});

test('model_select syncs deepseek-flash cost', (t) => {
  t.mock.timers.enable({ apis: ['Date'], now: Date.parse(OFF_PEAK_AT) });
  withHome(() => {
    const { ctx: uiCtx, model } = fakeCtx('deepseek', true, 'deepseek-flash');
    installExtension().get('model_select')?.({ model }, uiCtx);
    assert.deepEqual(model.cost, OFF_PEAK_RATES);
  });
});

test('headless hooks still sync deepseek-flash cost', (t) => {
  t.mock.timers.enable({ apis: ['Date'], now: Date.parse(OFF_PEAK_AT) });
  const handlers = installExtension();
  for (const hook of ['session_start', 'before_provider_request']) {
    const {
      ctx: headlessCtx,
      model,
      statuses,
    } = fakeCtx('deepseek', false, 'deepseek-flash');
    handlers.get(hook)?.({}, headlessCtx);
    assert.deepEqual(model.cost, OFF_PEAK_RATES, hook);
    assert.deepEqual(statuses, [], hook);
  }
});
