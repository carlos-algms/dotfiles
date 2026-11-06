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
import { nous } from './providers/nous.ts';
import { openaiCodex } from './providers/openai-codex.ts';

/** fg wraps text in tags so nested colouring is detectable. */
function fakeCtx(provider = 'nous', hasUI = true) {
  const statuses: (string | undefined)[] = [];
  const ctx = {
    hasUI,
    get model() {
      return { provider };
    },
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
    provider = nextProvider;
  }
  return { ctx, statuses, selectProvider };
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

test('registry resolves a known provider and rejects unknown ones', () => {
  assert.equal(getRateLimitProvider('anthropic')?.provider, 'anthropic');
  assert.equal(getRateLimitProvider('nous')?.provider, 'nous');
  assert.equal(getRateLimitProvider('openai-codex')?.provider, 'openai-codex');
  assert.equal(getRateLimitProvider('openai'), undefined);
  assert.equal(getRateLimitProvider('constructor'), undefined);
  assert.equal(getRateLimitProvider(undefined), undefined);
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

test('anthropic format renders both windows with a percentage', () => {
  const text = anthropic.format(
    ctx,
    snap({
      'anthropic-ratelimit-unified-5h-utilization': '0.12',
      'anthropic-ratelimit-unified-5h-reset': futureReset(),
      'anthropic-ratelimit-unified-7d-utilization': '0.85',
      'anthropic-ratelimit-unified-7d-reset': futureReset(),
    }),
  );
  assert.match(text ?? '', /5h .*12%/);
  assert.match(text ?? '', /7d .*85%/);
});

test('anthropic format colours each window once, without nesting', () => {
  const text = anthropic.format(
    ctx,
    snap({
      'anthropic-ratelimit-unified-5h-utilization': '0.95',
      'anthropic-ratelimit-unified-5h-reset': futureReset(),
    }),
  );
  assert.match(text ?? '', /^<error>5h .*95%.*<\/error>$/);
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

test('openai-codex pickEvent flattens rate-limit windows by label', () => {
  const reset = Number(futureReset());
  assert.deepEqual(openaiCodex.pickEvent(codexEvent(10080, reset)), {
    '5h-used': '7',
    '5h-reset': String(reset),
    '7d-used': '95',
    '7d-reset': String(reset),
  });
});

test('openai-codex pickEvent skips zero-length windows', () => {
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

test('response hook writes the snapshot and sets the footer', () => {
  withHome(() => {
    const { ctx: uiCtx, statuses } = fakeCtx('nous');
    const upperCased = Object.fromEntries(
      Object.entries(NOUS_HEADERS).map(([key, value]) => [
        key.toUpperCase(),
        value,
      ]),
    );
    installExtension().get('after_provider_response')?.(
      { status: 200, headers: upperCased },
      uiCtx,
    );
    assert.equal(statuses.length, 1);
    assert.match(statuses[0] ?? '', /RPM/);
    assert.ok(readSnapshot('nous'));
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

for (const provider of ['nous', 'deepseek']) {
  test(`session start polls only registered providers: ${provider}`, (t) => {
    t.mock.timers.enable({ apis: ['setInterval'] });
    withHome(() => {
      const { ctx: uiCtx, statuses } = fakeCtx(provider);
      const handlers = installExtension();
      handlers.get('session_start')?.({}, uiCtx);
      assert.equal(statuses.length, 1);
      t.mock.timers.tick(1999);
      assert.equal(statuses.length, 1);
      t.mock.timers.tick(1);
      const expected = provider === 'deepseek' ? 1 : 2;
      assert.equal(statuses.length, expected);
      handlers.get('session_shutdown')?.({}, uiCtx);
      t.mock.timers.tick(6000);
      assert.equal(statuses.length, expected);
    });
  });
}

test('model switches start, reuse, stop, and restart polling for the active provider', (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  withHome(() => {
    const { ctx: uiCtx, statuses, selectProvider } = fakeCtx('deepseek');
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
      'deepseek',
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
      assert.equal(statuses.length, before + (provider === 'deepseek' ? 1 : 4));
      assert.equal(statuses.at(-1), expected);
    }
    handlers.get('session_shutdown')?.({}, uiCtx);
  });
});

test('repeated session start replaces polling and non-limited sessions stop it', (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] });
  withHome(() => {
    const { ctx: uiCtx, statuses, selectProvider } = fakeCtx();
    const handlers = installExtension();
    handlers.get('session_start')?.({}, uiCtx);
    handlers.get('session_start')?.({}, uiCtx);
    t.mock.timers.tick(6000);
    assert.equal(statuses.length, 5);
    selectProvider('deepseek');
    handlers.get('session_start')?.({}, uiCtx);
    t.mock.timers.tick(6000);
    assert.equal(statuses.length, 6);
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

for (const provider of ['deepseek', 'nous']) {
  test(`late Codex stream events preserve the active ${provider} footer`, (t) => {
    t.mock.timers.enable({ apis: ['setInterval'] });
    withHome(() => {
      const { ctx: uiCtx, statuses, selectProvider } = fakeCtx('openai-codex');
      const handlers = installExtension();
      writeSnapshot('nous', NOUS_HEADERS);
      handlers.get('session_start')?.({}, uiCtx);
      selectProvider(provider);
      handlers.get('model_select')?.({ model: { provider } }, uiCtx);
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
}

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
    assert.deepEqual(statuses, []);
    handler?.({ provider: 'openai-codex', data: codexEvent() }, uiCtx);
    assert.equal(statuses.length, 1);
    assert.match(statuses[0] ?? '', /5h .*7d/);
    assert.ok(readSnapshot('openai-codex'));
  });
});

test('response hook preserves existing state for irrelevant headers and unknown providers', () => {
  withHome((home) => {
    const nousCtx = fakeCtx('nous');
    const unknownCtx = fakeCtx('openai');
    const handler = installExtension().get('after_provider_response');
    handler?.({ status: 200, headers: NOUS_HEADERS }, nousCtx.ctx);
    assert.match(nousCtx.statuses.at(-1) ?? '', /RPM/);
    const statuses = [...nousCtx.statuses];
    const snapshot = readSnapshot('nous');
    assert.ok(snapshot);

    handler?.(
      { status: 502, headers: { 'content-type': 'text/html' } },
      nousCtx.ctx,
    );
    assert.deepEqual(nousCtx.statuses, statuses);
    assert.deepEqual(readSnapshot('nous'), snapshot);

    unknownCtx.ctx.ui.setStatus('rate-limits', 'existing footer');
    const file = join(home, '.pi', 'rate-limits.json');
    const stored = readFileSync(file, 'utf8');
    handler?.({ status: 200, headers: NOUS_HEADERS }, unknownCtx.ctx);
    assert.deepEqual(unknownCtx.statuses, ['existing footer']);
    assert.deepEqual(nousCtx.statuses, statuses);
    assert.equal(readFileSync(file, 'utf8'), stored);
    assert.equal(readSnapshot('openai'), undefined);
  });
});
