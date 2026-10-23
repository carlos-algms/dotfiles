import type { JobResult } from './jobs.ts';

const TAIL_MARKER = 'Last output:';

/** Keeps the header and the last `tailLines` output lines, for the collapsed view. */
export function collapseCompletion(
  content: string,
  tailLines: number,
): { text: string; hidden: number } {
  const lines = content.split('\n');
  const start = lines.indexOf(TAIL_MARKER) + 1;
  const hidden =
    start === 0 ? 0 : Math.max(0, lines.length - start - tailLines);
  if (hidden === 0) {
    return { text: content, hidden: 0 };
  }
  const kept = [...lines.slice(0, start), ...lines.slice(start + hidden)];
  return { text: kept.join('\n'), hidden };
}

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
