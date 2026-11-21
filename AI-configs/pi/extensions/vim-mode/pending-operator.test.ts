import assert from 'node:assert/strict';
import { test } from 'node:test';
import { resolvePendingOperator } from './pending-operator.ts';

type Case = [
  ...Parameters<typeof resolvePendingOperator>,
  ReturnType<typeof resolvePendingOperator>,
];

function check(cases: Case[]): void {
  for (const [pending, key, escape, expected] of cases) {
    assert.deepEqual(
      resolvePendingOperator(pending, key, escape),
      expected,
      JSON.stringify({ pending, key, escape }),
    );
  }
}

test('unrelated keys and control sequences pass through; escape cancels pending input', () => {
  check([
    [null, 'j', false, null],
    [null, '\x1b', true, null],
    ['d', '\x1b', true, { kind: 'cancel' }],
    ['ci', '\x1b[A', false, null],
    ['f', '\x03', false, null],
    ['d', 'z', false, { kind: 'cancel' }],
    ['g', 'x', false, { kind: 'cancel' }],
    ['dg', 'x', false, { kind: 'cancel' }],
  ]);
});

test('g resolves navigation, range edits, and case changes', () => {
  check([
    [null, 'g', false, 'g'],
    ['g', 'g', false, { kind: 'firstLine' }],
    ['g', 'u', false, 'gu'],
    ['g', 'U', false, 'gU'],
    ['gu', 'w', false, { kind: 'case', scan: 'w', upper: false }],
    ['gU', '$', false, { kind: 'case', sequences: ['\x05'], upper: true }],
    ['gu', 'W', false, { kind: 'case', scan: 'W', upper: false }],
    ['gU', 'B', false, { kind: 'case', scan: 'B', upper: true }],
    ['gu', 'z', false, { kind: 'cancel' }],
    ['d', 'g', false, 'dg'],
    ['c', 'g', false, 'cg'],
    ['dg', 'g', false, { kind: 'lineEdit', range: 'toFirst', change: false }],
    ['cg', 'g', false, { kind: 'lineEdit', range: 'toFirst', change: true }],
  ]);
});

test('d and c resolve line, motion, and text-object edits', () => {
  check([
    [null, 'd', false, 'd'],
    [null, 'c', false, 'c'],
    ['d', 'd', false, { kind: 'lineEdit', range: 'current', change: false }],
    ['c', 'G', false, { kind: 'lineEdit', range: 'toLast', change: true }],
    ['d', 'j', false, { kind: 'lineEdit', range: 'down', change: false }],
    ['c', 'j', false, { kind: 'lineEdit', range: 'down', change: true }],
    ['c', 'k', false, { kind: 'lineEdit', range: 'up', change: true }],
    ['d', 'i', false, 'di'],
    ['c', 'a', false, 'ca'],
    [
      'di',
      'w',
      false,
      { kind: 'textObject', key: 'w', outer: false, change: false },
    ],
    [
      'ca',
      'B',
      false,
      { kind: 'textObject', key: 'B', outer: true, change: true },
    ],
  ]);
});

test('cursor-only motions map to their delete primitive and forward flag', () => {
  const rows = [
    ['h', '\x7f', false, true],
    ['l', '\x1b[3~', true, false],
    ['0', '\x15', false, true],
    ['$', '\x0b', true, false],
  ] as const;
  for (const [motion, sequence, forward, guardLineStart] of rows) {
    for (const [pending, change] of [
      ['d', false],
      ['c', true],
    ] as const) {
      assert.deepEqual(
        resolvePendingOperator(pending, motion, false),
        {
          kind: 'motionEdit',
          sequence,
          forward,
          guardLineStart,
          change,
        },
        `${pending}${motion}`,
      );
    }
  }
});

test('every word motion maps to its scan, for d and c', () => {
  for (const motion of ['w', 'b', 'e', 'W', 'B', 'E']) {
    for (const [pending, change] of [
      ['d', false],
      ['c', true],
    ] as const) {
      assert.deepEqual(
        resolvePendingOperator(pending, motion, false),
        { kind: 'scanEdit', scan: motion, change },
        `${pending}${motion}`,
      );
    }
  }
});
test('finds and character edits take one printable target', () => {
  check([
    [null, 'T', false, 'T'],
    ['T', 'x', false, { kind: 'find', find: 'T', target: 'x' }],
    ['F', 'xy', false, { kind: 'cancel' }],
    ['d', 't', false, 'dt'],
    ['c', 'f', false, 'cf'],
    [
      'dt',
      'x',
      false,
      { kind: 'charEdit', target: 'x', inclusive: false, change: false },
    ],
    [
      'cf',
      ' ',
      false,
      { kind: 'charEdit', target: ' ', inclusive: true, change: true },
    ],
    ['cf', '', false, { kind: 'cancel' }],
  ]);
});
