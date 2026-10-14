import { execFileSync } from 'node:child_process';

/** Env var set to the job id in every job shell. Children inherit it, even across `setsid` and double forks. */
export const JOB_TAG = 'PI_BG_JOB';

export interface Proc {
  pid: number;
  ppid: number;
  command: string;
}

export interface SweepOptions {
  /** Also kill descendants of the job shell. Only valid while that shell is alive: a dead pid may be reused. */
  walkTree: boolean;
}

const PS_MAX_BUFFER = 64 * 1024 * 1024;

/** `ps axeww` appends each process's environment to its command line. BSD syntax works on macOS and Linux. */
function listProcesses(): Proc[] {
  let output: string;
  try {
    output = execFileSync('ps', ['axeww', '-o', 'pid=,ppid=,command='], {
      encoding: 'utf-8',
      maxBuffer: PS_MAX_BUFFER,
    });
  } catch {
    // The sweep is best effort: a missing `ps` must not block the kill itself.
    return [];
  }
  const procs: Proc[] = [];
  for (const line of output.split('\n')) {
    const match = /^\s*(\d+)\s+(\d+)\s+(.*)$/.exec(line);
    if (match) {
      procs.push({
        pid: Number(match[1]),
        ppid: Number(match[2]),
        command: match[3] ?? '',
      });
    }
  }
  return procs;
}

export function findTargets(
  procs: Proc[],
  pid: number,
  options: SweepOptions & { self?: number },
): number[] {
  const targets = new Set<number>();
  const tag = new RegExp(`(?:^|\\s)${JOB_TAG}=${pid}(?:\\s|$)`);
  for (const proc of procs) {
    if (tag.test(proc.command)) {
      targets.add(proc.pid);
    }
  }

  if (options.walkTree) {
    const visited = new Set([pid]);
    const pending = [pid];
    for (
      let parent = pending.pop();
      parent !== undefined;
      parent = pending.pop()
    ) {
      for (const proc of procs) {
        if (proc.ppid === parent && !visited.has(proc.pid)) {
          visited.add(proc.pid);
          targets.add(proc.pid);
          pending.push(proc.pid);
        }
      }
    }
  }

  targets.delete(options.self ?? -1);
  return [...targets];
}

/**
 * Kills what the job left behind: processes that carry the job tag, plus (while the job shell is alive)
 * its descendants. Best effort, not a lock: a process that clears its environment, or a SIP-protected
 * macOS binary whose environment `ps` hides, escapes the tag, and a process forked after the scan escapes both.
 */
export function sweep(pid: number, options: SweepOptions): void {
  for (const target of findTargets(listProcesses(), pid, {
    ...options,
    self: process.pid,
  })) {
    try {
      process.kill(target, 'SIGTERM');
    } catch {
      // Already gone between the scan and the kill.
    }
  }
}
