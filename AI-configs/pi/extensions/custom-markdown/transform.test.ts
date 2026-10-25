import assert from 'node:assert/strict';
import { test } from 'node:test';
import { transformUserMarkdown } from './transform.ts';

const context = {
  messageType: 'user',
  isStreaming: false,
  availableWidth: 80,
} as const;

const cases = [
  ['ends a column-one quote', '> original\ncomment', '> original\n\ncomment'],
  [
    'keeps consecutive quoted lines',
    '> one\n> two\ncomment',
    '> one\n> two\n\ncomment',
  ],
  [
    'keeps existing blank separators',
    '> quote\n\ncomment',
    '> quote\n\ncomment',
  ],
  [
    'keeps whitespace-only separators',
    '> quote\n \t\ncomment',
    '> quote\n \t\ncomment',
  ],
  [
    'leaves indented quotes unchanged',
    '  > quote\ncomment',
    '  > quote\ncomment',
  ],
  [
    'leaves escaped markers unchanged',
    '\\> literal\ncomment',
    '\\> literal\ncomment',
  ],
  ['preserves CRLF', '> quote\r\ncomment\r\n', '> quote\r\n\r\ncomment\r\n'],
  ['preserves a final newline', '> quote\n', '> quote\n'],
  ['preserves empty input', '', ''],
  [
    'ends a quote before a fence',
    '> quote\n```ts\ncode\n```',
    '> quote\n\n```ts\ncode\n```',
  ],
] as const;

for (const [name, input, expected] of cases) {
  test(name, () => {
    const actual = transformUserMarkdown(input, context);
    assert.equal(actual, expected);
    assert.equal(transformUserMarkdown(actual, context), actual);
  });
}

for (const marker of ['`', '~']) {
  for (const length of [3, 4, 6]) {
    test(`preserves ${length}-character ${marker} fences and resumes after closing`, () => {
      const code = `${marker.repeat(length)}markdown\n> literal\nunchanged\n${marker.repeat(length + 1)}\n`;
      assert.equal(
        transformUserMarkdown(`${code}> quote\ncomment`, context),
        `${code}> quote\n\ncomment`,
      );
    });
  }

  test(`preserves unclosed ${marker} fences and rejects invalid closing lines`, () => {
    const other = marker === '`' ? '~' : '`';
    const input = `${marker.repeat(4)}\n${marker.repeat(3)}\n${other.repeat(4)}\n${marker.repeat(4)}text\n> literal\nunchanged`;
    assert.equal(transformUserMarkdown(input, context), input);
  });
}

test('does not treat inline backticks as a fence', () => {
  assert.equal(
    transformUserMarkdown('text ```\n> quote\ncomment', context),
    'text ```\n> quote\n\ncomment',
  );
});

test('rejects backticks in a backtick fence info string', () => {
  assert.equal(
    transformUserMarkdown('```a`b\n> quote\ncomment', context),
    '```a`b\n> quote\n\ncomment',
  );
});

for (const messageType of ['assistant', 'assistant-thinking'] as const) {
  test(`leaves ${messageType} content unchanged`, () => {
    const input = '> quote\ncomment';
    assert.equal(
      transformUserMarkdown(input, { ...context, messageType }),
      input,
    );
  });
}
