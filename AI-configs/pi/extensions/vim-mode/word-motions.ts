/**!
 * Vim word motions for the vim-mode fork. Lowercase `w`/`b`/`e` move over
 * keyword and punctuation runs; uppercase `W`/`B`/`E` move over whitespace-
 * delimited WORDs, so a punctuation run merges with its neighbours. Both replace
 * pi's word primitives. Self-contained (no pi imports), so node:test can load it
 * directly (pattern of text-objects.ts).
 */

import type { Region } from './text-objects.ts';

export type WordScan = 'w' | 'b' | 'e' | 'W' | 'B' | 'E';
export type Cursor = { line: number; col: number };

type CharClass = 'keyword' | 'punct' | 'blank' | 'line';

function isBlank(ch: string | undefined): boolean {
  return ch === ' ' || ch === '\t';
}

function isSpace(ch: string | undefined): boolean {
  return ch === ' ' || ch === '\t' || ch === '\n';
}

// vim's default iskeyword: letters, digits, `_`, and every non-ASCII character.
function isKeyword(ch: string | undefined): boolean {
  if (ch === undefined) {
    return false;
  }
  return /[\p{L}\p{N}_]/u.test(ch) || ch.charCodeAt(0) > 127;
}

function classOf(ch: string | undefined): CharClass {
  if (ch === undefined || ch === '\n') {
    return 'line';
  }
  if (isBlank(ch)) {
    return 'blank';
  }
  return isKeyword(ch) ? 'keyword' : 'punct';
}

function toOffset(lines: string[], { line, col }: Cursor): number {
  let offset = col;
  for (let i = 0; i < line; i++) {
    offset += (lines[i] ?? '').length + 1;
  }
  return offset;
}

function fromOffset(lines: string[], offset: number): Cursor {
  let rest = offset;
  for (let line = 0; line < lines.length; line++) {
    const length = (lines[line] ?? '').length;
    if (rest <= length) {
      return { line, col: rest };
    }
    rest -= length + 1;
  }
  const last = lines.length - 1;
  return { line: last, col: (lines[last] ?? '').length };
}

// Where vim parks the cursor when no word is left: the last character of the
// buffer, which is the last column of the last non-empty line.
function lastCharOffset(lines: string[]): number {
  const text = lines.join('\n');
  for (let i = text.length - 1; i >= 0; i--) {
    if (text[i] !== '\n') {
      return i;
    }
  }
  return 0;
}

// Start of the next word. An empty line is a stop; a blank-only line is not.
// `word` splits runs by character class, so punctuation starts its own word.
function forwardStart(text: string, at: number, word: boolean): number {
  let i = at;
  const startClass = classOf(text[i]);
  if (startClass === 'keyword' || startClass === 'punct') {
    while (i < text.length) {
      const cls = classOf(text[i]);
      if (cls === 'line' || cls === 'blank') {
        break;
      }
      if (word && cls !== startClass) {
        break;
      }
      i++;
    }
  }
  while (i < text.length) {
    const ch = text[i];
    if (ch === '\n') {
      // The line after this break is empty: stop on its first column.
      if (text[i + 1] === undefined || text[i + 1] === '\n') {
        return i + 1;
      }
      i++;
      continue;
    }
    if (isBlank(ch)) {
      i++;
      continue;
    }
    return i;
  }
  return -1;
}

// Last character of the current or next word.
function forwardEnd(text: string, at: number, word: boolean): number {
  let i = at + 1;
  while (i < text.length && isSpace(text[i])) {
    i++;
  }
  if (i >= text.length) {
    return -1;
  }
  const runClass = classOf(text[i]);
  let end = i;
  while (end + 1 < text.length) {
    const cls = classOf(text[end + 1]);
    if (cls === 'line' || cls === 'blank') {
      break;
    }
    if (word && cls !== runClass) {
      break;
    }
    end++;
  }
  return end;
}

