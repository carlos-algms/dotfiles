/**!
 * Text-object region math for the vim-mode fork: iw/aw, quote objects,
 * bracket pairs. Self-contained (no pi imports), so node:test can load it
 * directly (pattern of vim-snippets.ts).
 */

import { removeLines } from './line-edits.ts';

// End-exclusive: the region is [start, end). `linewise` is set only by
// bracketRegion's inner adjustment (vim's di( / ci( on a block whose
// boundaries fold to line edges): delete removes the covered lines, change
// leaves one empty line.
export type Region = {
  startLine: number;
  startCol: number;
  endLine: number;
  endCol: number;
  linewise?: true;
};

// Object char -> bracket pair. Closing chars and b/B are synonyms.
const BRACKETS: Record<string, readonly [open: string, close: string]> = {
  '(': ['(', ')'],
  ')': ['(', ')'],
  b: ['(', ')'],
  '[': ['[', ']'],
  ']': ['[', ']'],
  '{': ['{', '}'],
  '}': ['{', '}'],
  B: ['{', '}'],
  '<': ['<', '>'],
  '>': ['<', '>'],
};

export function resolveTextObject(
  lines: string[],
  line: number,
  col: number,
  key: string,
  outer: boolean,
  maskBracketLine?: (text: string) => string,
): Region | null {
  if (key === 'w' || key === 'W') {
    return wordRegion(lines, line, col, outer);
  }
  if (key === '"' || key === "'" || key === '`') {
    return quoteRegion(lines, line, col, key, outer);
  }
  const pair = BRACKETS[key];
  if (!pair) {
    return null;
  }
  const bracketLines = maskBracketLine ? lines.map(maskBracketLine) : lines;
  return bracketRegion(bracketLines, line, col, pair[0], pair[1], outer);
}

