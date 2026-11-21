# vim-mode

Pi extension. Replaces pi's editor with a modal `vim`-like editor. Fork of pi's
`examples/extensions/modal-editor.ts` with local extensions for operators,
motions, and one-shot commands.

## What it does

- Two modes: `insert` (default) and `normal`. `Esc` toggles to normal and moves
  the cursor onto the last typed char, as in vim; `i` / `a` return to insert.
- Mode label embedded in the editor's bottom border. The scroll indicator
  replaces it while the editor is scrolled.
- Cursor shape per mode: bar in insert, block in normal. Uses the hardware
  cursor (`showHardwareCursor: true` required; pi then hides its own fake
  cursor). Unfocused shape comes from the terminal (kitty
  `cursor_shape_unfocused`, default `hollow`).
- Translates `vim` keys to pi's existing editor primitives (cursor moves,
  delete-word, delete-to-line-end, etc). Does not call pi's keybinding manager
  directly.

## Supported keys (normal mode)

- Motions: `h` `j` `k` `l` `0` `$` `w` `W` `b` `B` `e` `E` `gg` `G` (both land
  on column 0)
- Edits: `x` `D` `C` `S` `s` `~`
- Operators: `d{motion}` / `c{motion}` over `w` `W` `b` `B` `e` `E` `h` `l` `0`
  `$`
- Linewise: `dd` deletes the line, `cc` / `S` empty it and enter insert. `dj` /
  `dk` / `cj` / `ck` delete (or empty and retype) the current line plus the line
  below / above; on the buffer edge they are a no-op, as in vim. `dG` / `dgg` /
  `cG` / `cgg` cover the cursor line to the last or first line. `ggdG` empties
  the buffer. Undo restores the deleted lines in one step; undo replacement
  typing first after a change. `c` leaves one empty line
- Char search motions: `f` `F` `t` `T` with `;` / `,` repeat. Built on pi's
  char-jump (`ctrl+]` / `ctrl+alt+]`), so they search across lines
- Paste: `p` pastes pi's kill ring after the cursor, inline (not linewise). Word
  and line deletes fill it (`dw` `de` `db` `d0` `d$` `D` `C` `dd` `cc` `S` `dj`
  `dk` `cj` `ck` `dG` `dgg` `cG` `cgg`, and text-object deletes `diw` etc); `x`,
  `dh`, `dl`, `dt`, `df`, `gu`, `gU`, `~` do not
- Char search operators: `dt<char>` / `df<char>` / `ct<char>` / `cf<char>`
  (forward, single-line)
