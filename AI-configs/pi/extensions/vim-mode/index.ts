/**
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

import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey } from "@earendil-works/pi-tui";
import { expandFenceSnippet } from "./vim-snippets.ts";

// Normal mode key mappings: key -> escape sequence (or null for mode switch)
const NORMAL_KEYS: Record<string, string | null> = {
	h: "\x1b[D", // left
	j: "\x1b[B", // down
	k: "\x1b[A", // up
	l: "\x1b[C", // right
	"0": "\x01", // line start
	$: "\x05", // line end
	x: "\x1b[3~", // delete char
	i: null, // insert mode
	a: null, // append (insert + right)
};

// === LOCAL ADDITIONS ======================================================
// Extra motions and operators. W/B collapse to w/b (pi has one word
// definition). pi's word-right ends at the END of the word (emacs forward-word),
// so w lands on the word end, not the next word start. w/W: see wordForward();
// e/E: see wordEnd().
//
// IMPORTANT: pi's Editor.handleInput matches one keybinding per call. Compound
// sequences must be sent as separate array entries, not concatenated strings.
const MOTION_KEYS: Record<string, string[]> = {
	b: ["\x1b[1;3D"], // alt+left  = word left
	B: ["\x1b[1;3D"],
};

// Delete primitive applied when an operator (d/c) is followed by a motion.
// alt+letter uses CSI-u (\x1b[<cp>;3u) not legacy \x1b<letter>: pi's matcher
// rejects the legacy form when kitty keyboard protocol is active (kitty, wezterm,
// ghostty, foot, ...). CSI-u matches in both modes.
const DELETE_FOR_MOTION: Record<string, string> = {
	w: "\x1b[100;3u", // alt+d = delete word forward (codepoint 100 = 'd', mod 3 = alt)
	W: "\x1b[100;3u",
	e: "\x1b[100;3u", // alias of dw: deletes leading ws + word, leaves trailing ws
	E: "\x1b[100;3u",
	b: "\x17", // ctrl+w = delete word backward (raw ctrl char, kitty-safe)
	B: "\x17",
	h: "\x7f", // backspace
	l: "\x1b[3~", // delete
	"0": "\x15", // ctrl+u = delete to line start
	$: "\x0b", // ctrl+k = delete to line end
};

// Motions whose delete primitive acts forward from the cursor. pi's forward
// delete at end of line joins the next line, so these go through forwardDelete.
const FORWARD_DELETE_MOTIONS = new Set(["w", "W", "e", "E", "l", "$"]);

// Cursor-only motions that give the region for gu/gU. Same boundaries as the
// DELETE_FOR_MOTION primitives (e/E alias w/W), but nothing is deleted.
const CASE_MOTION: Record<string, string[]> = {
	w: ["\x1b[1;3C"],
	W: ["\x1b[1;3C"],
	e: ["\x1b[1;3C"],
	E: ["\x1b[1;3C"],
	b: ["\x1b[1;3D"],
	B: ["\x1b[1;3D"],
	h: ["\x1b[D"],
	l: ["\x1b[C"],
	"0": ["\x01"],
	$: ["\x05"],
};

// One-shot normal-mode commands: key -> sequences + optional mode switch.
// Composites built from pi's existing editor primitives.
const SIMPLE_KEYS: Record<string, { seqs: string[]; insert?: boolean }> = {
	A: { seqs: ["\x05"], insert: true }, // append at line end
	I: { seqs: ["\x01"], insert: true }, // insert at line start
	o: { seqs: ["\x05", "\n"], insert: true }, // open line below
	O: { seqs: ["\x01", "\n", "\x1b[A"], insert: true }, // open line above
	u: { seqs: ["\x1f"] }, // undo (pi binds ctrl+-; terminal-dependent)
};
// Hardware cursor shape per mode (DECSCUSR). Unfocused shape is the terminal's
// job (kitty: cursor_shape_unfocused hollow). Needs showHardwareCursor: true.
const CURSOR_SHAPE = {
	normal: "\x1b[2 q", // steady block
	insert: "\x1b[6 q", // steady bar
} satisfies Record<"normal" | "insert", string>;


// f/F/t/T reuse pi's char-jump primitive (tui.editor.jumpForward/Backward).
// It searches across lines, unlike vim. ctrl+alt+] uses CSI-u (kitty-safe).
type FindKind = "f" | "F" | "t" | "T";
const JUMP_FORWARD = "\x1d"; // ctrl+]
const JUMP_BACKWARD = "\x1b[93;7u"; // ctrl+alt+]
const FLIP_FIND: Record<FindKind, FindKind> = { f: "F", F: "f", t: "T", T: "t" };
function isFindKind(s: string): s is FindKind {
	return s in FLIP_FIND;
}

// pi's Editor keeps these private and its .d.ts erases their types, so the
// shapes are declared by hand. Reached only through ModalEditor.internals.
type EditorInternals = {
	state: { cursorLine: number; cursorCol: number };
	killRing: { push(text: string, opts: { prepend: boolean }): void };
	pastes: Map<number, string>;
	pasteCounter: number;
};
// === END LOCAL ADDITIONS ==================================================

class ModalEditor extends CustomEditor {
	private mode: "normal" | "insert" = "insert";
	// LOCAL: pending operator state. `g`, `dg`, `cg` wait for a second key; d/c
	// wait for a motion; dt/df/ct/cf and f/F/t/T wait for a target char.
	private pendingOp:
		| "d" | "c" | "g" | "gu" | "gU" | "dt" | "df" | "ct" | "cf" | "dg" | "cg" | FindKind | null = null;
	// LOCAL: last f/F/t/T search, for ; and ,
	private lastFind: { kind: FindKind; ch: string } | null = null;
	// LOCAL: last cursor shape sent to the terminal, to write only on change.
	private cursorShape: string | null = null;

	handleInput(data: string): void {
		// LOCAL hook: handles operator-pending, extended motions, A/I, and
		// Esc-cancels-operator. Returns true when key was consumed.
		if (this.handleLocal(data)) return;

		// Escape toggles to normal mode, or passes through for app handling
		if (matchesKey(data, "escape")) {
			if (this.mode === "insert") {
				this.mode = "normal";
			} else {
				super.handleInput(data); // abort agent, etc.
			}
			return;
		}

		// Insert mode: pass everything through
		if (this.mode === "insert") {
			super.handleInput(data);
			return;
		}

		// Normal mode: check mapped keys
		if (data in NORMAL_KEYS) {
			const seq = NORMAL_KEYS[data];
			if (data === "i") {
				this.mode = "insert";
			} else if (data === "a") {
				this.mode = "insert";
				super.handleInput("\x1b[C"); // move right first
			} else if (seq) {
				super.handleInput(seq);
			}
			return;
		}

		// Pass control sequences (ctrl+c, etc.) to super, ignore printable chars.
		// 32 is the ASCII printable threshold (space and above); below 32 is C0
		// control codes which we want to forward to the base editor.
		if (data.length === 1 && data.charCodeAt(0) >= 32) return;
		super.handleInput(data);
	}

	// === LOCAL ADDITIONS ==================================================
	// All extended normal-mode logic lives here so upstream's handleInput stays
	// byte-identical to the example file.
	private handleLocal(data: string): boolean {
		// Insert mode keeps upstream passthrough, except Esc: like vim, it moves the
		// cursor onto the last typed char.
		if (this.mode === "insert") {
			if (data === "\t") {
				const { line, col } = this.getCursor();
				const edit = expandFenceSnippet(this.getLines(), line, col);
				if (edit) {
					this.replaceBuffer(edit.lines, edit.line, edit.col);
					return true;
				}
			}
			if (!matchesKey(data, "escape")) return false;
			this.mode = "normal";
			if (this.getCursor().col > 0) super.handleInput("\x1b[D");
			return true;
		}

		// Esc cancels a pending operator instead of aborting the agent.
		if (matchesKey(data, "escape")) {
			if (this.pendingOp) {
				this.pendingOp = null;
				return true;
			}
			return false;
		}

		// Resolve pending operators.
		if (this.pendingOp) {
			// Control keys and escape sequences (ctrl+c, enter, arrows) cancel the
			// operator and still reach pi.
			if (data.charCodeAt(0) < 32) {
				this.pendingOp = null;
				return false;
			}

			// `g` waits for u/U/g to become gu/gU/gg. Anything else cancels.
			if (this.pendingOp === "g") {
				if (data === "g") {
					this.pendingOp = null;
					this.gotoFirstLine();
				} else if (data === "u") this.pendingOp = "gu";
				else if (data === "U") this.pendingOp = "gU";
				else this.pendingOp = null;
				return true;
			}

			// f/F/t/T: data is the target char.
			if (isFindKind(this.pendingOp)) {
				const kind = this.pendingOp;
				this.pendingOp = null;
				if (data.length === 1 && data.charCodeAt(0) >= 32) {
					this.lastFind = { kind, ch: data };
					this.findChar(kind, data, false);
				}
				return true;
			}

			const op = this.pendingOp;
			this.pendingOp = null;

			// d/c: dd/cc clears line, t/f waits for target char, else apply delete
			// primitive for motion.
			if (op === "d" || op === "c") {
				if (data === op) {
					this.deleteLines("current", op === "c");
					return true;
				}
				if (data === "t" || data === "f") {
					this.pendingOp = (op + data) as "dt" | "df" | "ct" | "cf";
					return true;
				}
				if (data === "g") {
					this.pendingOp = op === "d" ? "dg" : "cg";
					return true;
				}
				if (data === "G") {
					this.deleteLines("toLast", op === "c");
					return true;
				}
				const seq = DELETE_FOR_MOTION[data];
				if (seq) {
					// Backward primitives at col 0 would join the previous line; vim does
					// nothing there (db still joins, as in vim).
					const nothingBefore = (data === "h" || data === "0") && this.getCursor().col === 0;
					if (FORWARD_DELETE_MOTIONS.has(data)) {
						this.forwardDelete(seq, op === "d");
					} else if (!nothingBefore) {
						super.handleInput(seq);
					}
					if (op === "c") this.mode = "insert";
				}
				return true; // swallow even on unknown motion, like vim
			}

			// dgg/cgg: second g completes the range. Anything else cancels.
			if (op === "dg" || op === "cg") {
				if (data === "g") {
					this.deleteLines("toFirst", op === "cg");
				}
				return true;
			}

			// dt/df/ct/cf: data is the target char. Single-line, forward only.
			// Uses replaceBuffer for one undo step (pi's forward-delete pushes one
			// snapshot per char).
			if (op === "dt" || op === "df" || op === "ct" || op === "cf") {
				if (data.length === 1 && data.charCodeAt(0) >= 32) {
					const { line, col } = this.getCursor();
					const lines = this.getLines();
					const lineText = lines[line] ?? "";
					const idx = lineText.indexOf(data, col + 1);
					if (idx !== -1) {
						const inclusive = op === "df" || op === "cf";
						const endCol = inclusive ? idx + 1 : idx;
						const newLines = lines.slice();
						newLines[line] = lineText.slice(0, col) + lineText.slice(endCol);
						this.replaceBuffer(newLines, line, col);
						if (op === "ct" || op === "cf") {
							this.mode = "insert";
						} else {
							this.clampCursor();
						}
					}
				}
				return true; // no match: stay in normal mode, like vim
			}

			// gu/gU: transform the region the motion covers.
			if (op === "gu" || op === "gU") {
				this.transformCase(data, op === "gU");
				return true;
			}

			return true;
		}

		// Start an operator.
		if (data === "d" || data === "c" || data === "g") {
			this.pendingOp = data;
			return true;
		}
		if (isFindKind(data)) {
			this.pendingOp = data;
			return true;
		}

		// ; and , repeat the last f/F/t/T (, reverses direction).
		if ((data === ";" || data === ",") && this.lastFind) {
			const { kind, ch } = this.lastFind;
			this.findChar(data === ";" ? kind : FLIP_FIND[kind], ch, true);
			return true;
		}

		if (data === "G") {
			this.gotoLastLine();
			return true;
		}

		// S: substitute line (= cc).
		if (data === "S") {
			this.deleteLines("current", true);
			return true;
		}

		// x D C s: forward deletes (= dl, d$, c$, cl).
		if (data === "x" || data === "D" || data === "C" || data === "s") {
			const toLineEnd = data === "D" || data === "C";
			const change = data === "C" || data === "s";
			this.forwardDelete(toLineEnd ? "\x0b" : "\x1b[3~", !change);
			if (change) this.mode = "insert";
			return true;
		}

		// l and $: stop on the last char, not past it. pi's right wraps to the next
		// line, so l moves only inside the line. a is l-then-insert.
		if (data === "l" || data === "$") {
			if (data === "l") {
				this.stepRight();
			} else {
				super.handleInput("\x05");
			}
			this.clampCursor();
			return true;
		}
		if (data === "a") {
			this.stepRight();
			this.mode = "insert";
			return true;
		}

		// h: pi's left wraps to the previous line end (past the last char); vim
		// stops at col 0.
		if (data === "h") {
			if (this.getCursor().col > 0) {
				super.handleInput("\x1b[D");
			}
			return true;
		}

		if (data === "w" || data === "W") {
			this.wordForward();
			return true;
		}

		if (data === "e" || data === "E") {
			this.wordEnd();
			return true;
		}

		// p: paste kill ring after cursor (pi yank inserts at cursor).
		if (data === "p") {
			this.stepRight();
			super.handleInput("\x19"); // ctrl+y
			this.clampCursor();
			return true;
		}

		// One-shot commands (A, I, o, O, u).
		const simple = SIMPLE_KEYS[data];
		if (simple) {
			for (const s of simple.seqs) super.handleInput(s);
			if (simple.insert) this.mode = "insert";
			return true;
		}

		// ~ : toggle case of the grapheme under cursor, advance right.
		// Direct buffer edit (no key-sequence primitive); one undo step.
		if (data === "~") {
			const { line, col } = this.getCursor();
			const lines = [...this.getLines()];
			const lineText = lines[line] ?? "";
			const ch = [...new Intl.Segmenter().segment(lineText.slice(col))][0]?.segment;
			if (ch !== undefined) {
				const toggled = ch === ch.toUpperCase() ? ch.toLowerCase() : ch.toUpperCase();
				lines[line] = lineText.slice(0, col) + toggled + lineText.slice(col + ch.length);
				this.replaceBuffer(lines, line, col + toggled.length);
				this.clampCursor();
			}
			return true;
		}

		// Extended word motions (w/W/b/B/e/E).
		const motion = MOTION_KEYS[data];
		if (motion) {
			for (const s of motion) super.handleInput(s);
			this.clampCursor();
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
	private replaceBuffer(lines: string[], cursorLine: number, cursorCol: number, killText?: string): void {
		const internals = this.internals;
		const savedPastes = new Map(internals.pastes);
		const savedCounter = internals.pasteCounter;
		this.setText(lines.join("\n"));
		for (const [id, text] of savedPastes) {
			internals.pastes.set(id, text);
		}
		internals.pasteCounter = savedCounter;
		// pi has no public cursor setter. Safe after setText: UndoStack deep-clones.
		internals.state.cursorLine = cursorLine;
		internals.state.cursorCol = cursorCol;
		if (killText) {
			internals.killRing.push(killText, { prepend: false });
		}
	}

	private lineLength(): number {
		return (this.getLines()[this.getCursor().line] ?? "").length;
	}

	// Right within the current line only; pi's right wraps to the next line.
	private stepRight(): void {
		if (this.getCursor().col < this.lineLength()) {
			super.handleInput("\x1b[C");
		}
	}

	// Vim keeps the normal-mode cursor on a char. pi allows col == line length.
	private clampCursor(): void {
		const { col } = this.getCursor();
		if (col > 0 && col === this.lineLength()) {
			super.handleInput("\x1b[D");
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

	// w/W: pi's word-right, kept on the last char. On a line's last char that
	// would stay put, so step past it and cross to the next line's first word
	// (an empty next line is a stop, as in vim). No next line: stay.
	private wordForward(): void {
		const start = this.getCursor();
		super.handleInput("\x1b[1;3C");
		this.clampCursor();
		const end = this.getCursor();
		if (end.line !== start.line || end.col !== start.col) {
			return;
		}
		super.handleInput("\x1b[C");
		super.handleInput("\x1b[1;3C");
		if (this.getCursor().line !== start.line && this.lineLength() > 0) {
			super.handleInput("\x1b[1;3C");
		}
		this.clampCursor();
	}

	// Word-right until the cursor is on a non-empty line, or cannot move.
	private skipEmptyLines(): void {
		while (this.lineLength() === 0) {
			const before = this.getCursor();
			super.handleInput("\x1b[1;3C");
			const after = this.getCursor();
			if (after.line === before.line && after.col === before.col) {
				return;
			}
		}
	}

	// e/E: end of the current or next word. pi's word-right ends at the word end,
	// so one step left lands on the last letter. From a last letter that is a
	// no-op, so step past it and retry. If word-right wraps to the next line it
	// stops at col 0: skip empty lines, then go once more to the first word's end.
	private wordEnd(): void {
		const start = this.getCursor();
		for (const stepFirst of [false, true]) {
			if (stepFirst) {
				super.handleInput("\x1b[C");
			}
			const from = this.getCursor();
			super.handleInput("\x1b[1;3C");
			if (this.getCursor().line !== from.line) {
				this.skipEmptyLines();
				super.handleInput("\x1b[1;3C");
			}
			super.handleInput("\x1b[D");
			const end = this.getCursor();
			if (end.line !== start.line || end.col !== start.col) {
				break;
			}
		}
		this.clampCursor();
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

	// dd/dG/dgg and cc/cG/cgg/S: linewise delete of the current line, or from the
	// cursor line to the last/first line. c leaves one empty line and enters insert.
	private deleteLines(range: "toLast" | "toFirst" | "current", change: boolean): void {
		const { line } = this.getCursor();
		const lines = this.getLines();
		const first = range === "toFirst" ? 0 : line;
		const last = range === "toLast" ? lines.length - 1 : line;
		const rest = [...lines.slice(0, first), ...(change ? [""] : []), ...lines.slice(last + 1)];
		const kept = rest.length > 0 ? rest : [""];
		this.replaceBuffer(kept, Math.min(first, kept.length - 1), 0, lines.slice(first, last + 1).join("\n"));
		if (change) {
			this.mode = "insert";
		}
	}

	// gu/gU: move the cursor over the motion to find the region, restore the
	// cursor, then rewrite the line in one step. Cross-line motions stop at the
	// line edge. Cursor ends at the region start, as in vim.
	private transformCase(motion: string, upper: boolean): void {
		const seqs = CASE_MOTION[motion];
		if (!seqs) {
			return;
		}
		const { state } = this.internals;
		const start = this.getCursor();
		for (const s of seqs) {
			super.handleInput(s);
		}
		const end = this.getCursor();
		state.cursorLine = start.line;
		state.cursorCol = start.col;
		const lines = [...this.getLines()];
		const lineText = lines[start.line] ?? "";
		let from = Math.min(start.col, end.col);
		let to = Math.max(start.col, end.col);
		if (end.line < start.line) {
			from = 0;
			to = start.col;
		} else if (end.line > start.line) {
			from = start.col;
			to = lineText.length;
		}
		const region = lineText.slice(from, to);
		const changed = upper ? region.toUpperCase() : region.toLowerCase();
		if (changed === region) {
			return;
		}
		lines[start.line] = lineText.slice(0, from) + changed + lineText.slice(to);
		this.replaceBuffer(lines, start.line, from);
	}

	// Restore the terminal's default cursor shape (DECSCUSR 0) on shutdown.
	resetCursorShape(): void {
		this.tui.terminal.write("\x1b[0 q");
		this.cursorShape = null;
	}

	// f/F/t/T. Cursor unchanged after the jump means no match; t/T then stay put.
	// A repeated t/T steps past the adjacent target first, else `;` never moves.
	private findChar(kind: FindKind, ch: string, isRepeat: boolean): void {
		const forward = kind === "f" || kind === "t";
		const till = kind === "t" || kind === "T";
		const step = forward ? "\x1b[C" : "\x1b[D";
		const back = forward ? "\x1b[D" : "\x1b[C";
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
		const label = ` ${this.mode === "normal" ? "NORMAL" : "INSERT"} `;
		if (hiddenLineCount > 0 || width < label.length + 2) {
			return super.renderBottomBorder(width, hiddenLineCount);
		}
		return this.borderColor(`─${label}${"─".repeat(width - label.length - 1)}`);
	}
	// === END LOCAL ADDITIONS ==============================================

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length === 0) return lines;

		// LOCAL: sync hardware cursor shape with mode.
		const shape = CURSOR_SHAPE[this.mode];
		if (shape !== this.cursorShape) {
			this.cursorShape = shape;
			this.tui.terminal.write(shape);
		}

		return lines;
	}
}

export default function (pi: ExtensionAPI) {
	let editor: ModalEditor | undefined;
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setEditorComponent((tui, theme, kb) => {
			editor = new ModalEditor(tui, theme, kb);
			return editor;
		});
	});
	pi.on("session_shutdown", () => {
		editor?.resetCursorShape();
		editor = undefined;
	});
}
