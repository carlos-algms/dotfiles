import assert from 'node:assert/strict';
import { test } from 'node:test';
import { searchEmojis } from './match.ts';
import { fuzzy } from './test-fuzzy.ts';
import type { Emoji } from './types.ts';

const grin: Emoji = { emoji: '😀', label: 'grinning face', tags: ['smile'] };
const neutral: Emoji = {
  emoji: '😐️',
  label: 'neutral face',
  tags: ['indifference'],
};
const shrug: Emoji = {
  emoji: '🤷',
  label: 'person shrugging',
  tags: ['idk', 'dunno'],
};
const sadCat: Emoji = { emoji: '😿', label: 'crying cat', tags: ['smile'] };
const smiling: Emoji = { emoji: '😊', label: 'smiling face', tags: [] };
const all = [grin, neutral, shrug];

function find(
  emojis: Emoji[],
  query: string,
  recents: string[] = [],
  limit = 50,
): string[] {
  return searchEmojis(emojis, query, recents, fuzzy, limit).map((e) => e.emoji);
}

test('empty query lists everything in dataset order', () => {
  assert.deepEqual(find(all, ''), ['😀', '😐️', '🤷']);
});

test('empty query puts recents first, newest first, and ignores unknown ones', () => {
  assert.deepEqual(find(all, '', ['🤷', '🙈', '😐️']), ['🤷', '😐️', '😀']);
});

test('fuzzy-matches the name as a subsequence', () => {
  assert.deepEqual(find(all, 'shru'), ['🤷']);
  assert.deepEqual(find(all, 'neutral'), ['😐️']);
});

test('returns nothing when no name or tag matches', () => {
  assert.deepEqual(find(all, 'zzz'), []);
});

test('matches tags', () => {
  assert.deepEqual(find(all, 'idk'), ['🤷']);
});

test('ranks name matches above tag-only matches of the same kind', () => {
  const smileFace: Emoji = { emoji: '🙂', label: 'smile face', tags: [] };
  assert.deepEqual(find([sadCat, smileFace], 'smile'), ['🙂', '😿']);
});

test('ranks a literal substring above a looser subsequence match', () => {
  const ruler: Emoji = { emoji: '📏', label: 'straight ruler', tags: [] };
  assert.deepEqual(find([ruler, shrug], 'shru'), ['🤷', '📏']);
});

test('ranks a literal tag above a subsequence name match', () => {
  const tone: Emoji = { emoji: '🏾', label: 'medium-dark skin tone', tags: [] };
  assert.deepEqual(find([tone, shrug], 'idk'), ['🤷', '🏾']);
});

test('orders other matches by score, best first', () => {
  assert.deepEqual(find([grin, neutral], 'face'), ['😐️', '😀']);
});

test('puts matching recents first, even over a better score', () => {
  assert.deepEqual(find([neutral, grin], 'face', ['😀']), ['😀', '😐️']);
});

test('excludes recents that do not match the query', () => {
  assert.deepEqual(find(all, 'shru', ['😀']), ['🤷']);
});

test('caps the result count', () => {
  assert.deepEqual(find(all, '', [], 2), ['😀', '😐️']);
  assert.deepEqual(find(all, 'face', [], 1), ['😐️']);
});
