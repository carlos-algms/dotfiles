import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  type Region,
  applyRegion,
  bracketRegion,
  quoteRegion,
  resolveTextObject,
  wordRegion,
} from './text-objects.ts';

// Region helpers: single-line expectations written as [start, end).
function r(line: number, start: number, end: number): Region {
  return { startLine: line, startCol: start, endLine: line, endCol: end };
}

test('iw takes the word run around the cursor', () => {
  const lines = ['foo bar baz'];
  assert.deepEqual(wordRegion(lines, 0, 1, false), r(0, 0, 3));
  assert.deepEqual(wordRegion(lines, 0, 9, false), r(0, 8, 11));
});

test('iw takes a punctuation run, not the adjacent word', () => {
  const lines = ['a...b'];
  assert.deepEqual(wordRegion(lines, 0, 2, false), r(0, 1, 4));
});

test('iw on white space takes the run', () => {
  assert.deepEqual(wordRegion(['foo   bar'], 0, 5, false), r(0, 3, 6));
});

test('iw at the line end takes the final run but is a no-op on an empty line', () => {
  assert.deepEqual(wordRegion(['foo'], 0, 3, false), r(0, 0, 3));
  assert.equal(wordRegion([''], 0, 0, false), null);
});

test('iw keeps a combining mark with its punctuation', () => {
  assert.deepEqual(wordRegion(['a!\u0301b'], 0, 1, false), r(0, 1, 3));
});

test('aw takes trailing white space', () => {
  assert.deepEqual(wordRegion(['foo   bar'], 0, 1, true), r(0, 0, 6));
});

test('aw keeps the line indent, as in vim', () => {
  assert.deepEqual(wordRegion(['   foo'], 0, 5, true), r(0, 3, 6));
});

test('aw takes mid-line leading white space when there is no trailing', () => {
  assert.deepEqual(wordRegion(['a   foo'], 0, 5, true), r(0, 1, 7));
});

test('aw from white space takes the run plus the following object', () => {
  assert.deepEqual(wordRegion(['foo bar'], 0, 3, true), r(0, 3, 7));
});

test('aw from trailing white space with no following object fails', () => {
  assert.equal(wordRegion(['foo   '], 0, 4, true), null);
});

test('i" inside a string takes the content between quotes', () => {
  const lines = ['say "hi" now'];
  assert.deepEqual(quoteRegion(lines, 0, 6, '"', false), r(0, 5, 7));
});

test('quote objects work the same for double, single, and backtick quotes', () => {
  for (const quote of ['"', "'", '`']) {
    const lines = [`x = ${quote}hi${quote}`];
    assert.deepEqual(quoteRegion(lines, 0, 6, quote, false), r(0, 5, 7), quote);
    assert.deepEqual(resolveTextObject(lines, 0, 6, quote, true), r(0, 3, 8));
  }
});

test('a" includes quotes and trailing white space', () => {
  assert.deepEqual(quoteRegion(['say "hi" now'], 0, 6, '"', true), r(0, 4, 9));
});

test('a" with no trailing white space takes leading white space', () => {
  assert.deepEqual(quoteRegion(['   "hi"'], 0, 4, '"', true), r(0, 0, 7));
});

test('cursor on a quote pairs quotes from the line start', () => {
  const lines = ['"a" "b"'];
  assert.deepEqual(quoteRegion(lines, 0, 0, '"', false), r(0, 1, 2));
  assert.deepEqual(quoteRegion(lines, 0, 2, '"', false), r(0, 1, 2));
  assert.deepEqual(quoteRegion(lines, 0, 4, '"', false), r(0, 5, 6));
});

test('cursor between strings takes the gap, as vim does', () => {
  assert.deepEqual(quoteRegion(['"a" "b"'], 0, 3, '"', false), r(0, 3, 4));
});

test('an escaped quote does not end the region', () => {
  const lines = ['x = "a\\"b"'];
  assert.deepEqual(quoteRegion(lines, 0, 5, '"', false), r(0, 5, 9));
  assert.deepEqual(
    applyRegion(lines, quoteRegion(lines, 0, 5, '"', false)!, false),
    {
      lines: ['x = ""'],
      killed: 'a\\"b',
    },
  );
});

test('i" on an escaped quote selects its own string', () => {
  const lines = ['"keep" "a\\"b"'];
  assert.deepEqual(quoteRegion(lines, 0, 10, '"', false), r(0, 8, 12));
});

