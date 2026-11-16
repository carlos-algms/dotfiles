import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createTurnStats, formatDuration } from './stats.ts';

test('formatDuration', () => {
  assert.equal(formatDuration(5_400), '5s');
  assert.equal(formatDuration(65_000), '1m 05s');
  assert.equal(formatDuration(600_000), '10m 00s');
});

test('live and average TPS count the wait for the first token, not the time between requests', () => {
  let clock = 0;
  const stats = createTurnStats(() => clock);
  stats.start();
  assert.equal(stats.workingMessage(), 'Working · 0s');

  clock = 1_000;
  stats.messageStart();
  clock = 2_000;
  stats.delta(400);
  clock = 4_000;
  assert.equal(stats.workingMessage(), 'Working · 4s · 33 tok/s');

  stats.messageEnd(300);
  clock = 64_000;
  assert.equal(stats.workingMessage(), 'Working · 1m 04s');
  assert.equal(stats.summary(), 'Turn took 1m 04s · TPS ~100');
});

test('reasoning before visible text is timed from the request start', () => {
  let clock = 0;
  const stats = createTurnStats(() => clock);
  stats.start();
  stats.messageStart();
  clock = 30_000;
  stats.delta(800);
  clock = 32_000;
  stats.messageEnd(5_200);
  assert.equal(stats.summary(), 'Turn took 32s · TPS ~163');
});

test('no output omits TPS; missing usage falls back to the estimate', () => {
  let clock = 0;
  const stats = createTurnStats(() => clock);
  stats.start();
  assert.equal(stats.summary(), 'Turn took 0s');

  stats.messageStart();
  clock = 1_000;
  stats.delta(400);
  clock = 2_000;
  stats.messageEnd(0);
  assert.equal(stats.summary(), 'Turn took 2s · TPS ~50');
});
