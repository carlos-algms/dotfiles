# md2adf.py grammar

`scripts/md2adf.py` converts Markdown to ADF. It exits 2 with `line N: ...` on
stderr for anything it cannot convert. It never emits partial output.

## Supported

- Headings `#` to `######`
- Paragraphs; a trailing double space or `\` makes a hard break
- Lists: `-`, `*`, `+`, `1.`, nested and mixed, multi-paragraph items, fenced
  code in items. List items and blockquotes hold paragraphs, lists, and fenced
  code only
- Checklists: `- [ ]` open, `- [x]` done, nested to any depth. Items hold inline
  text; a nested checklist becomes a sibling `taskList` after its parent item
  (ADF shape, accepted by Jira)
- Fenced code (backticks or tildes) with optional language
- GFM tables; inline marks and smart links in cells
- Blockquote `>`
- Horizontal rule `---` (needs a blank line before it)
- Inline: `**bold**`, `*italic*`, `_italic_`, `~~strike~~`, `` `code` ``,
  `[text](https://url)` link, `<https://url>` smart link (`inlineCard`)
- `code` combined with bold or italic keeps only `code`
- Containers:

  ```text
  :::panel info|note|warning|error|success
  text
  :::

  :::expand Title
  text
  :::
  ```

## Rejected with an error

Images, raw HTML at the start of a block, setext headings (`Title` over `===`),
indented code blocks, bullets or code under a checklist item, checklists inside
bullet items, nested containers, relative link targets, empty link text, empty
list items, blockquotes, panels, and expands, headings, tables, or rules inside
list items or blockquotes, tables inside panels, and a table not preceded by a
blank line.

Differs from CommonMark: an unindented line after a list item starts a new
paragraph (no lazy continuation), and a `---` right after a list line is not a
setext heading. Put a blank line before `---`.

Passed through as literal text, with exit 0: inline tags such as `a <b>x</b>`,
reference-style links such as `[a][b]`, and bare URLs.

## Output

- Default: the bare `{"type":"doc","version":1,...}` document
- `--format acli-create`: full payload; needs `--summary`; reads team, project,
  and sprint ids from `jira-data.yaml`
- `--format acli-edit`: needs `--issues`; carries the flags given and always the
  description. To change only the summary, use plain
  `acli jira workitem edit --key K --summary ...` without this script
- `--assignee` takes `me` (reads `my_email`) or an email; `@me` is rejected
- Same input and flags give byte-identical output. `localId` values derive from
  content and their position in the document
- Output is ASCII JSON (non-ASCII text is `\uXXXX`-escaped)
- Every failure exits 2 with a one-line message and no output, including invalid
  UTF-8 input and nesting deeper than the Python recursion limit
