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
- Operators: `d{motion}` / `c{motion}` over `w` `b` `h` `l` `0` `$`;
  `dd` / `cc` for whole-line
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

### No tests

Personal fork, manually exercised. Add tests if the operator state machine
grows.

## Limitations

- No visual mode, no registers, no marks, no `.` repeat.
- No `f` / `t` / `F` / `T` char-search motions.
- No counts (e.g. `3w`, `5dd`).
- `g` prefix only resolves to `gu` / `gU`. `gg` / `G` not implemented.
- Word definition follows pi (single rule), not vim's word/WORD split.
