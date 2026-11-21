import assert from 'node:assert/strict';
import { test } from 'node:test';
import { lineRange, removeLines } from './line-edits.ts';

test('lineRange covers the dd family', () => {
  assert.deepEqual(lineRange(5, 2, 'current'), { first: 2, last: 2 });
  assert.deepEqual(lineRange(5, 2, 'down'), { first: 2, last: 3 });
  assert.deepEqual(lineRange(5, 2, 'up'), { first: 1, last: 2 });
  assert.deepEqual(lineRange(5, 2, 'toFirst'), { first: 0, last: 2 });
  assert.deepEqual(lineRange(5, 2, 'toLast'), { first: 2, last: 4 });
});

test('lineRange fails on the edge line, as in vim', () => {
  assert.equal(lineRange(3, 0, 'up'), null);
  assert.equal(lineRange(3, 2, 'down'), null);
});

test('dj on the first of three lines leaves the last, as in vim', () => {
  const lines = ['one', 'two', 'three'];
  const span = lineRange(lines.length, 0, 'down');
  assert.ok(span);
  assert.deepEqual(removeLines(lines, span.first, span.last, false), {
    lines: ['three'],
    killed: 'one\ntwo',
  });
});

test('ck on the last line leaves one empty line, as in vim', () => {
  const lines = ['one', 'two'];
  const span = lineRange(lines.length, 1, 'up');
  assert.ok(span);
  assert.deepEqual(removeLines(lines, span.first, span.last, true), {
    lines: [''],
    killed: 'one\ntwo',
  });
});

test('removeLines keeps one empty line when the buffer empties', () => {
  assert.deepEqual(removeLines(['a', 'b'], 0, 1, false), {
    lines: [''],
    killed: 'a\nb',
  });
  assert.deepEqual(removeLines(['a', 'b'], 0, 1, true), {
    lines: [''],
    killed: 'a\nb',
  });
});

test('removeLines shifts the tail up and keeps it', () => {
  assert.deepEqual(removeLines(['a', 'b', 'c'], 1, 2, false), {
    lines: ['a'],
    killed: 'b\nc',
  });
});
