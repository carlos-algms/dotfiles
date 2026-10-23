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
function fakeCtx(provider = 'nous') {
  const statuses: (string | undefined)[] = [];
  const ctx = {
    hasUI: true,
    model: { provider },
    ui: {
      theme: {
        fg: (color: string, text: string) => `<${color}>${text}</${color}>`,
      },
      setStatus(_key: string, text: string | undefined) {
        statuses.push(text);
      },
    },
  } as unknown as ExtensionContext;
  return { ctx, statuses };
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

test('nous format drops buckets whose relative reset has elapsed', () => {
  const twoMinutesAgo = Date.now() - 120_000;
  const text = nous.format(ctx, snap(NOUS_HEADERS, twoMinutesAgo));
  assert.doesNotMatch(text ?? '', /RPM|TPM/);
  assert.match(text ?? '', /RPH/);
  const yesterday = Date.now() - 86_400_000;
  assert.equal(nous.format(ctx, snap(NOUS_HEADERS, yesterday)), undefined);
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

test('poll tick re-renders so expired buckets leave the footer', () => {
  withHome(() => {
    mock.timers.enable({ apis: ['setInterval', 'Date'], now: Date.now() });
    const { ctx: uiCtx, statuses } = fakeCtx('nous');
    const handlers = installExtension();
    try {
      writeSnapshot('nous', NOUS_HEADERS);
      handlers.get('session_start')?.({}, uiCtx);
      assert.match(statuses.at(-1) ?? '', /RPM/);
      mock.timers.tick(120_000);
      assert.doesNotMatch(statuses.at(-1) ?? '', /RPM/);
      assert.match(statuses.at(-1) ?? '', /RPH/);
    } finally {
      handlers.get('session_shutdown')?.({}, uiCtx);
      mock.timers.reset();
    }
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

test('response hook keeps the footer when headers are absent or provider unknown', () => {
  withHome(() => {
    const nousCtx = fakeCtx('nous');
    const handler = installExtension().get('after_provider_response');
    handler?.(
      { status: 502, headers: { 'content-type': 'text/html' } },
      nousCtx.ctx,
    );
    handler?.({ status: 200, headers: NOUS_HEADERS }, fakeCtx('openai').ctx);
    assert.deepEqual(nousCtx.statuses, []);
    assert.equal(readSnapshot('nous'), undefined);
  });
});
