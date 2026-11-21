/**!
 * Modal Editor - vim-like modal editing example
 *
 * Usage: pi --extension ./examples/extensions/modal-editor.ts
 *
 * - Escape: insert → normal mode (in normal mode, aborts agent)
 * - i: normal → insert mode
 * - hjkl: navigation in normal mode
 * - ctrl+c, ctrl+d, etc. work in both modes
 */

// -----------------------------------------------------------------------------
// LOCAL FORK NOTES
// Source: @earendil-works/pi-coding-agent examples/extensions/modal-editor.ts
// Extensions below are kept in self-contained blocks (LOCAL ADDITIONS) and
// hooked into handleInput via a single one-line guard, so upstream changes
// merge cleanly. Do not modify upstream code blocks; extend through hooks.
// -----------------------------------------------------------------------------

import {
  CustomEditor,
  type ExtensionAPI,
} from '@earendil-works/pi-coding-agent';
import { matchesKey } from '@earendil-works/pi-tui';
import { type LineMotion, lineRange, removeLines } from './line-edits.ts';
import {
  type FindKind,
  type PendingOp,
  resolvePendingOperator,
} from './pending-operator.ts';
import { type Region, applyRegion, resolveTextObject } from './text-objects.ts';
import { expandFenceSnippet } from './vim-snippets.ts';
import { type WordScan, scanWord, wordScanRegion } from './word-motions.ts';

// Normal mode key mappings: key -> escape sequence (or null for mode switch)
// Annotate, not `satisfies`: these tables are indexed by an arbitrary key, and
// `satisfies` keeps the literal type (no index signature).
const NORMAL_KEYS: Record<string, string | null> = {
  h: '\x1b[D', // left
  j: '\x1b[B', // down
  k: '\x1b[A', // up
  l: '\x1b[C', // right
  '0': '\x01', // line start
  $: '\x05', // line end
  x: '\x1b[3~', // delete char
  i: null, // insert mode
  a: null, // append (insert + right)
};

// === LOCAL ADDITIONS ======================================================

// Cursor-only motions that give the region for gu/gU, and pi's primitive for
// each d/c motion, live in one table: pending-operator.ts MOTIONS.

// One-shot normal-mode commands: key -> sequences + optional mode switch.
// Composites built from pi's existing editor primitives.
const SIMPLE_KEYS: Record<string, { seqs: string[]; insert?: boolean }> = {
  A: { seqs: ['\x05'], insert: true }, // append at line end
  I: { seqs: ['\x01'], insert: true }, // insert at line start
  o: { seqs: ['\x05', '\n'], insert: true }, // open line below
  O: { seqs: ['\x01', '\n', '\x1b[A'], insert: true }, // open line above
  u: { seqs: ['\x1f'] }, // undo (pi binds ctrl+-; terminal-dependent)
};
// Hardware cursor shape per mode (DECSCUSR). Unfocused shape is the terminal's
// job (kitty: cursor_shape_unfocused hollow). Needs showHardwareCursor: true.
const CURSOR_SHAPE = {
  normal: '\x1b[2 q', // steady block
  insert: '\x1b[6 q', // steady bar
} satisfies Record<'normal' | 'insert', string>;

// f/F/t/T reuse pi's char-jump primitive (tui.editor.jumpForward/Backward).
// It searches across lines, unlike vim. ctrl+alt+] uses CSI-u (kitty-safe).
const JUMP_FORWARD = '\x1d'; // ctrl+]
const JUMP_BACKWARD = '\x1b[93;7u'; // ctrl+alt+]
const FLIP_FIND: Record<FindKind, FindKind> = {
  f: 'F',
  F: 'f',
  t: 'T',
  T: 't',
};

// pi's Editor keeps these private and its .d.ts erases their types, so the
// shapes are declared by hand. Reached only through ModalEditor.internals.
type EditorInternals = {
  state: { cursorLine: number; cursorCol: number };
  killRing: { push(text: string, opts: { prepend: boolean }): void };
  pastes: Map<number, string>;
  pasteCounter: number;
  expandPasteMarkers(text: string): string;
};

// A range of the old buffer that an edit replaces.
type ReplacedRange = { line: number; start: number; end: number };

// === END LOCAL ADDITIONS ==================================================

