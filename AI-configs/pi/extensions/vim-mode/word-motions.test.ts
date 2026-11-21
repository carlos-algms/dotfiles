import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  type Cursor,
  type WordScan,
  scanWord,
  wordScanRegion,
} from './word-motions.ts';

// Expected positions were taken from vim 9.1 on the same buffer, 0-based.
function at(lines: string[], from: Cursor, scan: WordScan): Cursor {
  return scanWord(lines, from, scan);
}

function c(line: number, col: number): Cursor {
  return { line, col };
}

test('W stops on the next WORD start and keeps punctuation attached', () => {
  assert.deepEqual(at(['foo bar'], c(0, 0), 'W'), c(0, 4));
  assert.deepEqual(at(['foo.bar baz'], c(0, 0), 'W'), c(0, 8));
  assert.deepEqual(at(['foo bar'], c(0, 2), 'W'), c(0, 4));
  assert.deepEqual(at(['one two'], c(0, 3), 'W'), c(0, 4));
});

test('W falls back to the last character when no WORD follows', () => {
  assert.deepEqual(at(['one'], c(0, 0), 'W'), c(0, 2));
  assert.deepEqual(at(['one two'], c(0, 4), 'W'), c(0, 6));
  assert.deepEqual(at(['one', '   '], c(0, 0), 'W'), c(1, 2));
});

test('W crosses lines, stops on an empty line, skips blank-only lines', () => {
  assert.deepEqual(at(['one', 'two'], c(0, 2), 'W'), c(1, 0));
  assert.deepEqual(at(['one', '', 'two'], c(0, 0), 'W'), c(1, 0));
  assert.deepEqual(at(['one', '', 'two'], c(1, 0), 'W'), c(2, 0));
  assert.deepEqual(at(['one', '   ', 'two'], c(0, 0), 'W'), c(2, 0));
});

test('B stops on the previous WORD start', () => {
  assert.deepEqual(at(['foo bar'], c(0, 4), 'B'), c(0, 0));
  assert.deepEqual(at(['one two three'], c(0, 12), 'B'), c(0, 8));
  assert.deepEqual(at(['one two three'], c(0, 4), 'B'), c(0, 0));
  assert.deepEqual(at(['one  two'], c(0, 7), 'B'), c(0, 5));
  assert.deepEqual(at(['foo bar'], c(0, 0), 'B'), c(0, 0));
});

test('B crosses lines, stops on an empty line, skips blank-only lines', () => {
  assert.deepEqual(at(['one', 'two'], c(1, 0), 'B'), c(0, 0));
  assert.deepEqual(at(['one', '', 'two'], c(2, 0), 'B'), c(1, 0));
  assert.deepEqual(at(['one', '', 'two'], c(1, 0), 'B'), c(0, 0));
  assert.deepEqual(at(['one', '   ', 'two'], c(2, 0), 'B'), c(0, 0));
  assert.deepEqual(at(['   ', 'foo'], c(1, 0), 'B'), c(0, 0));
});

test('E stops on the last character of the current or next WORD', () => {
  assert.deepEqual(at(['foo bar'], c(0, 0), 'E'), c(0, 2));
  assert.deepEqual(at(['foo.bar baz'], c(0, 0), 'E'), c(0, 6));
  assert.deepEqual(at(['  foo  bar'], c(0, 0), 'E'), c(0, 4));
});

test('E skips empty and blank-only lines and stays at the buffer end', () => {
  assert.deepEqual(at(['one', '', 'two'], c(0, 0), 'E'), c(0, 2));
  assert.deepEqual(at(['one', '', 'two'], c(0, 2), 'E'), c(2, 2));
  assert.deepEqual(at(['one', '   ', 'two'], c(0, 2), 'E'), c(2, 2));
  assert.deepEqual(at(['one'], c(0, 2), 'E'), c(0, 2));
  assert.deepEqual(at(['   '], c(0, 0), 'E'), c(0, 2));
});

test('dW region runs to the next WORD, or to the line end without one', () => {
  assert.deepEqual(wordScanRegion(['one two three'], c(0, 0), 'W'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 4,
  });
  assert.deepEqual(wordScanRegion(['one   two'], c(0, 0), 'W'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 6,
  });
  assert.deepEqual(wordScanRegion(['one two'], c(0, 4), 'W'), {
    startLine: 0,
    startCol: 4,
    endLine: 0,
    endCol: 7,
  });
});

