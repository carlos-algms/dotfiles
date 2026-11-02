import assert from 'node:assert/strict';
import { test } from 'node:test';
import { visibleWidth } from '@earendil-works/pi-tui';
import { replaceFooterStats } from './render.ts';

const stats =
  '↑267k ↓43k R16M CH99.9% $2.547 (sub) 36.2%/500k (auto)                    model';

test('replaces only CH and context while retaining model alignment', () => {
  const result = replaceFooterStats(stats, 100, 52, 181000);
  assert.match(result, /CH52\.0%/);
  assert.match(result, /36\.2% \(181k\/500k\) \(auto\)/);
  assert.match(result, /^↑267k ↓43k R16M /);
  assert.match(result, /\$2\.547 \(sub\)/);
  assert.match(result, /  model$/);
  assert.equal(visibleWidth(result), visibleWidth(stats));
});

test('keeps unavailable values and absent fields unchanged', () => {
  assert.equal(replaceFooterStats(stats, 100, undefined, undefined), stats);
  assert.equal(replaceFooterStats(stats, 100, undefined, null), stats);
  assert.equal(
    replaceFooterStats('?/500k (auto)', 100, 52, null),
    '?/500k (auto)',
  );
  assert.equal(
    replaceFooterStats('no statistics', 100, 52, 181000),
    'no statistics',
  );
});

test('formats current tokens across supported scales, including zero', () => {
  for (const [tokens, expected] of [
    [0, '0'],
    [999, '999'],
    [1000, '1.0k'],
    [9999, '10.0k'],
    [10000, '10k'],
    [181000, '181k'],
    [1000000, '1.0M'],
  ] as const) {
    assert.equal(
      replaceFooterStats('36.2%/500k', 100, undefined, tokens),
      `36.2% (${expected}/500k)`,
    );
  }
});

test('handles colored statistics and respects narrow terminal widths', () => {
  const colored = '\x1b[2mCH99.9% \x1b[33m36.2%/500k (auto)\x1b[0m';
  const result = replaceFooterStats(colored, 100, 0, 181000);
  assert.match(result, /\x1b\[33m36\.2% \(181k\/500k\) \(auto\)\x1b\[0m/);
  assert.match(result, /CH0\.0%/);
  for (const width of [0, 1, 10, 35, 70]) {
    assert.ok(
      visibleWidth(replaceFooterStats(colored, width, 52, 181000)) <= width,
    );
    assert.ok(
      visibleWidth(replaceFooterStats(stats, width, 52, 181000)) <= width,
    );
  }
});