class ModalEditor extends CustomEditor {
  private mode: 'normal' | 'insert' = 'insert';
  // LOCAL: pending operator state. `g`, `dg`, `cg` wait for a second key; d/c
  // wait for a motion; dt/df/ct/cf and f/F/t/T wait for a target char.
  private pendingOp: PendingOp | null = null;

  // LOCAL: last f/F/t/T search, for ; and ,
  private lastFind: { kind: FindKind; ch: string } | null = null;

  // LOCAL: last cursor shape sent to the terminal, to write only on change.
  private cursorShape: string | null = null;

  handleInput(data: string): void {
    // LOCAL hook: handles operator-pending, extended motions, A/I, and
    // Esc-cancels-operator. Returns true when key was consumed.
    if (this.handleLocal(data)) {
      return;
    }

    // Escape toggles to normal mode, or passes through for app handling
    if (matchesKey(data, 'escape')) {
      if (this.mode === 'insert') {
        this.mode = 'normal';
      } else {
        super.handleInput(data); // abort agent, etc.
      }
      return;
    }

    // Insert mode: pass everything through
    if (this.mode === 'insert') {
      super.handleInput(data);
      return;
    }

    // Normal mode: check mapped keys
    if (data in NORMAL_KEYS) {
      const seq = NORMAL_KEYS[data];
      if (data === 'i') {
        this.mode = 'insert';
      } else if (data === 'a') {
        this.mode = 'insert';
        super.handleInput('\x1b[C'); // move right first
      } else if (seq) {
        super.handleInput(seq);
      }
      return;
    }

    // Pass control sequences (ctrl+c, etc.) to super, ignore printable chars.
    // 32 is the ASCII printable threshold (space and above); below 32 is C0
    // control codes which we want to forward to the base editor.
    if (data.length === 1 && data.charCodeAt(0) >= 32) {
      return;
    }
    super.handleInput(data);
  }