// Start of the previous word. An empty line is a stop; a blank-only line is not.
function backwardStart(text: string, at: number, word: boolean): number {
  let i = at - 1;
  while (i >= 0) {
    const cls = classOf(text[i]);
    if (cls === 'line') {
      if (i === 0 || text[i - 1] === '\n') {
        return i;
      }
      i--;
      continue;
    }
    if (cls === 'blank') {
      i--;
      continue;
    }
    break;
  }
  if (i < 0) {
    return 0;
  }
  const runClass = classOf(text[i]);
  while (i > 0) {
    const cls = classOf(text[i - 1]);
    if (cls === 'line' || cls === 'blank') {
      break;
    }
    if (word && cls !== runClass) {
      break;
    }
    i--;
  }
  return i;
}

// True when the character at `at` is the last one of its run. `word` selects the
// lowercase rule, where a punctuation run is a separate word.
function runEndsAt(text: string, at: number, word: boolean): boolean {
  const cls = classOf(text[at]);
  if (cls === 'line' || cls === 'blank') {
    return false;
  }
  const next = classOf(text[at + 1]);
  return word ? next !== cls : next === 'line' || next === 'blank';
}

function scanOffset(
  text: string,
  at: number,
  scan: WordScan,
): { found: number; edge: string } {
  const word = scan === scan.toLowerCase();
  const edge = scan.toLowerCase();
  const found =
    edge === 'b'
      ? backwardStart(text, at, word)
      : edge === 'w'
        ? forwardStart(text, at, word)
        : forwardEnd(text, at, word);
  return { found, edge };
}

export function scanWord(
  lines: string[],
  cursor: Cursor,
  scan: WordScan,
): Cursor {
  const text = lines.join('\n');
  const { found } = scanOffset(text, toOffset(lines, cursor), scan);
  return fromOffset(lines, found < 0 ? lastCharOffset(lines) : found);
}

// Region an operator covers over a word motion, end-exclusive and clamped to
// the cursor line: unlike vim, the fork never joins lines (same rule as dh and
// dd). `change` selects vim's cw/cW special case. Null means the operator is a
// no-op.
export function wordScanRegion(
  lines: string[],
  cursor: Cursor,
  scan: WordScan,
  change = false,
): Region | null {
  const text = lines.join('\n');
  const lineText = lines[cursor.line] ?? '';
  const at = toOffset(lines, cursor);
  // cw/cW on the last character of a run delete just that character, like cl.
  if (
    change &&
    (scan === 'w' || scan === 'W') &&
    runEndsAt(text, at, scan === 'w')
  ) {
    return cursor.col < lineText.length
      ? {
          startLine: cursor.line,
          startCol: cursor.col,
          endLine: cursor.line,
          endCol: cursor.col + 1,
        }
      : null;
  }
  // cw/cW act like ce/cE on a non-blank, so the trailing blanks stay in place.
  // On a blank they keep dw/dW's region: the blank run is replaced too.
  const changeAsEnd =
    change && scan.toLowerCase() === 'w' && !isBlank(lineText[cursor.col]);
  const effective: WordScan = changeAsEnd ? (scan === 'w' ? 'e' : 'E') : scan;
  const { found, edge } = scanOffset(text, at, effective);
  const target = fromOffset(lines, found < 0 ? lastCharOffset(lines) : found);
  if (edge === 'b') {
    const start = target.line === cursor.line ? target.col : 0;
    return start < cursor.col
      ? {
          startLine: cursor.line,
          startCol: start,
          endLine: cursor.line,
          endCol: cursor.col,
        }
      : null;
  }
  if (target.line !== cursor.line) {
    return cursor.col < lineText.length
      ? {
          startLine: cursor.line,
          startCol: cursor.col,
          endLine: cursor.line,
          endCol: lineText.length,
        }
      : null;
  }
  // dw/dW on the last word delete to the line end, as vim's exclusive motion
  // does, instead of stopping on the word's last character.
  const end =
    edge === 'w' && found < 0
      ? lineText.length
      : Math.min(target.col + (edge === 'e' ? 1 : 0), lineText.length);
  return cursor.col < end
    ? {
        startLine: cursor.line,
        startCol: cursor.col,
        endLine: cursor.line,
        endCol: end,
      }
    : null;
}
