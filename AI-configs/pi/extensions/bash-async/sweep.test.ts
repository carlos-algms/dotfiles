import assert from 'node:assert/strict';
import { test } from 'node:test';
import { findTargets } from './sweep.ts';
import type { Proc } from './sweep.ts';

const procs: Proc[] = [
  {
    pid: 100,
    ppid: 1,
    command: 'bash -c echo $$; crit PI_ASYNC_JOB=100 HOME=/x',
  },
  { pid: 101, ppid: 100, command: 'crit PI_ASYNC_JOB=100 HOME=/x' },
  {
    pid: 102,
    ppid: 1,
    command: '/opt/homebrew/bin/crit _serve PI_ASYNC_JOB=100 HOME=/x',
  },
  { pid: 103, ppid: 101, command: 'sleep 5 HOME=/x' },
  { pid: 200, ppid: 1, command: 'daemon PI_ASYNC_JOB=1000 HOME=/x' },
  { pid: 201, ppid: 1, command: 'daemon HOME=/x PI_ASYNC_JOB=10' },
  { pid: 300, ppid: 1, command: 'unrelated HOME=/x' },
];

test('tag match finds detached processes and ignores other tags and untagged ones', () => {
  assert.deepEqual(
    findTargets(procs, 100, { walkTree: false }).sort(),
    [100, 101, 102],
  );
});

test('tag match is exact: PI_ASYNC_JOB=10 does not match PI_ASYNC_JOB=100 or 1000', () => {
  assert.deepEqual(findTargets(procs, 10, { walkTree: false }), [201]);
});

test('walkTree adds untagged descendants of the pid', () => {
  assert.deepEqual(
    findTargets(procs, 100, { walkTree: true }).sort(),
    [100, 101, 102, 103],
  );
});

test('without walkTree the pid itself is not targeted unless it carries the tag', () => {
  assert.deepEqual(findTargets(procs, 300, { walkTree: false }), []);
});

test('never targets the caller', () => {
  assert.deepEqual(
    findTargets(procs, 100, { walkTree: true, self: 102 }).sort(),
    [100, 101, 103],
  );
});