  // === LOCAL ADDITIONS ==================================================
  // All extended normal-mode logic lives here so upstream's handleInput stays
  // byte-identical to the example file.
  private handleLocal(data: string): boolean {
    // Insert mode keeps upstream passthrough, except Esc: like vim, it moves the
    // cursor onto the last typed char.
    if (this.mode === 'insert') {
      if (data === '\t') {
        const { line, col } = this.getCursor();
        const edit = expandFenceSnippet(this.getLines(), line, col);
        if (edit) {
          this.replaceBuffer(edit.lines, edit.line, edit.col, {
            replaced: [{ line, start: 0, end: col }],
          });
          return true;
        }
      }
      if (!matchesKey(data, 'escape')) {
        return false;
      }
      this.mode = 'normal';
      if (this.getCursor().col > 0) {
        super.handleInput('\x1b[D');
      }
      return true;
    }

    const escape = matchesKey(data, 'escape');
    const step = resolvePendingOperator(this.pendingOp, data, escape);
    this.pendingOp = typeof step === 'string' ? step : null;
    if (step !== null) {
      if (typeof step !== 'string') {
        switch (step.kind) {
          case 'cancel':
            break;
          case 'firstLine':
            this.gotoFirstLine();
            break;
          case 'find':
            this.lastFind = { kind: step.find, ch: step.target };
            this.findChar(step.find, step.target, false);
            break;
          case 'lineEdit':
            this.deleteLines(step.range, step.change);
            break;
          case 'motionEdit': {
            // Unlike Pi's backward primitives, dh and d0 do not join lines.
            const atStart = step.guardLineStart && this.getCursor().col === 0;
            if (step.forward) {
              this.forwardDelete(step.sequence, !step.change);
            } else if (!atStart) {
              super.handleInput(step.sequence);
            }
            if (step.change) {
              this.mode = 'insert';
            }
            break;
          }
          case 'scanEdit':
            this.scanEdit(step.scan, step.change);
            break;
          case 'textObject':
            this.applyTextObject(step.key, step.change, step.outer);
            break;
          case 'charEdit': {
            // One buffer edit avoids an undo snapshot for every character.
            const { line, col } = this.getCursor();
            const lines = this.getLines();
            const text = lines[line] ?? '';
            const idx = text.indexOf(step.target, col + 1);
            if (idx !== -1) {
              const endCol = step.inclusive ? idx + 1 : idx;
              const newLines = lines.slice();
              newLines[line] = text.slice(0, col) + text.slice(endCol);
              const edited = this.replaceBuffer(newLines, line, col, {
                replaced: [{ line, start: col, end: endCol }],
              });
              if (!edited) {
                break;
              }
              if (step.change) {
                this.mode = 'insert';
              } else {
                this.clampCursor();
              }
            }
            break;
          }
          case 'case': {
            const { upper } = step;
            const region =
              'scan' in step
                ? wordScanRegion(this.getLines(), this.getCursor(), step.scan)
                : this.motionRegion(step.sequences);
            this.transformCase(upper, region);
            break;
          }
        }
      }
      return true;
    }
    if (escape) {
      return false;
    }

    // ; and , repeat the last f/F/t/T (, reverses direction).
    if ((data === ';' || data === ',') && this.lastFind) {
      const { kind, ch } = this.lastFind;
      this.findChar(data === ';' ? kind : FLIP_FIND[kind], ch, true);
      return true;
    }

    if (data === 'G') {
      this.gotoLastLine();
      return true;
    }

    // S: substitute line (= cc).
    if (data === 'S') {
      this.deleteLines('current', true);
      return true;
    }

    // x D C s: forward deletes (= dl, d$, c$, cl).
    if (data === 'x' || data === 'D' || data === 'C' || data === 's') {
      const toLineEnd = data === 'D' || data === 'C';
      const change = data === 'C' || data === 's';
      this.forwardDelete(toLineEnd ? '\x0b' : '\x1b[3~', !change);
      if (change) {
        this.mode = 'insert';
      }
      return true;
    }

    // l and $: stop on the last char, not past it. pi's right wraps to the next
    // line, so l moves only inside the line. a is l-then-insert.
    if (data === 'l' || data === '$') {
      if (data === 'l') {
        this.stepRight();
      } else {
        super.handleInput('\x05');
      }
      this.clampCursor();
      return true;
    }
    if (data === 'a') {
      this.stepRight();
      this.mode = 'insert';
      return true;
    }

    // h: pi's left wraps to the previous line end (past the last char); vim
    // stops at col 0.
    if (data === 'h') {
      if (this.getCursor().col > 0) {
        super.handleInput('\x1b[D');
      }
      return true;
    }

    // w/B/e word motions: vim word rule, not pi's.
    if (
      data === 'w' ||
      data === 'b' ||
      data === 'e' ||
      data === 'W' ||
      data === 'B' ||
      data === 'E'
    ) {
      this.scanMotion(data);
      return true;
    }

    // J: join with the next line, one undo step. No-op on the last line.
    if (data === 'J') {
      const { line } = this.getCursor();
      const lines = this.getLines();
      if (line < lines.length - 1) {
        const cur = lines[line] ?? '';
        const nextTrim = (lines[line + 1] ?? '').trimStart();
        const sep =
          cur === '' ||
          /\s$/.test(cur) ||
          nextTrim === '' ||
          nextTrim.startsWith(')')
            ? ''
            : ' ';
        const joined = cur + sep + nextTrim;
        const newLines = lines.slice();
        newLines.splice(line, 2, joined);
        this.replaceBuffer(
          newLines,
          line,
          Math.max(Math.min(cur.length, joined.length - 1), 0),
          {
            replaced: [
              { line, start: cur.length, end: cur.length },
              {
                line: line + 1,
                start: 0,
                end: (lines[line + 1] ?? '').length - nextTrim.length,
              },
            ],
          },
        );
      }
      return true;
    }

    // p: paste kill ring after cursor (pi yank inserts at cursor).
    if (data === 'p') {
      this.stepRight();
      super.handleInput('\x19'); // ctrl+y
      this.clampCursor();
      return true;
    }

    // One-shot commands (A, I, o, O, u).
    const simple = SIMPLE_KEYS[data];
    if (simple) {
      for (const s of simple.seqs) {
        super.handleInput(s);
      }
      if (simple.insert) {
        this.mode = 'insert';
      }
      return true;
    }

    // ~ : toggle case of the grapheme under cursor, advance right.
    // Direct buffer edit (no key-sequence primitive); one undo step.
    if (data === '~') {
      const { line, col } = this.getCursor();
      const lines = [...this.getLines()];
      const lineText = lines[line] ?? '';
      const ch = [...new Intl.Segmenter().segment(lineText.slice(col))][0]
        ?.segment;
      if (ch !== undefined) {
        const toggled =
          ch === ch.toUpperCase() ? ch.toLowerCase() : ch.toUpperCase();
        lines[line] =
          lineText.slice(0, col) + toggled + lineText.slice(col + ch.length);
        const edited = this.replaceBuffer(lines, line, col + toggled.length, {
          replaced: [{ line, start: col, end: col + ch.length }],
        });
        if (edited) {
          this.clampCursor();
        }
      }
      return true;
    }

    return false;
  }

