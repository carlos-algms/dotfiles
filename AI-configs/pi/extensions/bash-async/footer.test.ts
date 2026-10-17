import assert from 'node:assert/strict';
import { test } from 'node:test';
import { footerLines, formatFooter } from './footer.ts';

test('formatFooter clears the entry when no job runs', () => {
  assert.equal(formatFooter(0), undefined);
});

test('formatFooter shows the count and the open hint', () => {
  assert.equal(formatFooter(1), '1 async running · → to inspect');
  assert.equal(formatFooter(3), '3 async running · → to inspect');
});

test('footerLines renders no line when no job runs', () => {
  assert.deepEqual(footerLines(0, 80), []);
});

test('footerLines left-aligns the text with no padding', () => {
  assert.deepEqual(footerLines(2, 50), ['2 async running · → to inspect']);
});

test('footerLines never exceeds the width', () => {
  assert.equal(footerLines(1, 10)[0]?.length, 10);
});
