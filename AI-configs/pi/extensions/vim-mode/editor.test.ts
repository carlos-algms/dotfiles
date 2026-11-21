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

// EditorComponent hides getCursor; the concrete editor exposes it.
function cursor(editor: Editor): { line: number; col: number } {
  return (
    editor as unknown as { getCursor(): { line: number; col: number } }
  ).getCursor();
}

function send(editor: Editor, keys: Iterable<string>): void {
  for (const key of keys) {
    editor.handleInput(key);
  }
}

// Editor with text, in normal mode at the cursor one keys sequence leaves.
function normalMode(text: string, keys: string): Editor {
  const editor = createEditor();
  editor.setText(text);
  send(editor, ['\x1b', ...keys]);
  return editor;
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
  assert.equal(normalMode('one\ntwo', 'gglldl').getText(), 'on\ntwo');
});

test('cw changes to the end of the word and enters insert', () => {
  const editor = normalMode('foo bar', 'ggcwX');
  send(editor, '\x1b');
  assert.equal(editor.getText(), 'X bar');
});

test('b moves to the start of the previous word', () => {
  assert.deepEqual(cursor(normalMode('one two', 'gg$b')), { line: 0, col: 4 });
});

test('de deletes to the end of the word inclusive and never joins lines', () => {
  assert.equal(normalMode('one\ntwo', 'gglllde').getText(), 'on\ntwo');
  assert.equal(normalMode('foo bar', 'ggde').getText(), ' bar');
});

test('cE on the last word enters insert at the region start', () => {
  const editor = normalMode('one two', 'ggllllcEX');
  send(editor, '\x1b');
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

test('W and B move by whitespace-delimited WORD', () => {
  const editor = normalMode('foo.bar baz', 'ggW');
  assert.deepEqual(cursor(editor), { line: 0, col: 8 });
  send(editor, 'B');
  assert.deepEqual(cursor(editor), { line: 0, col: 0 });
});

test('B crosses to the previous line and W stops on an empty line', () => {
  const crossed = normalMode('one two\nthree\n\nfour', 'ggj0B');
  assert.deepEqual(cursor(crossed), { line: 0, col: 4 });
  const walked = normalMode('one two\nthree\n\nfour', 'ggW');
  assert.deepEqual(cursor(walked), { line: 0, col: 4 });
  send(walked, 'W');
  assert.deepEqual(cursor(walked), { line: 1, col: 0 });
  send(walked, 'W');
  assert.deepEqual(cursor(walked), { line: 2, col: 0 });
});

test('E ends a WORD, so a punctuation run counts as one', () => {
  const editor = normalMode('foo.bar baz', 'ggE');
  assert.deepEqual(cursor(editor), { line: 0, col: 6 });
  send(editor, 'E');
  assert.deepEqual(cursor(editor), { line: 0, col: 10 });
});

test('dW deletes the WORD and its trailing blanks, never joining lines', () => {
  assert.equal(normalMode('one   two', 'ggdW').getText(), 'two');
  assert.equal(normalMode('one\ntwo', 'ggdW').getText(), '\ntwo');
});

test('dB deletes back to the previous WORD and dE is inclusive', () => {
  assert.equal(normalMode('foo.bar baz', 'ggWdB').getText(), 'baz');
  assert.equal(normalMode('foo.bar baz', 'ggdE').getText(), ' baz');
});

test('cW keeps the blanks after the WORD', () => {
  const changed = normalMode('one two', 'ggcWX');
  send(changed, '\x1b');
  assert.equal(changed.getText(), 'X two');
  const spaced = normalMode('one  two', 'ggcWX');
  send(spaced, '\x1b');
  assert.equal(spaced.getText(), 'X  two');
});

test('gu and gU over a WORD include the WORD end', () => {
  assert.equal(normalMode('ONE TWO', 'ggguE').getText(), 'one TWO');
  assert.equal(normalMode('ONE', 'ggguW').getText(), 'one');
  const upper = normalMode('foo.bar baz', 'gggUW');
  assert.equal(upper.getText(), 'FOO.BAR baz');
  assert.deepEqual(cursor(upper), { line: 0, col: 0 });
});

test('w lands on the next word start, not on the blank before it', () => {
  const editor = normalMode('foo bar', 'ggw');
  assert.deepEqual(cursor(editor), { line: 0, col: 4 });
  const punct = normalMode('foo-bar baz', 'ggwww');
  assert.deepEqual(cursor(punct), { line: 0, col: 8 });
});

test('e keeps punctuation runs as words', () => {
  const editor = normalMode('foo-bar baz', 'ggeee');
  assert.deepEqual(cursor(editor), { line: 0, col: 6 });
  const quoted = normalMode('a"b c', 'gge');
  assert.deepEqual(cursor(quoted), { line: 0, col: 1 });
});

test('dw and de follow the lowercase scans', () => {
  assert.equal(normalMode('foo bar baz', 'ggdw').getText(), 'bar baz');
  assert.equal(normalMode('foo-bar baz', 'ggdw').getText(), '-bar baz');
  assert.equal(normalMode('foo-bar baz', 'ggde').getText(), '-bar baz');
});

test('cw on punctuation and db across words match vim', () => {
  const changed = normalMode('foo-bar baz', 'ggcwX');
  send(changed, '\x1b');
  assert.equal(changed.getText(), 'X-bar baz');
  assert.equal(normalMode('foo bar baz', 'ggWdb').getText(), 'bar baz');
});

test('cw on the last character of a word changes one character', () => {
  const changed = normalMode('ab cd', 'gglcwX');
  send(changed, '\x1b');
  assert.equal(changed.getText(), 'aX cd');
});

test('gu and gU over cursor-only motions stop at the line edge', () => {
  const toEnd = normalMode('AB CD', 'ggllgu$');
  assert.equal(toEnd.getText(), 'AB cd');
  assert.deepEqual(cursor(toEnd), { line: 0, col: 2 });
  const toStart = normalMode('AB CD', 'ggllgu0');
  assert.equal(toStart.getText(), 'ab CD');
  assert.deepEqual(cursor(toStart), { line: 0, col: 0 });
  assert.equal(normalMode('HELLO\nCDEW', 'ggj0guh').getText(), 'HELLO\nCDEW');
  assert.equal(normalMode('AB CD', 'gg0gu0').getText(), 'AB CD');
});

test('word deletes fill the kill ring, gu does not', () => {
  const ringed = normalMode('one two', 'ggdW');
  send(ringed, 'p');
  assert.equal(ringed.getText(), 'tone wo');
  const cased = normalMode('AAA\nbbb', 'ggddgU$');
  send(cased, 'p');
  assert.equal(cased.getText(), 'BAAABB');
});

test('a word delete rejects a boundary inside a paste marker', () => {
  const editor = createEditor();
  editor.setText('x');
  paste(editor, largePaste);
  const before = editor.getText();
  send(editor, ['\x1b', ...'llllllllll', ...'dw']);
  assert.equal(editor.getText(), before);
  assert.equal(editor.getExpandedText?.(), `x${largePaste}`);
});

test('c with an empty word region enters insert, d does nothing', () => {
  const changed = normalMode('abc\ndef', 'gg0jcb');
  send(changed, 'X');
  send(changed, '\x1b');
  assert.equal(changed.getText(), 'abc\nXdef');
  const deleted = normalMode('abc\ndef', 'gg0jdb');
  send(deleted, 'X');
  assert.equal(deleted.getText(), 'abc\ndef');
});