  // The only place that casts to pi's private fields.
  private get internals(): EditorInternals {
    return this as unknown as EditorInternals;
  }

  // Rewrite the buffer as one undo step and place the cursor. setText clears
  // pi's paste registry, so restore it or [paste #N] markers stop expanding on
  // submit. setText also skips the kill ring, so push killText directly.
  // `replaced` names the old-buffer ranges the edit touches: an edit whose
  // boundary falls strictly inside a live paste marker would corrupt it, so it
  // is dropped (returns false) and the caller skips its follow-up.
  private replaceBuffer(
    lines: string[],
    cursorLine: number,
    cursorCol: number,
    { kill, replaced = [] }: { kill?: string; replaced?: ReplacedRange[] } = {},
  ): boolean {
    if (!this.canReplace(replaced)) {
      return false;
    }
    const internals = this.internals;
    const savedPastes = new Map(internals.pastes);
    const savedCounter = internals.pasteCounter;
    const killed = kill && internals.expandPasteMarkers(kill);
    this.setText(lines.join('\n'));
    for (const [id, text] of savedPastes) {
      internals.pastes.set(id, text);
    }
    internals.pasteCounter = savedCounter;
    // pi has no public cursor setter. Safe after setText: UndoStack deep-clones.
    internals.state.cursorLine = cursorLine;
    internals.state.cursorCol = cursorCol;
    if (killed) {
      internals.killRing.push(killed, { prepend: false });
    }
    return true;
  }

  private canReplace(replaced: ReplacedRange[]): boolean {
    const old = this.getLines();
    return replaced.every(({ line, start, end }) =>
      this.pasteSpans(old[line] ?? '').every(
        ({ start: spanStart, end: spanEnd }) =>
          !(spanStart < start && start < spanEnd) &&
          !(spanStart < end && end < spanEnd),
      ),
    );
  }

