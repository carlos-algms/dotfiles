import assert from 'node:assert/strict';
import { test, type TestContext } from 'node:test';
import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent';
import turnStats from './index.ts';

type Handler = (event: unknown, ctx: unknown) => void;

function install(t: TestContext) {
  t.mock.timers.enable({ apis: ['setInterval', 'Date'], now: 0 });
  const handlers = new Map<string, Handler>();
  turnStats({
    on(name: string, handler: Handler) {
      handlers.set(name, handler);
    },
  } as unknown as ExtensionAPI);
  return (name: string, event: unknown, ctx: unknown) =>
    handlers.get(name)?.(event, ctx);
}

function fakeCtx(mode = 'tui') {
  const working: (string | undefined)[] = [];
  const notices: string[] = [];
  const ctx = {
    mode,
    ui: {
      setWorkingMessage(message?: string) {
        working.push(message);
      },
      notify(message: string) {
        notices.push(message);
      },
    },
  } as unknown as ExtensionContext;
  return { ctx, working, notices };
}

const assistant = (output: number) => ({
  message: { role: 'assistant', usage: { output } },
});
const toolResult = { message: { role: 'toolResult' } };

test('one timer per user turn, tool messages ignored, summary once on settle', (t) => {
  const emit = install(t);
  const { ctx, working, notices } = fakeCtx();

  emit('agent_start', {}, ctx);
  t.mock.timers.tick(1_000);
  emit('message_start', assistant(0), ctx);
  t.mock.timers.tick(1_000);
  emit(
    'message_update',
    { assistantMessageEvent: { type: 'text_delta', delta: 'x'.repeat(400) } },
    ctx,
  );
  t.mock.timers.tick(2_000);
  assert.equal(working.at(-1), 'Working · 4s · 33 tok/s');

  emit('message_end', assistant(300), ctx);
  emit('message_start', toolResult, ctx);
  emit('message_end', toolResult, ctx);
  emit('agent_start', {}, ctx);
  t.mock.timers.tick(1_000);
  assert.equal(working.at(-1), 'Working · 5s');

  emit('agent_settled', { aborted: false }, ctx);
  assert.equal(working.at(-1), undefined);
  assert.deepEqual(notices, ['Turn took 5s · TPS ~100']);

  const updates = working.length;
  t.mock.timers.tick(5_000);
  assert.equal(working.length, updates);
});

test('non-TUI modes are ignored', (t) => {
  const emit = install(t);
  const { ctx, working, notices } = fakeCtx('print');

  emit('agent_start', {}, ctx);
  t.mock.timers.tick(2_000);
  emit('agent_settled', { aborted: false }, ctx);
  assert.deepEqual(working, []);
  assert.deepEqual(notices, []);
});

test('session shutdown stops the timer without a summary', (t) => {
  const emit = install(t);
  const { ctx, working, notices } = fakeCtx();

  emit('agent_start', {}, ctx);
  emit('session_shutdown', {}, ctx);
  const updates = working.length;
  t.mock.timers.tick(5_000);
  emit('agent_settled', { aborted: false }, ctx);
  assert.equal(working.length, updates);
  assert.equal(working.at(-1), undefined);
  assert.deepEqual(notices, []);
});