- Text objects: press `d` (delete) or `c` (change), then `i` (inside) or `a`
  (around), then an object key:
  - `w` / `W`: a run of whitespace, ASCII punctuation, or other text. `aw` takes
    adjacent whitespace but does not extend a word selection back into the
    indent. From whitespace, `iw` takes the run and `aw` adds the next run
  - `"`, `'`, or `` ` ``: a quote pair on the current line. `i` excludes the
    quotes; `a` includes them and adjacent whitespace
  - `(`, `[`, `{`, `<`, their closers, or `b` / `B`: a bracket pair. `a`
    includes the delimiters; `i` excludes them. In `f(\n  arg\n)`, `di(` removes
    the whole `arg` line and `ci(` leaves one empty line. In `f(\n  arg)`, `di(`
    removes only the selected characters
  - Both operators fill the kill ring. `c` enters insert at the region start.
    Undo restores the deletion in one step; undo replacement typing first
- Case ops: `gu{motion}` / `gU{motion}`
- Open lines: `o` `O`
- Join: `J` inserts one space (none after trailing whitespace; empty or
  `)`-starting next line adds none), strips the next line's leading whitespace,
  one undo step
- Append: `A` `I`
- Undo: `u` (terminal-dependent, see caveats)

## Installation

Symlinked via the whole-dir extension link set up in `AI-Config-README.md`.
Reload pi or restart.

## Caveats

- `u` (undo) maps to `\x1f` (ctrl+_), pi's default undo binding. Some terminals
  do not emit ctrl+_ at all; mapping falls flat there.
- Word motions (`w` `b` `e` and their capital variants) rely on pi binding
  `alt+left` / `alt+right` to word-step. If those are remapped, motions break.
- `dw` / `dW` send the kitty CSI-u form `\x1b[100;3u` for `alt+d`, not the
  legacy `\x1bd`. pi's key matcher (`pi-tui/dist/keys.js`) rejects
  `\x1b<letter>` when the kitty keyboard protocol is active (kitty, wezterm,
  ghostty, foot). CSI-u matches in both modes.
- pi's word-right goes to the END of the word (emacs forward-word), so `w` / `W`
  land on the word end, not the next word start as in vim. On a line's last char
  they cross to the next line's first word (an empty line is a stop).
- `e` / `E` is `word-right` then `left-one-char`, because pi has no native
  "end-of-word" primitive. From a word's last letter that is a no-op, so it
  steps right and retries, crossing and skipping empty lines. Punctuation runs
  follow pi's word rule and can differ from vim.
- `dw` / `dW` delete leading whitespace plus the word and leave the trailing
  space, unlike vim's `dw`.
- Upper-case word motions (`W` `B` `E`) collapse to lower-case behavior. pi has
  one word definition; vim's WORD (whitespace-delimited) is not exposed.

## Fork merge contract

This file is a fork of upstream's example. To keep upstream merges clean:

- Upstream code blocks stay semantically identical, except the intentional
  divergences below. Style-only drift (repo prettier, braces on single-statement
  `if`) is reapplied on each merge, not hand-merged.
- Local logic lives between `// === LOCAL ADDITIONS ===` /
  `// === END LOCAL ADDITIONS ===` markers.
- New behavior hooks into `handleInput` via the `handleLocal()` guard at the top
  of the override (a comment plus `if (this.handleLocal(data)) return;`); do not
  interleave.

Intentional divergences outside the markers (re-apply on each upstream merge):

- `LOCAL FORK NOTES` comment block above the imports
- Imports: no `truncateToWidth` / `visibleWidth`; adds local editing helpers
- Class fields `pendingOp`, `lastFind`, `cursorShape` on `ModalEditor`
- The `handleLocal()` hook (comment plus `if` line) at the top of `handleInput`
- Comment above the printable-char guard in `handleInput` is reworded
- `render()`: the upstream border-label append is replaced by cursor-shape sync;
  the label now comes from the `renderBottomBorder` override
- Default export: keeps the editor instance and resets the cursor shape on
  `session_shutdown`

Upstream source:
`@earendil-works/pi-coding-agent examples/extensions/modal-editor.ts`.

## ADRs

### Direct escape sequences instead of pi's keybinding manager

`CustomEditor` overrides `handleInput(data)` which receives raw input strings.
Translating vim keys to pi's underlying escape sequences (e.g. `\x1b[1;3C` for
word-right) bypasses the keybinding indirection and keeps the extension small.
Trade-off: user-overridden keybindings in pi don't propagate here. Acceptable
for personal use; revisit if the editor needs to honor custom bindings.

### Operator prefixes held as one state slot

`pendingOp` holds one prefix. `resolvePendingOperator` in `pending-operator.ts`
turns that prefix plus the next key into a step without touching the editor. `g`
waits for `u` / `U` / `g`. The same resolver handles `d` and `c` waiting for a
motion, `dg` / `cg` waiting for the second `g`, `dt`/`df`/`ct`/`cf` and
`f`/`F`/`t`/`T` waiting for a target char, and `di`/`da`/`ci`/`ca` waiting for
the object char.

### Text objects compute regions directly

Same pattern as `gu` / `dt` for the buffer write: no pi primitive exists, so
`text-objects.ts` computes a region (word run, quote pair, bracket pair) and
`applyRegion` removes it. `line-edits.ts` handles line ranges and removes whole
lines for both line motions and text objects. `index.ts` applies the edit,
updates the kill ring, and sets the cursor.

### `~` uses direct buffer mutation

No editor primitive for "toggle case at cursor", so `~` reads via `getLines()` /
`getCursor()` (one grapheme, via `Intl.Segmenter`) and rewrites the line through
`replaceBuffer`. The alternative (sequence-only) would need a new pi primitive.
`gu` / `gU` work the same way: a cursor-only motion finds the region, then one
`replaceBuffer` call rewrites it. Delete-then-reinsert was dropped: it took two
undo steps and clobbered the kill ring.

### Buffer edits use `replaceBuffer` + private field access

pi's `handleForwardDelete` pushes one undo snapshot per char, so the natural
implementation (loop N forward-deletes) creates N undo steps. Edits that need
one undo step (`dt`/`df`/`ct`/`cf`, `dd`/`cc`/`S`, `dG`/`dgg`/`cG`/`cgg`,
`dj`/`dk`/`cj`/`ck`, `di`/`da`/`ci`/`ca`, `gu`/`gU`, `~`) build the new lines
and call `replaceBuffer`:

- `setText` for a single snapshot
- restore pi's paste registry (`pastes`, `pasteCounter`), which `setText`
  clears; without it `[paste #N]` markers are sent as literal text
- set the cursor via `state.cursorLine` / `state.cursorCol`. Safe because pi's
  `UndoStack.push` deep-clones via `structuredClone`
- `killRing.push` for edits that delete text, since `setText` skips the ring.
  The kill text goes through `internals.expandPasteMarkers` first, so `p`
  inserts the pasted payload rather than a `[paste #N]` marker. Edits that go
  through pi's own primitives instead (`x` `dw` `dh` `dl` `D` `C`) push the raw
  buffer text, marker included

`gg` / `G` also set the cursor directly: `Up` on the first line at col 0 and
`Down` on the last line (while browsing history) navigate history instead.

All private access (`state`, `killRing`, `pastes`, `pasteCounter`, and the
`expandPasteMarkers` method) goes through one cast in `ModalEditor.internals`,
with hand-written types because pi's `.d.ts` erases private member types. A pi
rename fails at runtime, not in `tsc`.

## Testing

From the repo root, use Node.js 24 and the Pi release pinned in `tsconfig.json`:

```bash
node --test 'AI-configs/pi/extensions/vim-mode/*.test.ts'
```

The suite covers pure helpers and sends key sequences to Pi's editor without a
terminal.

## Limitations

- No visual mode, no marks, no `.` repeat.
- No `P`, `y`, or registers: `p` only reads pi's kill ring.
- `f` / `F` / `t` / `T` cross lines (pi's jump primitive); vim stays on the
  line. `d`/`c` with `f`/`t` are forward and single-line only.
- Text objects: brackets scan the whole buffer. They skip delimiters inside live
  paste markers, double-quoted strings on one line, and single-character
  literals. With the cursor strictly inside a quoted string, that string's own
  brackets win. Every `replaceBuffer` edit rejects a change whose boundary falls
  strictly inside a live paste marker. `aw` from trailing whitespace does
  nothing where vim crosses the line break. `iw` groups non-ASCII punctuation
  with words where pi's `w` treats it as a boundary. No `ip` / `as` / `at`, no
  counts. Empty inner blocks (`""`, `()`) delete nothing; `c` still enters
  insert. Quotes honor only backslash escapes.
- No counts (e.g. `3w`, `5dd`).
- `g` prefix only resolves to `gu` / `gU` / `gg`.
- pi allows the cursor at `col == line length`. Normal-mode commands keep it on
  the last char, except `j`, `k` and `u`, which can leave it past the end
  (cosmetic; clamping `j` / `k` would lose the sticky column). Forward deletes
  (`x` `s` `D` `C` `dl` `dw` `d$`) first step onto the last char and do nothing
  on an empty line, so they never join lines.
- `cc` / `S` do not keep indentation.
- `dh` / `d0` / `ch` / `c0` at column 0 do nothing, as in vim. `db` there still
  joins the previous line.
- The cursor shape reset on `session_shutdown` is untested in a live session.
- `gu` / `gU` / `~` / `dt` / `df` / `ct` / `cf` are not paste-marker aware: a
  marker lying entirely inside the edit is rewritten, and pi then submits it as
  literal text. Only a marker split by an edit boundary is rejected.
- `gg` / `G` do not reset pi's sticky column (`preferredVisualCol`, private). A
  following `j` / `k` can land on a stale column.
- `dt`/`df`/`ct`/`cf` are forward + single-line only. `dT`/`dF` (backward) not
  implemented.
- Word definition follows pi (single rule), not vim's word/WORD split.