// Mirrors pi's word classes (pi-tui utils.js): a white space run, an ASCII
// punctuation run, or a word run. pi-tui's PUNCTUATION_REGEX is not exported
// from the package root, so the character set is duplicated here.
const WORD_PUNCT = /[(){}\[\]<>.,;:'"!?+\-=*/\\|&%^$#@~`]/;

function charClass(ch: string): 'ws' | 'punct' | 'word' {
  if (/\s/.test(ch)) {
    return 'ws';
  }
  return WORD_PUNCT.test(ch) ? 'punct' : 'word';
}

// vim's outer-object white space rule: take the run's trailing white space,
// or its leading white space when there is none (motion.txt, object-select).
// Around quotes can include leading indentation.
function extendOverWhitespace(
  text: string,
  start: number,
  end: number,
  { guardIndent = false }: { guardIndent?: boolean } = {},
): { start: number; end: number } {
  let wsEnd = end;
  while (wsEnd < text.length && charClass(text.charAt(wsEnd)) === 'ws') {
    wsEnd++;
  }
  if (wsEnd > end) {
    return { start, end: wsEnd };
  }
  let wsStart = start;
  while (wsStart > 0 && charClass(text.charAt(wsStart - 1)) === 'ws') {
    wsStart--;
  }
  // guardIndent: aw never reaches back into the line indent.
  return { start: guardIndent && wsStart === 0 ? start : wsStart, end };
}

const graphemes = new Intl.Segmenter(undefined, { granularity: 'grapheme' });

// aw extends a non-whitespace run without reaching back into the indent.
// Starting on whitespace takes that run plus the following object.
export function wordRegion(
  lines: string[],
  line: number,
  col: number,
  outer: boolean,
): Region | null {
  const text = lines[line] ?? '';
  const segments = [...graphemes.segment(text)];
  let cursor = segments.length - 1;
  while (cursor >= 0 && (segments[cursor]?.index ?? 0) > col) {
    cursor--;
  }
  if (cursor < 0) {
    return null;
  }
  const classes = segments.map(({ segment }) => charClass(segment.charAt(0)));
  const cls = classes[cursor];
  let start = cursor;
  let end = cursor + 1;
  while (start > 0 && classes[start - 1] === cls) {
    start--;
  }
  while (end < classes.length && classes[end] === cls) {
    end++;
  }
  if (outer && cls === 'ws') {
    if (end === classes.length) {
      return null;
    }
    const next = classes[end];
    while (end < classes.length && classes[end] === next) {
      end++;
    }
  }
  const charStart = segments[start]?.index ?? 0;
  const charEnd = segments[end]?.index ?? text.length;
  const { start: startCol, end: endCol } =
    outer && cls !== 'ws'
      ? extendOverWhitespace(text, charStart, charEnd, { guardIndent: true })
      : { start: charStart, end: charEnd };
  return {
    startLine: line,
    startCol,
    endLine: line,
    endCol,
  };
}

// A backslash run of odd length escapes the char after it.
function isEscaped(text: string, i: number): boolean {
  let backslashes = 0;
  for (let k = i - 1; k >= 0 && text.charAt(k) === '\\'; k--) {
    backslashes++;
  }
  return backslashes % 2 === 1;
}

// i"/a" (also ' and `): same line only, as in vim. Off a quote: the region
// between the previous quote and the next one. On a quote: quotes pair up
// counting from the line start. a" also takes trailing white space, or
// leading white space when there is none (vim motion.txt, v_aquote).
export function quoteRegion(
  lines: string[],
  line: number,
  col: number,
  quote: string,
  outer: boolean,
): Region | null {
  const text = lines[line] ?? '';
  const positions: number[] = [];
  for (let i = 0; i < text.length; i++) {
    // vim skips quotes escaped with 'quoteescape' (backslash by default).
    if (text.charAt(i) === quote && !isEscaped(text, i)) {
      positions.push(i);
    }
  }
  const next = positions.findIndex((p) => p >= col);
  if (next < 0) {
    return null;
  }
  const first =
    positions[next] === col ? next - (next % 2) : Math.max(0, next - 1);
  // Outside a string, an escaped quote at the cursor starts the gap.
  const escapedBeforeOpen =
    next % 2 === 0 && text.charAt(col) === quote && isEscaped(text, col);
  const open = escapedBeforeOpen
    ? text.indexOf(quote, (positions[next - 1] ?? -1) + 1)
    : positions[first];
  const close = positions[escapedBeforeOpen ? next : first + 1];
  if (open === undefined || close === undefined) {
    return null;
  }
  if (!outer) {
    return {
      startLine: line,
      startCol: open + 1,
      endLine: line,
      endCol: close,
    };
  }
  // No indent guard here: vim's a" does eat the line's leading white space.
  const { start, end } = extendOverWhitespace(text, open, close + 1);
  return { startLine: line, startCol: start, endLine: line, endCol: end };
}

// True when `flat` sits strictly between the ends of a run the mask hid (e.g.
// inside a quoted string). Boundaries and runs already masked in `text` (paste
// markers) are not interior.
function insideMaskedSpan(text: string, masked: string, flat: number): boolean {
  const isMask = (i: number) =>
    masked.charAt(i) === '\0' && text.charAt(i) !== '\0';
  if (!isMask(flat)) {
    return false;
  }
  let start = flat;
  let end = flat;
  while (start > 0 && isMask(start - 1)) start--;
  while (end < masked.length - 1 && isMask(end + 1)) end++;
  return flat > start && flat < end;
}

// i(/a( (also [ { <). Multiline: the buffer is scanned as one string, so
// blocks may span lines. Depth counting finds the enclosing pair; off any
// pair, the next opener and its match are used, as in vim (motion.txt,
// object-select). On the closer, the pair that closes there is selected.
export function bracketRegion(
  lines: string[],
  line: number,
  col: number,
  open: string,
  close: string,
  outer: boolean,
): Region | null {
  const text = lines.join('\n');
  const flat = lines.slice(0, line).reduce((n, l) => n + l.length + 1, col);
  // Mask double-quoted strings and single-character literals without moving offsets.
  const delimiters = text.replace(
    /\\[^\n]|'(?:\\[^\n]|[^'\\\n])'|"(?:\\[^\n]|[^"\\\n])*"/gu,
    (match) => (match.startsWith('\\') ? match : '\0'.repeat(match.length)),
  );
  // vim is not string-aware: with the cursor strictly inside a masked string,
  // the block under it wins over the mask. The quotes themselves stay masked,
  // and so does a mask already in `text` (paste markers).
  const scan = insideMaskedSpan(text, delimiters, flat) ? text : delimiters;
  // On the closer, the closer itself must not close the block.
  const from = scan.charAt(flat) === close ? flat - 1 : flat;
  let depth = 0;
  let openIdx = -1;
  for (let i = from; i >= 0; i--) {
    const ch = scan.charAt(i);
    if (ch === close) {
      depth++;
    } else if (ch === open) {
      if (depth === 0) {
        openIdx = i;
        break;
      }
      depth--;
    }
  }
  if (openIdx === -1) {
    openIdx = scan.indexOf(open, flat);
  }
  if (openIdx === -1) {
    return null;
  }
  depth = 0;
  let closeIdx = -1;
  for (let i = openIdx + 1; i < text.length; i++) {
    const ch = scan.charAt(i);
    if (ch === open) {
      depth++;
    } else if (ch === close) {
      if (depth === 0) {
        closeIdx = i;
        break;
      }
      depth--;
    }
  }
  if (closeIdx === -1) {
    return null;
  }
  // vim keeps a block's line structure: the inner region starts on the next
  // line when the opener ends a line and ends on the previous line's end
  // when the closer starts one.
  let startFlat = outer ? openIdx : openIdx + 1;
  let endFlat = outer ? closeIdx + 1 : closeIdx;
  if (!outer) {
    if (text.charAt(startFlat) === '\n') {
      startFlat++;
    }
    // vim's current_block() steps a closer that is alone on its line (only
    // its indent before it) back to the previous line's end, so the indent
    // survives and the interior lines go linewise.
    const closePos = flatToPos(lines, closeIdx);
    const closePrefix = (lines[closePos.line] ?? '').slice(0, closePos.col);
    if (closePos.line > 0 && /^[ \t]*$/.test(closePrefix)) {
      endFlat = closeIdx - closePos.col - 1;
    }
    // ( and ) on adjacent lines: the interior is the line break itself, so
    // folding overshoots. vim treats that as an empty inner block.
    if (startFlat > endFlat) {
      endFlat = startFlat;
    }
  }
  const start = flatToPos(lines, startFlat);
  const end = flatToPos(lines, endFlat);
  const linewise =
    !outer &&
    start.col === 0 &&
    end.col === (lines[end.line] ?? '').length &&
    start.line <= end.line;
  return {
    startLine: start.line,
    startCol: start.col,
    endLine: end.line,
    endCol: end.col,
    ...(linewise ? { linewise: true } : {}),
  };
}

