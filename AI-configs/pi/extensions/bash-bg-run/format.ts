import type { JobResult } from './jobs.ts';

export function formatCompletion(result: JobResult, tail: string): string {
  const { pid, command, logPath, exitCode, error } = result;
  const outcome = error === undefined ? `exit ${exitCode}` : error;
  const lines = [
    `Job ${pid} ended (${outcome}): ${command}`,
    `Log: ${logPath}`,
  ];
  if (tail.trim() !== '') {
    lines.push('Last output:', tail.trimEnd());
  }
  return lines.join('\n');
}