test('quote objects start at the first escaped quote in the gap', () => {
  assert.deepEqual(quoteRegion(['"a" \\" "b"'], 0, 5, '"', false), r(0, 6, 7));
  const lines = ['"a" \\" \\" "b"'];
  assert.deepEqual(quoteRegion(lines, 0, 8, '"', false), r(0, 6, 10));
  assert.deepEqual(quoteRegion(lines, 0, 8, '"', true), r(0, 5, 11));
});

test('i" before the first quote selects the next string', () => {
  assert.deepEqual(quoteRegion(['say "hi"'], 0, 0, '"', false), r(0, 5, 7));
});

test('an even backslash run does not escape the quote', () => {
  assert.deepEqual(quoteRegion(['"a\\\\" b'], 0, 2, '"', false), r(0, 1, 4));
});

test('unpaired or missing quotes fail', () => {
  assert.equal(quoteRegion(['no quotes'], 0, 2, '"', false), null);
  assert.equal(quoteRegion(['one " quote'], 0, 5, '"', false), null);
  assert.equal(quoteRegion(['"unterminated'], 0, 3, '"', false), null);
});

test('closing brackets and b/B select the same objects as openers', () => {
  const groups = [
    ['(x)', ['(', ')', 'b']],
    ['[x]', ['[', ']']],
    ['{x}', ['{', '}', 'B']],
    ['<x>', ['<', '>']],
  ] as const;
  for (const [line, keys] of groups) {
    for (const key of keys) {
      assert.deepEqual(resolveTextObject([line], 0, 1, key, false), r(0, 1, 2));
    }
  }
});

test('word and quote keys select their own objects', () => {
  assert.deepEqual(resolveTextObject(['"hi"'], 0, 1, 'W', false), r(0, 1, 3));
  assert.deepEqual(resolveTextObject(['"hi"'], 0, 1, '"', true), r(0, 0, 4));
  assert.equal(resolveTextObject(['hi'], 0, 1, 'z', false), null);
});

test('a( includes the delimiters', () => {
  assert.deepEqual(bracketRegion(['f(x)'], 0, 2, '(', ')', true), r(0, 1, 4));
});

test('i( picks the innermost of nested blocks', () => {
  assert.deepEqual(
    bracketRegion(['f(g(x))'], 0, 4, '(', ')', false),
    r(0, 4, 5),
  );
});

test('i( counts nested pairs when selecting the outer block', () => {
  assert.deepEqual(
    bracketRegion(['f(x, g(y), z)'], 0, 2, '(', ')', false),
    r(0, 2, 12),
  );
});

test('i( ignores a closer inside a double-quoted string', () => {
  const lines = ['f("a) data", next)'];
  const region = bracketRegion(lines, 0, 2, '(', ')', false);
  assert.ok(region);
  assert.deepEqual(applyRegion(lines, region, false).lines, ['f()']);
});

test('i( does not start a double-quoted string inside a character literal', () => {
  const lines = [`f('"', "a) data", next)`];
  const region = bracketRegion(lines, 0, 2, '(', ')', false);
  assert.ok(region);
  assert.deepEqual(applyRegion(lines, region, false).lines, ['f()']);
});

test('i( folds to whole lines when the block is vertical', () => {
  const lines = ['fn(', '  a, b', ') end'];
  const region = bracketRegion(lines, 1, 3, '(', ')', false);
  assert.ok(region);
  assert.deepEqual(region, {
    startLine: 1,
    startCol: 0,
    endLine: 1,
    endCol: 6,
    linewise: true,
  });
});

test('i( stays characterwise when only one boundary folds', () => {
  assert.deepEqual(
    bracketRegion(['fn(', '  a) end'], 1, 2, '(', ')', false),
    r(1, 0, 3),
  );
});

test('di( on a vertical block removes the inner lines, as in vim', () => {
  const lines = ['fn(', '  a', ') end'];
  const region = bracketRegion(lines, 1, 2, '(', ')', false);
  assert.ok(region);
  assert.deepEqual(applyRegion(lines, region, false), {
    lines: ['fn(', ') end'],
    killed: '  a',
  });
});

test('ci( on a vertical block leaves one empty line, as in vim', () => {
  const lines = ['fn(', 'a', 'b', ') end'];
  const region = bracketRegion(lines, 1, 2, '(', ')', false);
  assert.ok(region);
  assert.deepEqual(applyRegion(lines, region, true), {
    lines: ['fn(', '', ') end'],
    killed: 'a\nb',
  });
});

test('da( across lines merges onto one line, as in vim', () => {
  const lines = ['fn(', '  a', ') end'];
  const region = bracketRegion(lines, 1, 2, '(', ')', true);
  assert.ok(region);
  assert.deepEqual(applyRegion(lines, region, false), {
    lines: ['fn end'],
    killed: '(\n  a\n)',
  });
});