test('dW never joins lines', () => {
  assert.deepEqual(wordScanRegion(['one', 'two'], c(0, 0), 'W'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 3,
  });
});

test('dE region is inclusive of the WORD end', () => {
  assert.deepEqual(wordScanRegion(['one two'], c(0, 0), 'E'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 3,
  });
  assert.deepEqual(wordScanRegion(['one two'], c(0, 4), 'E'), {
    startLine: 0,
    startCol: 4,
    endLine: 0,
    endCol: 7,
  });
  assert.deepEqual(wordScanRegion(['one', 'two'], c(0, 2), 'E'), {
    startLine: 0,
    startCol: 2,
    endLine: 0,
    endCol: 3,
  });
});

test('dB region runs back to the previous WORD start', () => {
  assert.deepEqual(wordScanRegion(['one two'], c(0, 4), 'B'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 4,
  });
  assert.deepEqual(wordScanRegion(['one two'], c(0, 6), 'B'), {
    startLine: 0,
    startCol: 4,
    endLine: 0,
    endCol: 6,
  });
});

test('dB at a line start has no region, since the fork never joins lines', () => {
  assert.equal(wordScanRegion(['one', 'two'], c(1, 0), 'B'), null);
});

test('cW keeps the trailing blanks: vim treats it like cE on a non-blank', () => {
  assert.deepEqual(wordScanRegion(['one two'], c(0, 0), 'W', true), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 3,
  });
  assert.deepEqual(wordScanRegion(['one  two'], c(0, 0), 'W', true), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 3,
  });
  assert.deepEqual(wordScanRegion(['one two'], c(0, 4), 'W', true), {
    startLine: 0,
    startCol: 4,
    endLine: 0,
    endCol: 7,
  });
});

test('cW on a blank replaces the blank run, as dW does', () => {
  assert.deepEqual(wordScanRegion(['one two'], c(0, 3), 'W', true), {
    startLine: 0,
    startCol: 3,
    endLine: 0,
    endCol: 4,
  });
  assert.deepEqual(wordScanRegion(['one  two'], c(0, 3), 'W', true), {
    startLine: 0,
    startCol: 3,
    endLine: 0,
    endCol: 5,
  });
});

test('a WORD motion from an empty line has no region, since it would join', () => {
  assert.equal(wordScanRegion(['one', '', 'two'], c(1, 0), 'W'), null);
  assert.equal(wordScanRegion(['one', '', 'two'], c(1, 0), 'E'), null);
});

test('dB clamps a cross-line target to the line start', () => {
  assert.deepEqual(wordScanRegion(['one', 'two', 'three'], c(1, 2), 'B'), {
    startLine: 1,
    startCol: 0,
    endLine: 1,
    endCol: 2,
  });
});

test('w stops on the next word start, splitting punctuation into its own word', () => {
  assert.deepEqual(at(['foo bar'], c(0, 0), 'w'), c(0, 4));
  assert.deepEqual(at(['foo  bar'], c(0, 0), 'w'), c(0, 5));
  assert.deepEqual(at(['foo.'], c(0, 0), 'w'), c(0, 3));
  assert.deepEqual(at(['foo.bar baz'], c(0, 0), 'w'), c(0, 3));
  assert.deepEqual(at(['a-b c'], c(0, 0), 'w'), c(0, 1));
  assert.deepEqual(at(['a-b c'], c(0, 1), 'w'), c(0, 2));
});

test('w shares the WORD fallback to the buffer last character', () => {
  assert.deepEqual(at(['foo'], c(0, 0), 'w'), c(0, 2));
  assert.deepEqual(at(['foo.'], c(0, 3), 'w'), c(0, 3));
  assert.deepEqual(at(['one', '   '], c(0, 0), 'w'), c(1, 2));
  assert.deepEqual(at(['foo\tbar'], c(0, 0), 'w'), c(0, 4));
});

test('b stops on the previous word start, punctuation runs included', () => {
  assert.deepEqual(at(['foo bar'], c(0, 4), 'b'), c(0, 0));
  assert.deepEqual(at(['a-b c'], c(0, 4), 'b'), c(0, 2));
  assert.deepEqual(at(['a-b c'], c(0, 2), 'b'), c(0, 1));
  assert.deepEqual(at(['one', 'two'], c(1, 0), 'b'), c(0, 0));
});

