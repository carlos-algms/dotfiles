import assert from 'node:assert/strict';
import { test } from 'node:test';
import { formatCompletion } from './format.ts';
import type { JobResult } from './jobs.ts';

const base = {
  pid: 42,
  command: 'make test',
  logPath: '/tmp/pi-bg-jobs/x_42.log',
  exitCode: 0,
} satisfies JobResult;

test('reports exit code, log path and tail without the trailing newline', () => {
  const text = formatCompletion(base, 'ok\ndone\n');
  assert.equal(
    text,
    'Job 42 ended (exit 0): make test\nLog: /tmp/pi-bg-jobs/x_42.log\nLast output:\nok\ndone',
  );
});

test('reports a non-zero exit code', () => {
  assert.match(
    formatCompletion({ ...base, exitCode: 2 }, ''),
    /ended \(exit 2\)/,
  );
});

test('reports the error instead of the exit code, with the tail', () => {
  const text = formatCompletion(
    { ...base, exitCode: null, error: 'aborted' },
    'bye',
  );
  assert.equal(
    text,
    'Job 42 ended (aborted): make test\nLog: /tmp/pi-bg-jobs/x_42.log\nLast output:\nbye',
  );
});

test('omits the tail section when output is empty or only whitespace', () => {
  const expected =
    'Job 42 ended (exit 0): make test\nLog: /tmp/pi-bg-jobs/x_42.log';
  assert.equal(formatCompletion(base, ''), expected);
  assert.equal(formatCompletion(base, '  \n'), expected);
});

test('keeps leading whitespace of the tail', () => {
  assert.match(
    formatCompletion(base, '  indented\n'),
    /Last output:\n {2}indented$/,
  );
});