test('applyRegion is characterwise for single-line regions', () => {
  assert.deepEqual(applyRegion(['f(x)'], r(0, 2, 3), false), {
    lines: ['f()'],
    killed: 'x',
  });
});

test('applyRegion change keeps the surrounding text, ciw style', () => {
  const region = wordRegion(['foo bar'], 0, 1, false);
  assert.ok(region);
  assert.deepEqual(applyRegion(['foo bar'], region, true), {
    lines: [' bar'],
    killed: 'foo',
  });
});

test('applyRegion change on a quote keeps the quotes, ci" style', () => {
  const region = quoteRegion(['x = "hi"'], 0, 6, '"', false);
  assert.ok(region);
  assert.deepEqual(applyRegion(['x = "hi"'], region, true), {
    lines: ['x = ""'],
    killed: 'hi',
  });
});

test('a one-word line is a word object, not a whole-line delete', () => {
  const lines = ['before', 'foo', 'after'];
  const region = wordRegion(lines, 1, 1, false);
  assert.ok(region);
  assert.deepEqual(applyRegion(lines, region, false), {
    lines: ['before', '', 'after'],
    killed: 'foo',
  });
});

test('( and ) on adjacent lines are an empty inner block', () => {
  const region = bracketRegion(['(', ')'], 1, 0, '(', ')', false);
  assert.ok(region);
  assert.deepEqual(region, r(1, 0, 0));
  assert.deepEqual(applyRegion(['(', ')'], region, false), {
    lines: ['(', ')'],
    killed: '',
  });
});

test('white space inside a block is deleted, not skipped', () => {
  const region = bracketRegion(['(   )'], 0, 2, '(', ')', false);
  assert.ok(region);
  assert.deepEqual(applyRegion(['(   )'], region, false), {
    lines: ['()'],
    killed: '   ',
  });
});

test('an indented closer keeps its indent and folds linewise', () => {
  const lines = ['foo(', '  arg', '  )'];
  const region = bracketRegion(lines, 1, 3, '(', ')', false);
  assert.deepEqual(region, {
    startLine: 1,
    startCol: 0,
    endLine: 1,
    endCol: 5,
    linewise: true,
  });
  assert.deepEqual(applyRegion(lines, region, false), {
    lines: ['foo(', '  )'],
    killed: '  arg',
  });
});

test('an indented closer with a white-space only interior is empty', () => {
  const lines = ['f(', '  )'];
  assert.deepEqual(bracketRegion(lines, 0, 1, '(', ')', false), r(1, 0, 0));
});

test('a blank interior line is deleted, not skipped', () => {
  const lines = ['f(', '', ')'];
  const region = bracketRegion(lines, 1, 0, '(', ')', false);
  assert.deepEqual(region, {
    startLine: 1,
    startCol: 0,
    endLine: 1,
    endCol: 0,
    linewise: true,
  });
  assert.deepEqual(applyRegion(lines, region, false), {
    lines: ['f(', ')'],
    killed: '',
  });
});

test('di( removes a blank final interior line along with the content', () => {
  const lines = ['f(', 'a', '', ')'];
  const region = bracketRegion(lines, 1, 0, '(', ')', false);
  assert.ok(region);
  assert.deepEqual(applyRegion(lines, region, false).lines, ['f(', ')']);
});

test('off any block, the next opener and its match are used', () => {
  assert.deepEqual(
    bracketRegion(['f(x) y (z)'], 0, 6, '(', ')', false),
    r(0, 8, 9),
  );
});

test('cursor on the closer selects that block', () => {
  assert.deepEqual(bracketRegion(['f(x)'], 0, 3, '(', ')', false), r(0, 2, 3));
});

test('unbalanced brackets fail', () => {
  assert.equal(bracketRegion(['no brackets'], 0, 3, '(', ')', false), null);
  assert.equal(bracketRegion(['(open'], 0, 2, '(', ')', false), null);
});

test('a bracketed string does not pair with delimiters around it', () => {
  assert.deepEqual(
    bracketRegion(['f("a ) b" + x)'], 0, 1, '(', ')', false),
    r(0, 2, 13),
  );
});

test("a cursor inside a string pairs that string's own brackets, as in vim", () => {
  const lines = ['x("a (b)")'];
  assert.deepEqual(bracketRegion(lines, 0, 5, '(', ')', false), r(0, 6, 7));
  assert.deepEqual(bracketRegion(lines, 0, 6, '(', ')', false), r(0, 6, 7));
  assert.deepEqual(
    applyRegion(lines, bracketRegion(lines, 0, 5, '(', ')', false)!, false),
    { lines: ['x("a ()' + '")'], killed: 'b' },
  );
});
