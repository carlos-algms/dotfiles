import type { BashOperations } from '@earendil-works/pi-coding-agent';
import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { homedir, tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { createJobs } from './jobs.ts';
import type { JobResult } from './jobs.ts';

type ExecOptions = Parameters<BashOperations['exec']>[2];
type Script = (command: string, options: ExecOptions) => Promise<{ exitCode: number | null }>;

const NOW = new Date('2026-01-02T03:04:05.678Z');
const LOG_NAME_PREFIX = '2026-01-02T03-04-05.678Z';

function setup(script: Script) {
  const logDir = join(mkdtempSync(join(tmpdir(), 'bg-run-test-')), 'logs');
  const execCalls: { command: string; cwd: string; timeout?: number }[] = [];
  let resolve!: (result: JobResult) => void;
  const exited = new Promise<JobResult>((r) => {
    resolve = r;
  });
  function exec(command: string, cwd: string, options: ExecOptions) {
    execCalls.push({ command, cwd, timeout: options.timeout });
    return script(command, options);
  }
  const jobs = createJobs({ ops: { exec }, logDir, onExit: resolve, now: () => NOW });
  return { jobs, exited, logDir, execCalls };
}

function waitForAbort(signal: AbortSignal | undefined): Promise<never> {
  return new Promise((_resolve, reject) => {
    signal?.addEventListener('abort', () => reject(new Error('aborted')));
  });
}

test('start returns pid and log path, and the log holds output after the pid line', async () => {
  const { jobs, exited } = setup(async (_command, { onData }) => {
    onData(Buffer.from('1234\nhello\n'));
    onData(Buffer.from('world\n'));
    return { exitCode: 0 };
  });

  const started = await jobs.start('make', '/work');
  const result = await exited;

  assert.equal(started.pid, 1234);
  assert.match(started.logPath, new RegExp(`logs/${LOG_NAME_PREFIX}_1234\\.log$`));
  assert.deepEqual(result, { pid: 1234, logPath: started.logPath, command: 'make', exitCode: 0, error: undefined });
  assert.equal(readFileSync(started.logPath, 'utf-8'), 'hello\nworld\n');
});

test('start creates a private log dir and log file', async () => {
  const { jobs, exited, logDir } = setup(async (_command, { onData }) => {
    onData(Buffer.from('7\n'));
    return { exitCode: 0 };
  });

  const { logPath } = await jobs.start('x', '/work');
  await exited;

  assert.equal(statSync(logDir).mode & 0o777, 0o700);
  assert.equal(statSync(logPath).mode & 0o777, 0o600);
});

test('start runs the pid-echo prefixed command with the given cwd and timeout', async () => {
  const { jobs, exited, execCalls } = setup(async (_command, { onData }) => {
    onData(Buffer.from('7\n'));
    return { exitCode: 0 };
  });

  await jobs.start('sleep 1', '/work', 30);
  await exited;

  assert.deepEqual(execCalls, [{ command: 'echo $$; sleep 1', cwd: '/work', timeout: 30 }]);
});

test('start reads a pid line split across chunks', async () => {
  const { jobs, exited } = setup(async (_command, { onData }) => {
    onData(Buffer.from('12'));
    onData(Buffer.from('34\nrest'));
    return { exitCode: 0 };
  });

  const started = await jobs.start('x', '/work');
  await exited;

  assert.equal(started.pid, 1234);
  assert.equal(readFileSync(started.logPath, 'utf-8'), 'rest');
});

test('start rejects and aborts when the first line is not a positive integer pid', async () => {
  for (const firstLine of ['oops', '1.5', '0', '-5']) {
    let signal: AbortSignal | undefined;
    const { jobs } = setup(async (_command, options) => {
      signal = options.signal;
      options.onData(Buffer.from(`${firstLine}\n`));
      return waitForAbort(options.signal);
    });

    await assert.rejects(jobs.start('x', '/work'), /Expected a pid on the first output line/);
    assert.equal(signal?.aborted, true, firstLine);
  }
});

test('start rejects with the exec error when exec fails before reporting a pid', async () => {
  const { jobs } = setup(async () => {
    throw new Error('Working directory does not exist');
  });

  await assert.rejects(jobs.start('x', '/missing'), /Working directory does not exist/);
});

test('start rejects when the command ends without reporting a pid', async () => {
  const { jobs } = setup(async () => ({ exitCode: 0 }));

  await assert.rejects(jobs.start('x', '/work'), /Command ended before reporting its pid/);
});

test('onExit reports the exit code, including non-zero and null', async () => {
  for (const exitCode of [3, null]) {
    const { jobs, exited } = setup(async (_command, { onData }) => {
      onData(Buffer.from('5\n'));
      return { exitCode };
    });

    await jobs.start('x', '/work');
    const result = await exited;

    assert.equal(result.exitCode, exitCode);
    assert.equal(result.error, undefined);
  }
});

test('onExit reports a non-Error rejection as a string', async () => {
  const { jobs, exited } = setup(async (_command, { onData }) => {
    onData(Buffer.from('5\n'));
    throw 'boom';
  });

  await jobs.start('x', '/work');
  const result = await exited;

  assert.equal(result.exitCode, null);
  assert.equal(result.error, 'boom');
});

test('onExit reports the log error instead of the exec error when the log cannot be created', async () => {
  const { jobs, exited, logDir } = setup(async (_command, { onData, signal }) => {
    onData(Buffer.from('99\n'));
    return waitForAbort(signal);
  });
  const existing = join(logDir, `${LOG_NAME_PREFIX}_99.log`);
  mkdirSync(logDir, { recursive: true });
  writeFileSync(existing, 'old');

  await jobs.start('x', '/work');
  const result = await exited;

  assert.match(result.error ?? '', /EEXIST/);
  assert.equal(readFileSync(existing, 'utf-8'), 'old');
});

test('kill aborts a running job and reports it', async () => {
  const { jobs, exited } = setup(async (_command, { onData, signal }) => {
    onData(Buffer.from('99\n'));
    return waitForAbort(signal);
  });

  const { pid } = await jobs.start('sleep 100', '/work');

  assert.equal(jobs.kill(pid), true);
  const result = await exited;
  assert.equal(result.exitCode, null);
  assert.equal(result.error, 'aborted');
  assert.equal(jobs.kill(pid), false);
});

test('kill returns false for an unknown pid', () => {
  const { jobs } = setup(async () => ({ exitCode: 0 }));
  assert.equal(jobs.kill(1), false);
});

test('killAll aborts every running job', async () => {
  const results: JobResult[] = [];
  let pids = ['11\n', '22\n'];
  const logDir = join(mkdtempSync(join(tmpdir(), 'bg-run-test-')), 'logs');
  const jobs = createJobs({
    ops: {
      exec: async (_command, _cwd, { onData, signal }) => {
        onData(Buffer.from(pids[0] ?? ''));
        pids = pids.slice(1);
        return waitForAbort(signal);
      },
    },
    logDir,
    onExit: (result) => results.push(result),
  });

  const first = await jobs.start('a', '/work');
  const second = await jobs.start('b', '/work');
  jobs.killAll();
  await new Promise((resolve) => setTimeout(resolve, 20));

  assert.deepEqual(results.map((r) => r.pid).sort(), [first.pid, second.pid]);
  assert.deepEqual(results.map((r) => r.error), ['aborted', 'aborted']);
  assert.equal(jobs.kill(first.pid), false);
});

test('onExit reports a timeout rejection from exec as the error', async () => {
  const { jobs, exited } = setup(async (_command, { onData }) => {
    onData(Buffer.from('5\n'));
    throw new Error('timeout:5');
  });

  await jobs.start('sleep 100', '/work', 5);
  const result = await exited;

  assert.equal(result.exitCode, null);
  assert.equal(result.error, 'timeout:5');
});

test('output after the job ended is dropped without throwing', async () => {
  let late!: (data: Buffer) => void;
  const { jobs, exited } = setup(async (_command, { onData }) => {
    late = onData;
    onData(Buffer.from('5\nbefore\n'));
    return { exitCode: 0 };
  });

  const { logPath } = await jobs.start('x', '/work');
  await exited;
  late(Buffer.from('after\n'));
  await new Promise((resolve) => setTimeout(resolve, 20));

  assert.equal(readFileSync(logPath, 'utf-8'), 'before\n');
});

async function loadRealOps(): Promise<BashOperations> {
  const installDir = join(homedir(), '.pi/agent/install');
  const version = readFileSync(join(installDir, 'current-version'), 'utf-8').trim();
  const entry = join(installDir, 'releases', version, 'node_modules/@earendil-works/pi-coding-agent/dist/index.js');
  const pi = (await import(entry)) as typeof import('@earendil-works/pi-coding-agent');
  return pi.createLocalBashOperations();
}

function isAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

async function setupReal() {
  const ops = await loadRealOps().catch(() => undefined);
  if (!ops) {
    return undefined;
  }
  let resolve!: (result: JobResult) => void;
  const exited = new Promise<JobResult>((r) => {
    resolve = r;
  });
  const logDir = join(mkdtempSync(join(tmpdir(), 'bg-run-test-')), 'logs');
  return { jobs: createJobs({ ops, logDir, onExit: resolve }), exited };
}

// `sleep 3` ends the job on its own if kill fails; the assertions then see exit 0, not "aborted".
test('kill stops a real hanging process through the installed Pi', async (t) => {
  const real = await setupReal();
  if (!real) {
    t.skip('installed Pi not found');
    return;
  }
  const { jobs, exited } = real;

  const { pid } = await jobs.start('sleep 3', process.cwd());
  assert.equal(isAlive(pid), true);
  assert.equal(jobs.kill(pid), true);
  const result = await exited;

  assert.equal(result.exitCode, null);
  assert.equal(result.error, 'aborted');
  assert.equal(isAlive(pid), false);
});

test('timeout stops a real process through the installed Pi and reports timeout:<n>', async (t) => {
  const real = await setupReal();
  if (!real) {
    t.skip('installed Pi not found');
    return;
  }
  const { jobs, exited } = real;

  const { pid } = await jobs.start('sleep 5', process.cwd(), 1);
  const result = await exited;

  assert.equal(result.exitCode, null);
  assert.equal(result.error, 'timeout:1');
  assert.equal(isAlive(pid), false);
});

test('start rejects an invalid timeout through the installed Pi', async (t) => {
  const real = await setupReal();
  if (!real) {
    t.skip('installed Pi not found');
    return;
  }

  await assert.rejects(real.jobs.start('sleep 1', process.cwd(), -1), /Invalid timeout/);
});
