import assert from 'node:assert/strict';
import { test } from 'node:test';
import { pruneTags } from './tags.ts';

test('keeps tags the label does not contain', () => {
  assert.deepEqual(pruneTags('person shrugging', ['idk', 'dunno']), [
    'idk',
    'dunno',
  ]);
});

test('drops a tag that is a word of the label', () => {
  assert.deepEqual(pruneTags('grinning face', ['face', 'smile']), ['smile']);
});

test('drops a singular tag contained in a plural label word', () => {
  assert.deepEqual(pruneTags('smiling face with hearts', ['heart', 'love']), [
    'love',
  ]);
});

test('compares case-insensitively', () => {
  assert.deepEqual(pruneTags('Japanese “here” button', ['japanese', 'sign']), [
    'sign',
  ]);
});

test('drops a tag that is contained in another tag', () => {
  assert.deepEqual(pruneTags('person', ['shrug', 'shrugging', 'idk']), [
    'shrugging',
    'idk',
  ]);
});

test('drops duplicate tags, keeping the first', () => {
  assert.deepEqual(pruneTags('person', ['idk', 'maybe', 'idk']), [
    'idk',
    'maybe',
  ]);
});