  private pasteSpans(text: string): { start: number; end: number }[] {
    const { pastes } = this.internals;
    if (!pastes.size) {
      return [];
    }
    // Pi matches markers by ID even when a grapheme crosses the marker start.
    const spans: { start: number; end: number }[] = [];
    for (const match of text.matchAll(
      /\[paste #(\d+)( (\+\d+ lines|\d+ chars))?\]/g,
    )) {
      if (match.index !== undefined && pastes.has(Number(match[1]))) {
        spans.push({ start: match.index, end: match.index + match[0].length });
      }
    }
    return spans;
  }

  private lineLength(): number {
    return (this.getLines()[this.getCursor().line] ?? '').length;
  }

  // Right within the current line only; pi's right wraps to the next line.
  private stepRight(): void {
    if (this.getCursor().col < this.lineLength()) {
      super.handleInput('\x1b[C');
    }
  }

  // Vim keeps the normal-mode cursor on a char. pi allows col == line length.
  private clampCursor(): void {
    const { col } = this.getCursor();
    if (col > 0 && col === this.lineLength()) {
      super.handleInput('\x1b[D');
    }
  }

  // Run a forward-delete primitive as vim would: from the last char, never past
  // the end (pi's would join the next line), and nothing on an empty line.
  private forwardDelete(seq: string, clampAfter: boolean): void {
    if (this.lineLength() === 0) {
      return;
    }
    this.clampCursor();
    super.handleInput(seq);
    if (clampAfter) {
      this.clampCursor();
    }
  }

  // w/b/e and W/B/E: vim word motions, computed on the buffer instead of pi's
  // word primitives. Lowercase splits runs by character class; uppercase treats
  // a punctuation run and its neighbours as one WORD.
  private scanMotion(scan: WordScan): void {
    const target = scanWord(this.getLines(), this.getCursor(), scan);
    const { state } = this.internals;
    state.cursorLine = target.line;
    state.cursorCol = target.col;
    this.clampCursor();
  }

  // dw/cw/db/cb/de/ce and their WORD forms: the scan gives the region, then one
  // buffer rewrite. A motion that crosses the line edge stops there, so it never
  // joins lines. An empty region still enters insert for c, as vim does.
  private scanEdit(scan: WordScan, change: boolean): void {
    const lines = this.getLines();
    const region = wordScanRegion(lines, this.getCursor(), scan, change);
    if (!region) {
      if (change) {
        this.mode = 'insert';
      }
      return;
    }
    const { lines: newLines, killed } = applyRegion(lines, region, change);
    this.commitEdit(newLines, region.startLine, region.startCol, {
      kill: killed,
      change,
      replaced: [
        {
          line: region.startLine,
          start: region.startCol,
          end: region.startCol,
        },
        { line: region.endLine, start: region.endCol, end: region.endCol },
      ],
    });
  }

  // gg/G poke the cursor: Up on the first line at col 0 browses history, and
  // Down on the last line browses it too while a history entry is shown.
  private gotoFirstLine(): void {
    const { state } = this.internals;
    state.cursorLine = 0;
    state.cursorCol = 0;
  }

  private gotoLastLine(): void {
    const { state } = this.internals;
    state.cursorLine = this.getLines().length - 1;
    state.cursorCol = 0;
  }

  // dd/dj/dk/dG/dgg and cc/cj/ck/cG/cgg/S: linewise delete of the current
  // line, the current line plus the one below/above, or from the cursor line
  // to the last/first line. c leaves one empty line and enters insert. A
  // down/up range on the edge line is a no-op, as in vim.
  private deleteLines(range: LineMotion, change: boolean): void {
    const { line } = this.getCursor();
    const lines = this.getLines();
    const span = lineRange(lines.length, line, range);
    if (!span) {
      return;
    }
    const { lines: kept, killed } = removeLines(
      lines,
      span.first,
      span.last,
      change,
    );
    // Whole lines are removed, so no marker can be split.
    const edited = this.replaceBuffer(
      kept,
      Math.min(span.first, kept.length - 1),
      0,
      { kill: killed },
    );
    if (edited && change) {
      this.mode = 'insert';
    }
  }

  // di/da/ci/ca: compute the text-object region and apply delete/change to
  // it. d and c both push the region to the kill ring; c enters insert at
  // the region start. One undo step via replaceBuffer.
  private applyTextObject(obj: string, change: boolean, outer: boolean): void {
    const { line, col } = this.getCursor();
    const lines = this.getLines();
    const region = resolveTextObject(lines, line, col, obj, outer, (text) => {
      // Hide marker delimiters without moving the region's offsets.
      let masked = text;
      for (const { start, end } of this.pasteSpans(text)) {
        masked =
          masked.slice(0, start) + '\0'.repeat(end - start) + masked.slice(end);
      }
      return masked;
    });
    if (!region) {
      return;
    }
    // Empty inner block ("" or ()): vim aborts the delete; c still enters
    // insert between the delimiters. No buffer edit, so no undo snapshot.
    if (
      !region.linewise &&
      region.startLine === region.endLine &&
      region.startCol === region.endCol
    ) {
      if (change) {
        this.internals.state.cursorLine = region.startLine;
        this.internals.state.cursorCol = region.startCol;
        this.mode = 'insert';
      }
      return;
    }
    const { lines: newLines, killed } = applyRegion(lines, region, change);
    this.commitEdit(newLines, region.startLine, region.startCol, {
      kill: killed,
      change,
      replaced: [
        {
          line: region.startLine,
          start: region.startCol,
          end: region.startCol,
        },
        { line: region.endLine, start: region.endCol, end: region.endCol },
      ],
    });
  }

  // Shared tail of the region edits: abort leaves the buffer and mode alone,
  // otherwise place the cursor or enter insert.
  private commitEdit(
    lines: string[],
    line: number,
    col: number,
    {
      kill,
      change,
      replaced,
    }: { kill?: string; change: boolean; replaced: ReplacedRange[] },
  ): void {
    if (!this.replaceBuffer(lines, line, col, { kill, replaced })) {
      return;
    }
    if (change) {
      this.mode = 'insert';
    } else {
      this.clampCursor();
    }
  }

  // gu/gU: rewrite the line the region covers in one step. The region is already
  // clamped to one line, and the cursor ends at its start.
  private transformCase(upper: boolean, region: Region | null): void {
    if (!region) {
      return;
    }
    const lines = [...this.getLines()];
    const { startLine, startCol, endCol } = region;
    const lineText = lines[startLine] ?? '';
    const covered = lineText.slice(startCol, endCol);
    const changed = upper ? covered.toUpperCase() : covered.toLowerCase();
    if (changed === covered) {
      return;
    }
    lines[startLine] =
      lineText.slice(0, startCol) + changed + lineText.slice(endCol);
    this.replaceBuffer(lines, startLine, startCol, {
      replaced: [{ line: startLine, start: startCol, end: endCol }],
    });
  }

  // Region covered by a cursor-only motion, for gu/gU over pi's primitives.
  // pi wraps `h` / `l` across lines; a wrapped motion leaves no covered column
  // on this line, so it is a no-op here (vim cases the wrap target instead).
  private motionRegion(sequences: string[]): Region | null {
    const { state } = this.internals;
    const start = this.getCursor();
    for (const s of sequences) {
      super.handleInput(s);
    }
    const end = this.getCursor();
    state.cursorLine = start.line;
    state.cursorCol = start.col;
    if (end.line !== start.line) {
      return null;
    }
    const from = Math.min(start.col, end.col);
    const to = Math.max(start.col, end.col);
    if (from === to) {
      return null;
    }
    return {
      startLine: start.line,
      startCol: from,
      endLine: start.line,
      endCol: to,
    };
  }

  // Restore the terminal's default cursor shape (DECSCUSR 0) on shutdown.
  resetCursorShape(): void {
    this.tui.terminal.write('\x1b[0 q');
    this.cursorShape = null;
  }

  // f/F/t/T. Cursor unchanged after the jump means no match; t/T then stay put.
  // A repeated t/T steps past the adjacent target first, else `;` never moves.
  private findChar(kind: FindKind, ch: string, isRepeat: boolean): void {
    const forward = kind === 'f' || kind === 't';
    const till = kind === 't' || kind === 'T';
    const step = forward ? '\x1b[C' : '\x1b[D';
    const back = forward ? '\x1b[D' : '\x1b[C';
    const prestep = till && isRepeat;
    if (prestep) {
      super.handleInput(step);
    }
    const start = this.getCursor();
    super.handleInput(forward ? JUMP_FORWARD : JUMP_BACKWARD);
    super.handleInput(ch);
    const end = this.getCursor();
    if (end.line === start.line && end.col === start.col) {
      if (prestep) {
        super.handleInput(back);
      }
      return;
    }
    if (till) {
      super.handleInput(back);
    }
  }

  // Mode label embedded in the bottom border. Scroll indicator wins when shown.
  protected renderBottomBorder(width: number, hiddenLineCount: number): string {
    const label = ` ${this.mode === 'normal' ? 'NORMAL' : 'INSERT'} `;
    if (hiddenLineCount > 0 || width < label.length + 2) {
      return super.renderBottomBorder(width, hiddenLineCount);
    }
    return this.borderColor(`─${label}${'─'.repeat(width - label.length - 1)}`);
  }
  // === END LOCAL ADDITIONS ==============================================

  render(width: number): string[] {
    const lines = super.render(width);
    if (lines.length === 0) {
      return lines;
    }

    // LOCAL: sync hardware cursor shape with mode.
    const shape = CURSOR_SHAPE[this.mode];
    if (shape !== this.cursorShape) {
      this.cursorShape = shape;
      this.tui.terminal.write(shape);
    }

    return lines;
  }
}

export default function vimModePiExtension(pi: ExtensionAPI) {
  let editor: ModalEditor | undefined;

  pi.on('session_start', (_event, ctx) => {
    ctx.ui.setEditorComponent((tui, theme, kb) => {
      editor = new ModalEditor(tui, theme, kb);
      return editor;
    });
  });

  pi.on('session_shutdown', () => {
    editor?.resetCursorShape();
    editor = undefined;
  });
}
