import assert from 'node:assert/strict';
import { test } from 'node:test';
import type { Usage } from '@earendil-works/pi-ai';
import type { SessionEntry } from '@earendil-works/pi-coding-agent';
import { createSessionCacheHitRate } from './usage.ts';

function usage(input: number, cacheRead: number, cacheWrite = 0): Usage {
  return {
    input,
    output: 0,
    cacheRead,
    cacheWrite,
    totalTokens: input + cacheRead + cacheWrite,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
  };
}

function fixture(entries: SessionEntry[]) {
  let sessionId = 'session';
  let leafId: string | null = 'leaf';
  let scans = 0;
  return {
    session: {
      getSessionId: () => sessionId,
      getLeafId: () => leafId,
      getEntries: () => {
        scans++;
        return entries;
      },
    },
    setSession: (id: string) => {
      sessionId = id;
    },
    setLeaf: (id: string | null) => {
      leafId = id;
    },
    scans: () => scans,
  };
}

const base = { id: 'entry', parentId: null, timestamp: '2026-01-01T00:00:00Z' };

function usageEntry(value: Usage): SessionEntry {
  return {
    ...base,
    type: 'usage',
    kind: 'cache_warm',
    provider: 'openai',
    model: 'model',
    usage: value,
  };
}

test('weights cache hits by prompt tokens across every supported entry type', () => {
  const entries: SessionEntry[] = [
    {
      ...base,
      type: 'message',
      message: {
        role: 'assistant',
        content: [],
        api: 'openai-responses',
        provider: 'openai',
        model: 'model',
        stopReason: 'stop',
        timestamp: 0,
        usage: usage(90, 10),
      },
    },
    {
      ...base,
      type: 'message',
      message: {
        role: 'assistant',
        content: [],
        api: 'openai-responses',
        provider: 'openai',
        model: 'model',
        stopReason: 'stop',
        timestamp: 0,
        usage: usage(0, 100),
      },
    },
    {
      ...base,
      type: 'compaction',
      summary: '',
      firstKeptEntryId: 'entry',
      tokensBefore: 0,
      usage: usage(0, 0, 20),
    },
    {
      ...base,
      type: 'branch_summary',
      summary: '',
      fromId: 'entry',
      usage: usage(0, 10),
    },
    usageEntry(usage(0, 10)),
    {
      ...base,
      type: 'message',
      message: {
        role: 'toolResult',
        toolCallId: 'call',
        toolName: 'tool',
        content: [],
        isError: false,
        timestamp: 0,
        usage: usage(10, 0),
      },
    },
  ];
  const { session } = fixture(entries);
  assert.equal(createSessionCacheHitRate()(session), 52);
});

test('returns undefined without prompt tokens and ignores entries without usage', () => {
  const { session } = fixture([
    usageEntry(usage(0, 0)),
    {
      ...base,
      type: 'message',
      message: { role: 'user', content: 'hello', timestamp: 0 },
    },
    {
      ...base,
      type: 'compaction',
      summary: '',
      firstKeptEntryId: 'entry',
      tokensBefore: 0,
    },
  ]);
  assert.equal(createSessionCacheHitRate()(session), undefined);
  assert.equal(createSessionCacheHitRate()(fixture([]).session), undefined);
});

test('reuses totals until the leaf or session changes', () => {
  const entries = [usageEntry(usage(100, 100))];
  const data = fixture(entries);
  const rate = createSessionCacheHitRate();
  assert.equal(rate(data.session), 50);
  assert.equal(rate(data.session), 50);
  assert.equal(data.scans(), 1);

  entries.push(usageEntry(usage(0, 200)));
  data.setLeaf('next');
  assert.equal(rate(data.session), 75);
  assert.equal(data.scans(), 2);

  entries.splice(0, entries.length, usageEntry(usage(100, 0)));
  data.setSession('other');
  assert.equal(rate(data.session), 0);
  assert.equal(data.scans(), 3);

  data.setLeaf(null);
  assert.equal(rate(data.session), 0);
  assert.equal(data.scans(), 4);
});
