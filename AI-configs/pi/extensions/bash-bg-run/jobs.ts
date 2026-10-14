import { createWriteStream } from 'node:fs';
import type { WriteStream } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import type { BashOperations } from '@earendil-works/pi-coding-agent';
import { JOB_TAG, sweep as defaultSweep } from './sweep.ts';
import type { SweepOptions } from './sweep.ts';

export interface StartedJob {
  pid: number;
  logPath: string;
}

export interface JobResult extends StartedJob {
  command: string;
  exitCode: number | null;
  error?: string;
}

interface JobsOptions {
  ops: BashOperations;
  logDir: string;
  onExit: (result: JobResult) => void;
  now?: () => Date;
  sweep?: (pid: number, options: SweepOptions) => void;
}

const NEWLINE = 0x0a;

export type Jobs = ReturnType<typeof createJobs>;

/**
 * Runs commands through Pi's own bash operations. The command is prefixed with
 * `echo $$;` because `exec()` does not expose the child pid. Pi spawns detached,
 * so that pid is also the process group id (`kill -- -<pid>` stops the tree).
 * It also exports the pid as `PI_BG_JOB`, so `sweep` can find processes that
 * left the group with `setsid`.
 */
export function createJobs(options: JobsOptions) {
  const {
    ops,
    logDir,
    onExit,
    now = () => new Date(),
    sweep = defaultSweep,
  } = options;
  const running = new Map<number, AbortController>();

  async function start(
    command: string,
    cwd: string,
    timeout?: number,
  ): Promise<StartedJob> {
    await mkdir(logDir, { recursive: true, mode: 0o700 });
    const controller = new AbortController();

    return new Promise((resolve, reject) => {
      let head = Buffer.alloc(0);
      let job: (StartedJob & { log: WriteStream }) | undefined;
      let logError: string | undefined;

      function onData(data: Buffer) {
        if (job) {
          job.log.write(data);
          return;
        }
        head = Buffer.concat([head, data]);
        const end = head.indexOf(NEWLINE);
        if (end === -1) {
          return;
        }
        const firstLine = head.subarray(0, end).toString().trim();
        const pid = Number(firstLine);
        if (!Number.isInteger(pid) || pid <= 0) {
          controller.abort();
          reject(
            new Error(
              `Expected a pid on the first output line, got "${firstLine}"`,
            ),
          );
          return;
        }
        const stamp = now().toISOString().replace(/:/g, '-');
        const logPath = join(logDir, `${stamp}_${pid}.log`);
        const log = createWriteStream(logPath, { flags: 'wx', mode: 0o600 });
        log.on('error', (error) => {
          logError = error.message;
          controller.abort();
        });
        job = { pid, logPath, log };
        running.set(pid, controller);
        log.write(head.subarray(end + 1));
        resolve({ pid, logPath });
      }

      function finish(exitCode: number | null, error?: string) {
        if (!job) {
          reject(new Error(error ?? 'Command ended before reporting its pid'));
          return;
        }
        const { pid, logPath, log } = job;
        running.delete(pid);
        sweep(pid, { walkTree: false });
        const report = () =>
          onExit({ pid, logPath, command, exitCode, error: logError ?? error });
        if (log.destroyed) {
          report();
          return;
        }
        log.end(report);
      }

      ops
        .exec(`export ${JOB_TAG}=$$; echo $$; ${command}`, cwd, {
          onData,
          signal: controller.signal,
          timeout,
        })
        .then(
          ({ exitCode }) => finish(exitCode),
          (error: unknown) =>
            finish(
              null,
              error instanceof Error ? error.message : String(error),
            ),
        );
    });
  }

  function kill(pid: number): boolean {
    const controller = running.get(pid);
    if (!controller) {
      return false;
    }
    // Sweep first: once the group is dead, detached children lose the parent link the tree walk needs.
    sweep(pid, { walkTree: true });
    controller.abort();
    return true;
  }

  function killAll() {
    for (const [pid, controller] of running) {
      sweep(pid, { walkTree: true });
      controller.abort();
    }
  }

  return { start, kill, killAll };
}
