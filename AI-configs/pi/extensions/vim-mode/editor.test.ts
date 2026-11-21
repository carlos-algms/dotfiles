import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { registerHooks } from 'node:module';
import { test } from 'node:test';
import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent';

// Resolve the same Pi release that the extension type-checks against.
const config = new URL('../../tsconfig.json', import.meta.url);
const paths = readFileSync(config, 'utf8');
const packagePath = paths.match(
  /"@earendil-works\/pi-coding-agent":\s*\[\s*"([^"]+)"/,
)?.[1];
assert.ok(packagePath);
const packages = new URL('../', new URL(`${packagePath}/`, config));
const aliases: Record<string, string> = {
  '@earendil-works/pi-coding-agent':
    'pi-coding-agent/dist/modes/interactive/components/custom-editor.js',
  '@earendil-works/pi-tui': 'pi-tui/dist/index.js',
  '@earendil-works/pi-coding-agent/dist/core/keybindings.js':
    'pi-coding-agent/dist/core/keybindings.js',
};
const hooks = registerHooks({
  resolve(id, context, next) {
    const entry = aliases[id];
    return next(entry ? new URL(entry, packages).href : id, context);
  },
});
const { default: register } = await import('./index.ts');
const { KeybindingsManager } =
  await import('@earendil-works/pi-coding-agent/dist/core/keybindings.js');
hooks.deregister();

type Factory = NonNullable<
  Parameters<ExtensionContext['ui']['setEditorComponent']>[0]
>;
type Editor = ReturnType<Factory>;

function plain(text: string): string {
  return text;
}

function createEditor(): Editor {
  let editor: Editor | undefined;
  const ui = {
    setEditorComponent(factory: Factory) {
      const tui = {
        terminal: {
          columns: 80,
          write() {},
        },
        requestRender() {},
      } as unknown as Parameters<Factory>[0];
      editor = factory(
        tui,
        {
          borderColor: plain,
          selectList: {
            selectedPrefix: plain,
            selectedText: plain,
            description: plain,
            scrollInfo: plain,
            noMatch: plain,
          },
        },
        new KeybindingsManager(),
      );
    },
  };
  register({
    on(
      event: string,
      handler: (event: object, ctx: { ui: typeof ui }) => void,
    ) {
      if (event === 'session_start') {
        handler({}, { ui });
      }
    },
  } as unknown as ExtensionAPI);
  assert.ok(editor);
  return editor;
}

function send(editor: Editor, keys: Iterable<string>): void {
  for (const key of keys) {
    editor.handleInput(key);
  }
}

function paste(editor: Editor, text: string): void {
  editor.handleInput(`\x1b[200~${text}\x1b[201~`);
}

const largePaste = 'a'.repeat(1001);

test('bracket objects ignore a live paste marker on another line', () => {
  const editor = createEditor();
  editor.setText('notes\n');
  paste(editor, largePaste);
  assert.match(editor.getText(), /\[paste #1 \d+ chars\]/);
  send(editor, ['\x1b', ...'ggdi[']);
  assert.equal(editor.getExpandedText?.(), `notes\n${largePaste}`);
});

test('text objects protect a paste marker after a grapheme prepend character', () => {
  const editor = createEditor();
  editor.setText('\u0600');
  paste(editor, largePaste);
  send(editor, ['\x1b', ...'0diw']);
  assert.equal(editor.getExpandedText?.(), `\u0600${largePaste}`);
  send(editor, 'di[');
  assert.equal(editor.getExpandedText?.(), `\u0600${largePaste}`);
});

test('dh deletes left of the cursor and is a no-op at column 0', () => {
  const editor = createEditor();
  editor.setText('abc');
  send(editor, ['\x1b', ...'ggdh']);
  assert.equal(editor.getText(), 'abc');
  send(editor, [...'lldh']);
  assert.equal(editor.getText(), 'ac');
  send(editor, ['\x1b', ...'ggd0']);
  assert.equal(editor.getText(), 'ac');
});

test('dl at the last char deletes it without joining the next line', () => {
  const editor = createEditor();
  editor.setText('one\ntwo');
  send(editor, ['\x1b', ...'gglldl']);
  assert.equal(editor.getText(), 'on\ntwo');
});

test('cw changes to the end of the word and enters insert', () => {
  const editor = createEditor();
  editor.setText('foo bar');
  send(editor, ['\x1b', ...'ggcwX', '\x1b']);
  assert.equal(editor.getText(), 'X bar');
});

test('de deletes to the end of the word inclusive and never joins lines', () => {
  const lineEnd = createEditor();
  lineEnd.setText('one\ntwo');
  send(lineEnd, ['\x1b', ...'gglllde']);
  assert.equal(lineEnd.getText(), 'on\ntwo');
  const word = createEditor();
  word.setText('foo bar');
  send(word, ['\x1b', ...'ggde']);
  assert.equal(word.getText(), ' bar');
});

test('cE on the last word enters insert at the region start', () => {
  const editor = createEditor();
  editor.setText('one two');
  send(editor, ['\x1b', ...'ggllllcEX', '\x1b']);
  assert.equal(editor.getText(), 'one X');
});

test('an empty inner block deletes nothing and c enters insert inside it', () => {
  const editor = createEditor();
  editor.setText('()');
  send(editor, ['\x1b', ...'0ldi(']);
  assert.equal(editor.getText(), '()');
  send(editor, [...'ci(Q', '\x1b']);
  assert.equal(editor.getText(), '(Q)');
});

test('deleting an enclosing bracket object preserves the paste payload for yank and undo', () => {
  const editor = createEditor();
  editor.setText('[\n');
  paste(editor, largePaste);
  send(editor, ['\n', ']', '\x1b', ...'ggdi[']);
  assert.equal(editor.getText(), '[\n]');
  send(editor, 'u');
  assert.equal(editor.getExpandedText?.(), `[\n${largePaste}\n]`);
  send(editor, 'ggdi[p');
  assert.equal(editor.getText(), `[\n]${largePaste}`);
});

test('ciw inserts at the selection start and undoes typing before deletion', () => {
  const editor = createEditor();
  editor.setText('foo bar');
  send(editor, ['\x1b', ...'ggciwNEW', '\x1b']);
  assert.equal(editor.getText(), 'NEW bar');
  send(editor, 'u');
  assert.equal(editor.getText(), ' bar');
  send(editor, 'u');
  assert.equal(editor.getText(), 'foo bar');
});

test('edge ck is a no-op and dj deletes two lines in one undo step', () => {
  const editor = createEditor();
  editor.setText('one\ntwo\nthree');
  send(editor, ['\x1b', ...'ggck']);
  assert.equal(editor.getText(), 'one\ntwo\nthree');
  send(editor, 'dj');
  assert.equal(editor.getText(), 'three');
  send(editor, 'u');
  assert.equal(editor.getText(), 'one\ntwo\nthree');
});
