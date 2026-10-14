export type SnippetEdit = {
  lines: string[];
  line: number;
  col: number;
};

const FENCE = '````';

// Optional backtick, then an optional word starting with a letter.
const FENCE_TRIGGER = /^(`?)([a-z][\w+#-]*)?$/i;

// Expands a line that is only a backtick and/or a language word, with the
// cursor at end of line. Returns null when the line does not match.
export function expandFenceSnippet(
  lines: string[],
  line: number,
  col: number,
): SnippetEdit | null {
  const text = lines[line] ?? '';
  if (col !== text.length) {
    return null;
  }
  const match = FENCE_TRIGGER.exec(text);
  if (!match) {
    return null;
  }
  const [, backtick = '', word] = match;
  if (backtick === '' && word === undefined) {
    return null;
  }
  const next = [...lines];
  next.splice(line, 1, FENCE + (word ?? ''), '', FENCE);
  return { lines: next, line: line + 1, col: 0 };
}
