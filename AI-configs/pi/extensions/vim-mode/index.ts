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
// Extra motions and operators. W/B/E collapse to w/b/e (pi has one word
// definition). e/E is approximated as word-right then left one char.
//
// IMPORTANT: pi's Editor.handleInput matches one keybinding per call. Compound
// sequences must be sent as separate array entries, not concatenated strings.
const MOTION_KEYS: Record<string, string[]> = {
	w: ["\x1b[1;3C"], // alt+right = word right
	W: ["\x1b[1;3C"],
	b: ["\x1b[1;3D"], // alt+left  = word left
	B: ["\x1b[1;3D"],
	e: ["\x1b[1;3C", "\x1b[D"],
	E: ["\x1b[1;3C", "\x1b[D"],
};

// Delete primitive applied when an operator (d/c) is followed by a motion.
// alt+letter uses CSI-u (\x1b[<cp>;3u) not legacy \x1b<letter>: pi's matcher
// rejects the legacy form when kitty keyboard protocol is active (kitty, wezterm,
// ghostty, foot, ...). CSI-u matches in both modes.
const DELETE_FOR_MOTION: Record<string, string> = {
	w: "\x1b[100;3u", // alt+d = delete word forward (codepoint 100 = 'd', mod 3 = alt)
	W: "\x1b[100;3u",
	e: "\x1b[100;3u", // alias of dw; pi has no "to end of word" primitive, eats trailing ws
	E: "\x1b[100;3u",
	b: "\x17", // ctrl+w = delete word backward (raw ctrl char, kitty-safe)
	B: "\x17",
	h: "\x7f", // backspace
	l: "\x1b[3~", // delete
	"0": "\x15", // ctrl+u = delete to line start
	$: "\x0b", // ctrl+k = delete to line end
};

// Sequences that clear the current line (used by dd/cc and S).
const CLEAR_LINE: string[] = ["\x01", "\x0b"]; // line start + delete to end

// One-shot normal-mode commands: key -> sequences + optional mode switch.
// Composites built from pi's existing editor primitives.
const SIMPLE_KEYS: Record<string, { seqs: string[]; insert?: boolean }> = {
	A: { seqs: ["\x05"], insert: true }, // append at line end
	I: { seqs: ["\x01"], insert: true }, // insert at line start
	D: { seqs: ["\x0b"] }, // delete to line end (= d$)
	C: { seqs: ["\x0b"], insert: true }, // change to line end (= c$)
	S: { seqs: CLEAR_LINE, insert: true }, // substitute line (= cc)
	s: { seqs: ["\x1b[3~"], insert: true }, // substitute char (= cl)
	o: { seqs: ["\x05", "\n"], insert: true }, // open line below
	O: { seqs: ["\x01", "\n", "\x1b[A"], insert: true }, // open line above
	u: { seqs: ["\x1f"] }, // undo (pi binds ctrl+-; terminal-dependent)
};
// === END LOCAL ADDITIONS ==================================================

class ModalEditor extends CustomEditor {
	private mode: "normal" | "insert" = "insert";
	// LOCAL: pending operator state. `g` is a two-key prefix (resolves to gu/gU).
	private pendingOp: "d" | "c" | "g" | "gu" | "gU" | "dt" | "df" | "ct" | "cf" | null = null;

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
		// Only intercepts in normal mode. Insert mode keeps upstream passthrough.
		if (this.mode !== "normal") return false;

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
			// `g` waits for u/U to become gu/gU. Anything else cancels.
			if (this.pendingOp === "g") {
				if (data === "u") this.pendingOp = "gu";
				else if (data === "U") this.pendingOp = "gU";
				else this.pendingOp = null;
				return true;
			}

			const op = this.pendingOp;
			this.pendingOp = null;

			// d/c: dd/cc clears line, t/f waits for target char, else apply delete
			// primitive for motion.
			if (op === "d" || op === "c") {
				if (data === op) {
					for (const s of CLEAR_LINE) super.handleInput(s);
					if (op === "c") this.mode = "insert";
					return true;
				}
				if (data === "t" || data === "f") {
					this.pendingOp = (op + data) as "dt" | "df" | "ct" | "cf";
					return true;
				}
				const seq = DELETE_FOR_MOTION[data];
				if (seq) {
					super.handleInput(seq);
					if (op === "c") this.mode = "insert";
				}
				return true; // swallow even on unknown motion, like vim
			}

			// dt/df/ct/cf: data is the target char. Single-line, forward only.
			// Uses setText for one undo step (pi's forward-delete pushes one
			// snapshot per char). Cursor is restored via direct state poke;
			// safe because pi's UndoStack deep-clones on push (structuredClone),
			// so mutating state after setText doesn't corrupt the snapshot.
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
						this.setText(newLines.join("\n"));
						const editorState = (this as unknown as {
							state: { cursorLine: number; cursorCol: number };
						}).state;
						editorState.cursorLine = line;
						editorState.cursorCol = col;
					}
				}
				if (op === "ct" || op === "cf") this.mode = "insert";
				return true;
			}

			// gu/gU: capture region via cursor diff, delete, re-insert transformed.
			if (op === "gu" || op === "gU") {
				const seq = DELETE_FOR_MOTION[data];
				if (seq) {
					const linesBefore = this.getLines();
					const { line: lineBefore } = this.getCursor();
					super.handleInput(seq);
					const linesAfter = this.getLines();
					const { col: colAfter } = this.getCursor();
					const oldLine = linesBefore[lineBefore] ?? "";
					const newLine = linesAfter[lineBefore] ?? "";
					const lenDiff = oldLine.length - newLine.length;
					if (lenDiff > 0) {
						const removed = oldLine.slice(colAfter, colAfter + lenDiff);
						const xform = op === "gu" ? removed.toLowerCase() : removed.toUpperCase();
						this.insertTextAtCursor(xform);
					}
				}
				return true;
			}

			return true;
		}

		// Start an operator.
		if (data === "d" || data === "c" || data === "g") {
			this.pendingOp = data;
			return true;
		}

		// One-shot commands (A, I, D, C, S, s, o, O, u).
		const simple = SIMPLE_KEYS[data];
		if (simple) {
			for (const s of simple.seqs) super.handleInput(s);
			if (simple.insert) this.mode = "insert";
			return true;
		}

		// ~ : toggle case of char under cursor, advance right.
		// Uses direct buffer access (no key-sequence primitive available).
		if (data === "~") {
			const { line, col } = this.getCursor();
			const ch = this.getLines()[line]?.[col];
			if (ch !== undefined) {
				const toggled = ch === ch.toUpperCase() ? ch.toLowerCase() : ch.toUpperCase();
				super.handleInput("\x1b[3~"); // delete char under cursor
				this.insertTextAtCursor(toggled); // insert toggled, cursor advances
			}
			return true;
		}

		// Extended word motions (w/W/b/B/e/E).
		const motion = MOTION_KEYS[data];
		if (motion) {
			for (const s of motion) super.handleInput(s);
			return true;
		}

		return false;
	}
	// === END LOCAL ADDITIONS ==============================================

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length === 0) return lines;

		// LOCAL: render mode label as a separate line below editor + autocomplete
		// list. super.render() emits autocomplete after the bottom border (see
		// pi-tui editor.js render()), so appending here keeps the label visually
		// pinned to the bottom regardless of the popup state.
		const label = this.mode === "normal" ? "NORMAL" : "INSERT";
		return [...lines, ` ${label}`];
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setEditorComponent((tui, theme, kb) => new ModalEditor(tui, theme, kb));
	});
}
