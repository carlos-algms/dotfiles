import assert from 'node:assert/strict';
import { test } from 'node:test';
import { expandFenceSnippet } from './vim-snippets.ts';

test('lone backtick expands to a 4-backtick fence with cursor inside', () => {
  assert.deepEqual(expandFenceSnippet(['`'], 0, 1), {
    lines: ['````', '', '````'],
    line: 1,
    col: 0,
  });
});

test('lone word expands to a fence tagged with that word', () => {
  assert.deepEqual(expandFenceSnippet(['md'], 0, 2), {
    lines: ['````md', '', '````'],
    line: 1,
    col: 0,
  });
});

test('backtick followed by a word expands to the same fence', () => {
  assert.deepEqual(expandFenceSnippet(['`ts'], 0, 3), {
    lines: ['````ts', '', '````'],
    line: 1,
    col: 0,
  });
});

test('language names with +, #, and - are accepted', () => {
  assert.deepEqual(expandFenceSnippet(['c++'], 0, 3)?.lines, [
    '````c++',
    '',
    '````',
  ]);
  assert.deepEqual(expandFenceSnippet(['objective-c'], 0, 11)?.lines, [
    '````objective-c',
    '',
    '````',
  ]);
});

test('only the trigger line changes, neighbours are kept', () => {
  assert.deepEqual(expandFenceSnippet(['intro', 'md', 'after'], 1, 2), {
    lines: ['intro', '````md', '', '````', 'after'],
    line: 2,
    col: 0,
  });
});

test('empty line does not expand', () => {
  assert.equal(expandFenceSnippet([''], 0, 0), null);
});

test('cursor before end of line does not expand', () => {
  assert.equal(expandFenceSnippet(['md'], 0, 1), null);
});

test('text before the trigger does not expand', () => {
  assert.equal(expandFenceSnippet(['the md'], 0, 6), null);
  assert.equal(expandFenceSnippet(['x `md'], 0, 5), null);
});

test('double backtick and closed code span do not expand', () => {
  assert.equal(expandFenceSnippet(['``'], 0, 2), null);
  assert.equal(expandFenceSnippet(['`md`'], 0, 4), null);
});

test('word must start with a letter', () => {
  assert.equal(expandFenceSnippet(['1st'], 0, 3), null);
  assert.equal(expandFenceSnippet(['-'], 0, 1), null);
});
