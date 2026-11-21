export type LineMotion = 'current' | 'down' | 'up' | 'toFirst' | 'toLast';

// A vertical motion fails at the buffer edge without editing the line.
export function lineRange(
  lineCount: number,
  line: number,
  range: LineMotion,
): { first: number; last: number } | null {
  if (range === 'up' && line === 0) {
    return null;
  }
  if (range === 'down' && line === lineCount - 1) {
    return null;
  }
  return {
    first: range === 'toFirst' ? 0 : range === 'up' ? line - 1 : line,
    last:
      range === 'toLast' ? lineCount - 1 : range === 'down' ? line + 1 : line,
  };
}

export function removeLines(
  lines: string[],
  first: number,
  last: number,
  change: boolean,
): { lines: string[]; killed: string } {
  const killed = lines.slice(first, last + 1).join('\n');
  const rest = [
    ...lines.slice(0, first),
    ...(change ? [''] : []),
    ...lines.slice(last + 1),
  ];
  return { lines: rest.length > 0 ? rest : [''], killed };
}
