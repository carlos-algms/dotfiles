import type { Jobs } from './jobs.ts';

export function createToolHandlers(jobs: Pick<Jobs, 'start' | 'kill'>) {
  async function run(params: { command: string; timeout?: number }, cwd: string) {
    const { pid, logPath } = await jobs.start(params.command, cwd, params.timeout);
    return {
      content: [{ type: 'text' as const, text: `Started job ${pid}. Log: ${logPath}` }],
      details: { pid, logPath },
    };
  }

  async function kill(params: { pid: number }) {
    if (!jobs.kill(params.pid)) {
      throw new Error(`No running job ${params.pid}. Manual fallback: kill -- -${params.pid}`);
    }
    return {
      content: [{ type: 'text' as const, text: `Stopping job ${params.pid}` }],
      details: { pid: params.pid },
    };
  }

  return { run, kill };
}
