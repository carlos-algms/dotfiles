import assert from 'node:assert/strict';
import { test } from 'node:test';
import { isEditorFocused, shouldOpenPanel } from './input.ts';

const READY = {
  panelOpen: false,
  editorText: '',
  editorFocused: true,
  jobCount: 1,
};

test('shouldOpenPanel opens from an empty focused prompt with a job', () => {
  assert.equal(shouldOpenPanel(READY), true);
});

test('shouldOpenPanel passes the key through in every other case', () => {
  assert.equal(shouldOpenPanel({ ...READY, panelOpen: true }), false);
  assert.equal(shouldOpenPanel({ ...READY, editorText: 'a' }), false);
  assert.equal(shouldOpenPanel({ ...READY, editorFocused: false }), false);
  assert.equal(shouldOpenPanel({ ...READY, jobCount: 0 }), false);
});

test('isEditorFocused accepts only an object with the editor methods', () => {
  const editor = {
    render: () => [],
    invalidate: () => {},
    handleInput: () => {},
    getText: () => '',
    setText: () => {},
  };
  const { getText: _getText, ...notAnEditor } = editor;

  assert.equal(isEditorFocused(editor), true);
  assert.equal(isEditorFocused(notAnEditor), false);
  assert.equal(isEditorFocused(undefined), false);
  assert.equal(isEditorFocused('editor'), false);
});
