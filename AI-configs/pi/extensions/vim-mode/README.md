# vim-mode

Pi extension. Replaces pi's editor with a modal `vim`-like editor. Fork of pi's
`examples/extensions/modal-editor.ts` with local extensions for operators,
motions, and one-shot commands.

## What it does

- Two modes: `insert` (default) and `normal`. `Esc` toggles to normal; `i` /
  `a` return to insert.
- Mode indicator rendered on the editor's bottom border.
- Translates `vim` keys to pi's existing editor primitives (cursor moves,
  delete-word, delete-to-line-end, etc). Does not call pi's keybinding manager
  directly.

## Supported keys (normal mode)

- Motions: `h` `j` `k` `l` `0` `$` `w` `W` `b` `B` `e` `E`
- Edits: `x` `D` `C` `S` `s` `~`
- Operators: `d{motion}` / `c{motion}` over `w` `b` `e` `h` `l` `0` `$`;
  `dd` / `cc` for whole-line
- Char search: `dt<char>` / `df<char>` / `ct<char>` / `cf<char>`
  (forward, single-line)
- Case ops: `gu{motion}` / `gU{motion}`
- Open lines: `o` `O`
- Append: `A` `I`
- Undo: `u` (terminal-dependent, see caveats)

## Installation

Symlinked via the whole-dir extension link set up in
`AI-Config-README.md`. Reload pi or restart.

## Caveats

- `u` (undo) maps to `\x1f` (ctrl+_), pi's default undo binding. Some terminals
  do not emit ctrl+_ at all; mapping falls flat there.
- Word motions (`w` `b` `e` and their capital variants) rely on pi binding
  `alt+left` / `alt+right` to word-step. If those are remapped, motions break.
- `dw` / `dW` send the kitty CSI-u form `\x1b[100;3u` for `alt+d`, not the
  legacy `\x1bd`. pi's key matcher (`pi-tui/dist/keys.js`) rejects
  `\x1b<letter>` when the kitty keyboard protocol is active (kitty, wezterm,
  ghostty, foot). CSI-u matches in both modes.
- `e` / `E` is approximated as `word-right` then `left-one-char` because pi has
  no native "end-of-word" primitive. Off-by-one near punctuation runs is
  possible.
- Upper-case word motions (`W` `B` `E`) collapse to lower-case behavior. pi has
  one word definition; vim's WORD (whitespace-delimited) is not exposed.

## Fork merge contract

This file is a fork of upstream's example. To keep upstream merges clean:

- Upstream code blocks must stay byte-identical. Modifying them breaks merge.
- All local logic lives between
  `// === LOCAL ADDITIONS ===` / `// === END LOCAL ADDITIONS ===` markers.
- New behavior hooks into `handleInput` via the single `handleLocal()` guard at
  the top of the override; do not interleave.

Upstream source:
`@earendil-works/pi-coding-agent examples/extensions/modal-editor.ts`.

## ADRs

### Direct escape sequences instead of pi's keybinding manager

`CustomEditor` overrides `handleInput(data)` which receives raw input strings.
Translating vim keys to pi's underlying escape sequences (e.g. `\x1b[1;3C` for
word-right) bypasses the keybinding indirection and keeps the extension small.
Trade-off: user-overridden keybindings in pi don't propagate here. Acceptable
for personal use; revisit if the editor needs to honor custom bindings.

### Two-key `g` prefix held as state

`pendingOp` state holds `g` waiting for `u` / `U`. Same machinery handles `d`
and `c` operators waiting for a motion. One state slot rather than a parser.

### `~` uses direct buffer mutation

No editor primitive for "toggle case at cursor", so `~` reads via `getLines()`
/ `getCursor()`, deletes the char, and inserts the toggled char. Direct buffer
mutation is the cheapest path; the alternative (sequence-only) would need a
new pi primitive.

### `dt`/`df` use `setText` + direct cursor state poke

pi's `handleForwardDelete` pushes one undo snapshot per char, so the natural
implementation (loop N forward-deletes) creates N undo steps. To get one undo
step, `dt`/`df` build the modified buffer text and call `setText` (single
snapshot), then restore the cursor via direct mutation of `state.cursorLine`
/ `state.cursorCol`. Safe because pi's `UndoStack.push` deep-clones via
`structuredClone`, so post-`setText` mutation doesn't corrupt the snapshot.
This is the only place we touch private editor state; lifted instead of
walking visual lines with key sequences (which break under word wrap).

### No tests

Personal fork, manually exercised. Add tests if the operator state machine
grows.

## Limitations

- No visual mode, no registers, no marks, no `.` repeat.
- No standalone `f` / `t` / `F` / `T` char-search motions (only as `d`/`c`
  operator targets, forward only).
- No `i` / `a` text objects (`diw`, `da"`, etc).
- No counts (e.g. `3w`, `5dd`).
- `g` prefix only resolves to `gu` / `gU`. `gg` / `G` not implemented.
- `d{motion}` / `c{motion}` only over `w` `b` `e` `h` `l` `0` `$` (plus `dd`/`cc`).
- `de` / `dE` are aliased to `dw` / `dW` (pi has no "to end of word" primitive).
  They eat trailing whitespace, unlike real vim `de`.
- `dt`/`df`/`ct`/`cf` are forward + single-line only. `dT`/`dF` (backward) not
  implemented.
- Word definition follows pi (single rule), not vim's word/WORD split.
