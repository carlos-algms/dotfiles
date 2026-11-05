import type { PromptBox } from 'claude-code';

const FENCE = '````';

// Copied from AI-configs/pi/extensions/vim-mode/vim-snippets.ts, adapted to a
// flat text + cursor. Optional backtick, then an optional word starting with a
// letter.
const FENCE_TRIGGER = /^(`?)([a-z][\w+#-]*)?$/i;

const FENCE_LINE = /^ {0,3}(`{3,}|~{3,})/;

// A fence closes on a line of only its own character, at least as long.
function isInsideFence(textBefore: string): boolean {
  let open: string | undefined;
  for (const line of textBefore.split('\n')) {
    const fence = FENCE_LINE.exec(line)?.[1];
    if (!fence) {
      continue;
    }
    if (!open) {
      open = fence;
    } else if (
      fence[0] === open[0] &&
      fence.length >= open.length &&
      line.trim() === fence
    ) {
      open = undefined;
    }
  }
  return open !== undefined;
}

// Expands a line that is only a backtick and/or a language word, with the
// cursor at end of line. Returns null when the line does not match.
export function expandFenceSnippet(
  text: string,
  cursor: number,
): PromptBox | null {
  const next = text.indexOf('\n', cursor);
  const lineEnd = next === -1 ? text.length : next;
  if (lineEnd !== cursor) {
    return null;
  }
  const lineStart = text.lastIndexOf('\n', cursor - 1) + 1;
  const match = FENCE_TRIGGER.exec(text.slice(lineStart, cursor));
  if (!match) {
    return null;
  }
  const [, backtick = '', word = ''] = match;
  if (backtick === '' && word === '') {
    return null;
  }
  if (isInsideFence(text.slice(0, lineStart))) {
    return null;
  }
  const open = FENCE + word;
  return {
    text: `${text.slice(0, lineStart)}${open}\n\n${FENCE}${text.slice(cursor)}`,
    cursor: lineStart + open.length + 1,
  };
}
