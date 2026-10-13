import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createToolHandlers } from './tools.ts';

function setup(running: number[] = []) {
  const startCalls: unknown[][] = [];
  const handlers = createToolHandlers({
    start: async (...args) => {
      startCalls.push(args);
      return { pid: 7, logPath: '/tmp/logs/x_7.log' };
    },
    kill: (pid) => running.includes(pid),
  });
  return { handlers, startCalls };
}

test('run starts the job with the command, cwd and timeout, and returns the pid and log path', async () => {
  const { handlers, startCalls } = setup();

  const result = await handlers.run({ command: 'make', timeout: 30 }, '/work');

  assert.deepEqual(startCalls, [['make', '/work', 30]]);
  assert.deepEqual(result, {
    content: [{ type: 'text', text: 'Started job 7. Log: /tmp/logs/x_7.log' }],
    details: { pid: 7, logPath: '/tmp/logs/x_7.log' },
  });
});

test('kill stops a running job', async () => {
  const { handlers } = setup([7]);

  assert.deepEqual(await handlers.kill({ pid: 7 }), {
    content: [{ type: 'text', text: 'Stopping job 7' }],
    details: { pid: 7 },
  });
});

test('kill rejects for an unknown pid and names the manual fallback', async () => {
  const { handlers } = setup();

  await assert.rejects(handlers.kill({ pid: 9 }), {
    message: 'No running job 9. Manual fallback: kill -- -9',
  });
});
