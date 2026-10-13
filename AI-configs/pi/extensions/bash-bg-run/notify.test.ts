import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import type { JobResult } from './jobs.ts';
import { TAIL_LIMITS, createNotifier, readTail } from './notify.ts';

const identity = (content: string) => content;

function writeLog(content: string): string {
  const logPath = join(mkdtempSync(join(tmpdir(), 'bg-run-test-')), 'job.log');
  writeFileSync(logPath, content);
  return logPath;
}

test('readTail returns a small log whole', async () => {
  assert.equal(await readTail(writeLog('a\nb\n'), identity), 'a\nb\n');
});

test('readTail returns an empty string when the log is missing', async () => {
  assert.equal(await readTail('/nonexistent/job.log', identity), '');
});

test('readTail reads at most maxBytes of a larger log and starts on a whole line', async () => {
  const lines = Array.from({ length: 5000 }, (_, i) => `line-${i}`);
  const tail = await readTail(writeLog(`${lines.join('\n')}\n`), identity);

  assert.ok(Buffer.byteLength(tail) <= TAIL_LIMITS.maxBytes);
  assert.ok(tail.endsWith('line-4999\n'));
  const tailLines = tail.trimEnd().split('\n');
  assert.match(tailLines[0] ?? '', /^line-\d+$/);
  assert.deepEqual(tailLines, lines.slice(lines.length - tailLines.length));
});

test('readTail does not return a character split by the window boundary', async () => {
  const line = `${'é'.repeat(99)}\n`;
  const tail = await readTail(writeLog(line.repeat(300)), identity);

  assert.ok(tail.length > 0);
  assert.equal(tail.replaceAll(line, ''), '');
});

test('readTail returns the window of a larger log that has no newline', async () => {
  const tail = await readTail(writeLog('x'.repeat(TAIL_LIMITS.maxBytes * 3)), identity);
  assert.equal(tail, 'x'.repeat(TAIL_LIMITS.maxBytes));
});

test('readTail passes the window through the injected truncate', async () => {
  assert.equal(await readTail(writeLog('abc'), (content) => content.toUpperCase()), 'ABC');
});

const result = { pid: 42, command: 'make', logPath: '', exitCode: 0 } satisfies JobResult;

test('notify sends the completion message as a follow-up that triggers a turn', async () => {
  const sent: unknown[][] = [];
  const logPath = writeLog('done\n');
  const notify = createNotifier({ send: (...args) => void sent.push(args), truncate: identity });

  await notify({ ...result, logPath });

  assert.deepEqual(sent, [
    [
      {
        customType: 'bg-run',
        content: `Job 42 ended (exit 0): make\nLog: ${logPath}\nLast output:\ndone`,
        display: true,
      },
      { triggerTurn: true, deliverAs: 'followUp' },
    ],
  ]);
});

test('notify still sends the message, without a tail, when the log is missing', async () => {
  const sent: unknown[][] = [];
  const notify = createNotifier({ send: (...args) => void sent.push(args), truncate: identity });

  await notify({ ...result, logPath: '/nonexistent/job.log' });

  assert.equal(sent.length, 1);
  assert.doesNotMatch(String(JSON.stringify(sent[0])), /Last output/);
});

test('notify resolves when send throws, as it does on a stale pi after reload', async () => {
  const notify = createNotifier({
    send: () => {
      throw new Error('This extension instance is stale');
    },
    truncate: identity,
  });

  await assert.doesNotReject(notify({ ...result, logPath: writeLog('x') }));
});
