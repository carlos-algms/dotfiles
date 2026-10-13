# emoji-picker

Pi extension. Type `:` at the start of a line or after a space to open an emoji
dropdown in the editor. It is the same dropdown as the `@` file picker.

## Use

- ` :shru` or ` :neutral` fuzzy-matches emoji names; ` :idk` matches tags
- `up`/`down` or `ctrl+p`/`ctrl+n` move the selection. `ctrl+p/n` come from
  `tui.select.up/down` in `~/.pi/agent/keybindings.json`, not from this
  extension
- `enter` or `tab` inserts the emoji
- `space` closes the picker and leaves the typed text as is (`:`)

## Ranking

1. Recent emojis that match, newest first. A bare `:` lists recents first
2. Name contains the query
3. A tag contains the query
4. Name matches as a subsequence
5. A tag matches as a subsequence

Within a group, pi-tui's `fuzzyMatch` score decides. Literal matches rank above
subsequence matches because pi-tui matches greedily: `shru` otherwise ranks
"straight ruler" above "person shrugging", and `idk` matches "medium-dark".

## Data

`emojis.ts` is generated from `emojibase-data` (MIT) by
`node generate-emojis.ts`. Needs network. Do not edit it by hand. Filters live
in `filter.ts`:

- Flags (group 9) and regional indicators (no group) are dropped
- Female variants are dropped: `gender === 0` and every `👩‍…` sequence. The
  standalone `👩` stays. Single-codepoint pairs such as `👭` stay
- Toneable emojis keep only the light-tone variant, replacing the base. Mixed
  tone pairs are dropped. Tags come from the base emoji. Labels drop the skin
  tone (`man: light skin tone, beard` becomes `man: beard`)
- Tags that are a substring of the label or of another tag are dropped
  (`tags.ts`). This is lossless: any query that matches such a tag also matches
  the longer text
- Skin-tone swatches and hair components (group 2) are not filtered

## State

`${XDG_STATE_HOME:-~/.local/state}/pi/emoji-picker/recent.json`. A JSON array of
up to 30 emojis, newest first. A missing or corrupt file starts an empty list.

Every pick re-reads the file, adds the emoji, and writes it back. Concurrent pi
sessions therefore merge their picks instead of overwriting each other. Writes
within one session run in order.

## Files

- `index.ts` wires the provider on `session_start`
- `provider.ts` the autocomplete provider: token detection, items, insertion
- `match.ts` search and ranking
- `recents.ts` XDG path, MRU list, load and save
- `filter.ts` data filters, used by `generate-emojis.ts`
- `test-fuzzy.ts` test double for `fuzzyMatch`. Node cannot resolve
  `@earendil-works/pi-tui` outside pi

## Tests

```bash
node --test 'AI-configs/pi/extensions/emoji-picker/*.test.ts'
```