// Remove a region from the buffer: the pure half of applyTextObject in
// index.ts. Linewise regions: change keeps one empty line (vim ci( on a
// vertical block), delete removes the covered lines (vim di().
export function applyRegion(
  lines: string[],
  region: Region,
  change: boolean,
): { lines: string[]; killed: string } {
  if (region.linewise) {
    return removeLines(lines, region.startLine, region.endLine, change);
  }
  const startText = lines[region.startLine] ?? '';
  const endText = lines[region.endLine] ?? '';
  const killed =
    region.startLine === region.endLine
      ? startText.slice(region.startCol, region.endCol)
      : [
          startText.slice(region.startCol),
          ...lines.slice(region.startLine + 1, region.endLine),
          endText.slice(0, region.endCol),
        ].join('\n');
  const newLines = lines.slice();
  newLines.splice(
    region.startLine,
    region.endLine - region.startLine + 1,
    startText.slice(0, region.startCol) + endText.slice(region.endCol),
  );
  return { lines: newLines, killed };
}

// Flat index into lines joined by '\n' -> line/col. A separator index maps
// to the end of the line before it.
function flatToPos(
  lines: string[],
  idx: number,
): { line: number; col: number } {
  let line = 0;
  let col = idx;
  while (line < lines.length - 1 && col > (lines[line] ?? '').length) {
    col -= (lines[line] ?? '').length + 1;
    line++;
  }
  return { line, col };
}
