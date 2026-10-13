import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { after, before, test } from 'node:test';
import {
  MAX_RECENTS,
  loadRecents,
  pushRecent,
  recentsPath,
  recordRecent,
  saveRecents,
} from './recents.ts';

let dir = '';

before(async () => {
  dir = await mkdtemp(join(tmpdir(), 'emoji-picker-'));
});

after(async () => {
  await rm(dir, { recursive: true, force: true });
});

test('recentsPath uses XDG_STATE_HOME when it is absolute', () => {
  assert.equal(
    recentsPath({ XDG_STATE_HOME: '/x/state' }, '/home/me'),
    '/x/state/pi/emoji-picker/recent.json',
  );
});

test('recentsPath falls back to ~/.local/state when XDG_STATE_HOME is unset, empty or relative', () => {
  const expected = '/home/me/.local/state/pi/emoji-picker/recent.json';
  assert.equal(recentsPath({}, '/home/me'), expected);
  assert.equal(recentsPath({ XDG_STATE_HOME: '' }, '/home/me'), expected);
  assert.equal(
    recentsPath({ XDG_STATE_HOME: 'rel/state' }, '/home/me'),
    expected,
  );
});

test('pushRecent puts the newest first', () => {
  assert.deepEqual(pushRecent(['😀'], '🤷'), ['🤷', '😀']);
});

test('pushRecent moves an existing emoji to the front without duplicating it', () => {
  assert.deepEqual(pushRecent(['😀', '🤷', '😐️'], '🤷'), ['🤷', '😀', '😐️']);
});

test('pushRecent keeps at most MAX_RECENTS entries, dropping the oldest', () => {
  const full = Array.from({ length: MAX_RECENTS }, (_, i) => `e${i}`);
  const next = pushRecent(full, 'new');
  assert.equal(next.length, MAX_RECENTS);
  assert.equal(next[0], 'new');
  assert.equal(next.at(-1), `e${MAX_RECENTS - 2}`);
});

test('saveRecents creates missing directories and loadRecents reads the list back', async () => {
  const path = join(dir, 'nested', 'state', 'recent.json');
  await saveRecents(path, ['🤷', '😀']);
  assert.deepEqual(await loadRecents(path), ['🤷', '😀']);
});

test('loadRecents returns an empty list for a missing file', async () => {
  assert.deepEqual(await loadRecents(join(dir, 'missing.json')), []);
});

test('loadRecents returns an empty list for corrupt JSON', async () => {
  const path = join(dir, 'corrupt.json');
  await writeFile(path, '{not json');
  assert.deepEqual(await loadRecents(path), []);
});

test('loadRecents ignores non-string entries and non-array JSON', async () => {
  const mixed = join(dir, 'mixed.json');
  await writeFile(mixed, JSON.stringify(['😀', 5, null]));
  assert.deepEqual(await loadRecents(mixed), ['😀']);
  const object = join(dir, 'object.json');
  await writeFile(object, '{"a":1}');
  assert.deepEqual(await loadRecents(object), []);
});

test('recordRecent merges with picks written by another session', async () => {
  const path = join(dir, 'shared', 'recent.json');
  await saveRecents(path, ['😀']);
  // Two sessions started from the same snapshot; each records one pick.
  await recordRecent(path, '🤷');
  const merged = await recordRecent(path, '😐️');
  assert.deepEqual(merged, ['😐️', '🤷', '😀']);
  assert.deepEqual(await loadRecents(path), ['😐️', '🤷', '😀']);
});

test('recordRecent creates the file when it does not exist', async () => {
  const path = join(dir, 'fresh', 'recent.json');
  assert.deepEqual(await recordRecent(path, '🤷'), ['🤷']);
  assert.deepEqual(await loadRecents(path), ['🤷']);
});

test('saveRecents writes JSON', async () => {
  const path = join(dir, 'plain.json');
  await saveRecents(path, ['😀']);
  assert.deepEqual(JSON.parse(await readFile(path, 'utf8')), ['😀']);
});
