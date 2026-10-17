import assert from 'node:assert/strict';
import { test } from 'node:test';
import type { RunningJob } from './jobs.ts';
import {
  SCROLL_STEP,
  cleanLog,
  createPanelState,
  formatDuration,
} from './panel-state.ts';

function job(pid: number): RunningJob {
  return { pid, logPath: `/log/${pid}`, command: `cmd ${pid}`, startedAt: 0 };
}

function setup(initial: number[]) {
  let jobs = initial.map(job);
  const killed: number[] = [];
  let closed = 0;
  const state = createPanelState({
    list: () => jobs,
    kill: (pid) => {
      killed.push(pid);
      return true;
    },
    close: () => {
      closed += 1;
    },
  });
  return {
    state,
    killed,
    closes: () => closed,
    setJobs: (pids: number[]) => {
      jobs = pids.map(job);
    },
  };
}

test('selects the first job by default', () => {
  const { state } = setup([10, 20]);
  assert.equal(state.view().selected?.pid, 10);
});

test('next and prev move the selection and stop at the ends', () => {
  const { state } = setup([10, 20, 30]);

  state.handle('prev');
  assert.equal(state.view().selected?.pid, 10);
  state.handle('next');
  state.handle('next');
  state.handle('next');
  assert.equal(state.view().selected?.pid, 30);
  state.handle('prev');
  assert.equal(state.view().selected?.pid, 20);
});

test('kill stops the selected job by pid and keeps the panel open', () => {
  const { state, killed, closes } = setup([10, 20]);

  state.handle('next');
  state.handle('kill');

  assert.deepEqual(killed, [20]);
  assert.equal(closes(), 0);
});

test('kill with no job does nothing', () => {
  const { state, killed } = setup([]);
  state.handle('kill');
  assert.deepEqual(killed, []);
});

test('the selection follows its pid when an earlier job ends', () => {
  const { state, setJobs } = setup([10, 20, 30]);
  state.handle('next');
  state.handle('next');

  setJobs([20, 30]);

  assert.equal(state.view().selected?.pid, 30);
});

test('the selection falls back to the first job when the selected job ends', () => {
  const { state, setJobs } = setup([10, 20, 30]);
  state.handle('next');

  setJobs([10, 30]);

  assert.equal(state.view().selected?.pid, 10);
});

test('scrollUp scrolls back by a step, scrollDown returns to the tail and stops there', () => {
  const { state } = setup([10]);

  state.handle('scrollUp');
  state.handle('scrollUp');
  assert.equal(state.view().scrollBack, SCROLL_STEP * 2);
  state.handle('scrollDown');
  assert.equal(state.view().scrollBack, SCROLL_STEP);
  state.handle('scrollDown');
  state.handle('scrollDown');
  assert.equal(state.view().scrollBack, 0);
});

test('clampScroll caps the scroll at the given maximum', () => {
  const { state } = setup([10]);
  state.handle('scrollUp');
  state.handle('scrollUp');

  state.clampScroll(3);

  assert.equal(state.view().scrollBack, 3);
});

test('changing the selected job returns to the tail', () => {
  const { state, setJobs } = setup([10, 20]);

  state.handle('scrollUp');
  state.handle('next');
  assert.equal(state.view().scrollBack, 0);

  state.handle('scrollUp');
  setJobs([10]);
  assert.equal(state.view().scrollBack, 0);
});

test('close calls the close hook', () => {
  const { state, closes } = setup([10]);
  state.handle('close');
  assert.equal(closes(), 1);
});

test('sync closes the panel only when no job is left', () => {
  const { state, setJobs, closes } = setup([10]);

  state.sync();
  assert.equal(closes(), 0);

  setJobs([]);
  state.sync();
  assert.equal(closes(), 1);
});

test('cleanLog strips colors, keeps the last carriage-return redraw and drops control characters', () => {
  const raw =
    '\x1b[32mok\x1b[0m\r\nprogress 10%\rprogress 100%\n\x1b]0;title\x07a\tb\x01\n';
  assert.equal(cleanLog(raw), 'ok\nprogress 100%\na    b\n');
});

test('formatDuration uses seconds, minutes, then hours', () => {
  assert.equal(formatDuration(-5), '0s');
  assert.equal(formatDuration(45_000), '45s');
  assert.equal(formatDuration(180_000), '3m');
  assert.equal(formatDuration(2 * 3_600_000 + 1000), '2h');
});