test('e stops on the word end without merging punctuation', () => {
  assert.deepEqual(at(['a-b c'], c(0, 0), 'e'), c(0, 1));
  assert.deepEqual(at(['a-b c'], c(0, 1), 'e'), c(0, 2));
  assert.deepEqual(at(['a-b c'], c(0, 2), 'e'), c(0, 4));
  assert.deepEqual(at(['foo-bar baz'], c(0, 0), 'e'), c(0, 2));
  assert.deepEqual(at(['foo-bar baz'], c(0, 2), 'e'), c(0, 3));
  assert.deepEqual(at(['foo-bar baz'], c(0, 3), 'e'), c(0, 6));
  assert.deepEqual(at(['foo'], c(0, 2), 'e'), c(0, 2));
});

test('dw deletes to the next word start, or to the line end without one', () => {
  assert.deepEqual(wordScanRegion(['foo bar baz'], c(0, 0), 'w'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 4,
  });
  assert.deepEqual(wordScanRegion(['foo  bar'], c(0, 0), 'w'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 5,
  });
  assert.deepEqual(wordScanRegion(['foo-bar baz'], c(0, 0), 'w'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 3,
  });
  assert.deepEqual(wordScanRegion(['foo bar'], c(0, 4), 'w'), {
    startLine: 0,
    startCol: 4,
    endLine: 0,
    endCol: 7,
  });
  assert.deepEqual(wordScanRegion(['foo', 'bar'], c(0, 0), 'w'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 3,
  });
});

test('cw acts like ce on a non-blank and like dw on a blank', () => {
  assert.deepEqual(wordScanRegion(['foo bar'], c(0, 0), 'w', true), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 3,
  });
  assert.deepEqual(wordScanRegion(['foo-bar baz'], c(0, 0), 'w', true), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 3,
  });
  assert.deepEqual(wordScanRegion(['foo bar'], c(0, 3), 'w', true), {
    startLine: 0,
    startCol: 3,
    endLine: 0,
    endCol: 4,
  });
});

test('db and de regions follow the lowercase scans', () => {
  assert.deepEqual(wordScanRegion(['foo bar baz'], c(0, 4), 'b'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 4,
  });
  assert.deepEqual(wordScanRegion(['a-b c'], c(0, 4), 'b'), {
    startLine: 0,
    startCol: 2,
    endLine: 0,
    endCol: 4,
  });
  assert.deepEqual(wordScanRegion(['foo-bar baz'], c(0, 0), 'e'), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 3,
  });
  assert.deepEqual(wordScanRegion(['foo bar'], c(0, 4), 'e'), {
    startLine: 0,
    startCol: 4,
    endLine: 0,
    endCol: 7,
  });
});

test('cw and cW on a run last character delete just that character', () => {
  assert.deepEqual(wordScanRegion(['ab cd'], c(0, 1), 'w', true), {
    startLine: 0,
    startCol: 1,
    endLine: 0,
    endCol: 2,
  });
  assert.deepEqual(wordScanRegion(['foo-bar baz'], c(0, 2), 'w', true), {
    startLine: 0,
    startCol: 2,
    endLine: 0,
    endCol: 3,
  });
  assert.deepEqual(wordScanRegion(['ab cd'], c(0, 1), 'W', true), {
    startLine: 0,
    startCol: 1,
    endLine: 0,
    endCol: 2,
  });
});

test('ce on a run last character still reaches the next word end', () => {
  assert.deepEqual(wordScanRegion(['ab cd'], c(0, 1), 'e'), {
    startLine: 0,
    startCol: 1,
    endLine: 0,
    endCol: 5,
  });
});

test('cW maps to the WORD end, not the lowercase word end', () => {
  assert.deepEqual(wordScanRegion(['foo.bar baz'], c(0, 0), 'W', true), {
    startLine: 0,
    startCol: 0,
    endLine: 0,
    endCol: 7,
  });
  assert.deepEqual(wordScanRegion(['foo-bar baz'], c(0, 2), 'W', true), {
    startLine: 0,
    startCol: 2,
    endLine: 0,
    endCol: 7,
  });
});

test('non-ASCII characters belong to the keyword class', () => {
  assert.deepEqual(at(['héllo wörld'], c(0, 0), 'w'), c(0, 6));
  assert.deepEqual(at(['héllo wörld'], c(0, 0), 'W'), c(0, 6));
  assert.deepEqual(at(['aé-b'], c(0, 0), 'w'), c(0, 2));
});
