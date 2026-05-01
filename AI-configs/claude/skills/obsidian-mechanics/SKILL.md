---
name: obsidian-mechanics
description: >
  Personal Obsidian CLI mechanics and patterns not covered by the base
  `obsidian:obsidian-cli` skill. Load when driving the Obsidian CLI for content
  creation, file operations, vault hygiene, or version history. Triggers on:
  "search my vault", "find notes about", "show orphan notes", "find broken
  links", "rename this note", "move this note", "show note history", "restore
  version", "list backlinks", "show outline", "heredoc obsidian", "obsidian
  fallback", "vault hygiene".
---

# Obsidian Mechanics

Personal patterns for driving the Obsidian CLI. Fills gaps in the base
`obsidian:obsidian-cli` skill (heredoc content creation, file operations,
version history, vault hygiene, direct-file fallback).

**MANDATORY:** Load `obsidian:obsidian-cli` for the base CLI reference (syntax,
file targeting, common patterns).

## Vault context

Personal vault is a second-brain / Zettelkasten in Obsidian Flavored Markdown.

- **OneDrive sync, NO git.** Recovering from bad edits is hard. Be careful with
  edits and deletions. Track your changes so you can restore manually.
- **No build, no tests, no package manager.**
- Strict line breaks enabled.
- New files created in the current folder by default.
- Attachments live in `999-system/Attachments/`.
- Community plugins listed in `.obsidian/community-plugins.json`.

### Folder layout

```
001-Quick-Notes/    Fleeting notes, inbox
010-Daily/          Daily notes (Obsidian daily notes plugin)
100-wiki/           LLM-maintained personal wiki - see personal-wiki skill
  <category>/<topic>/  - dynamic folders, kebab-case
  log/<year>/          - monthly ingestion logs
999-system/         Obsidian internals (Archive, Attachments, Templates, ai-agents)
ai-memory/          AI investigation notes - see ai-memory skill
  Projects/<name>/     - per-project, date-prefixed files
  Researches/          - FROZEN, do NOT add new notes
```

Run `tree -d -L 3` over the vault path for the live layout.

## Prerequisites

Obsidian GUI must be open for the CLI to work. Assume it's running, and only try
to open it if any of the commands fail:

```bash
open -a Obsidian
```

Only verify connectivity if commands fail: `obsidian vault` should return vault
info. If it fails, wait a few seconds after opening and retry.

## Finding Existing Content

```bash
# Returns matching file paths only (like grep -l)
obsidian search query="auth middleware"

# Returns file:line: content for each match (like grep -n)
obsidian search:context query="auth middleware"

# Limit to a folder
obsidian search query="e2e tests" path="<folder>"

# List files in a folder
obsidian files folder="<folder>"

# Read a file
obsidian read path="<folder>/<note>.md"
```

## Resolving the vault path

Default: `obsidian vault info=path` returns the active vault's absolute path.
Cache the result per session - don't re-shell every time.

```bash
VAULT=$(obsidian vault info=path)
```

Fallback: `$SECOND_BRAIN_PATH` env var. Use when CLI calls fail (Obsidian GUI
not running, subagent context, etc.).

## Creating new files

**Default: `Write` tool, not `obsidian create`.**

```
Write <vault>/<folder>/<slug>.md
```

Why default to `Write`:

- Native diff in chat. Reviewable.
- No shell escaping, no heredoc, no `\t`/`\n`/`\r` bug.
- One tool call, not a 100-line bash invocation.
- Works whether Obsidian GUI is running or not.

Tradeoff: Obsidian indexes the file on its next vault scan (seconds). Wikilinks
resolve fine - they're filename-based, not index-based.

### When to use `obsidian create` instead

- You explicitly need its `template=<name>` flag.
- You want the file opened in the GUI immediately (`open`, `newtab`).
- Otherwise: prefer `Write`.

If you do use it, pass `content=` via heredoc (`<<'EOF'`) and remember:

- Without `overwrite`, an existing path creates a duplicate (`file 1.md`).
- The CLI interprets `\t`/`\n`/`\r` as escape sequences in `content=`. A literal
  `path\to\file` becomes `path<tab>o\file`. Fall back to `Write` when this hits.

## Appending to Existing Files

```bash
obsidian append \
  path="<folder>/<note>.md" \
  content="\n## New Section\n\nAdditional findings here"
```

## Editing and reading existing files

**Default to direct file tools (`Read`, `Edit`, `Write`) for any file already on
disk.** They give better diffs, user review, no shell escaping, and work whether
Obsidian GUI is running or not.

Reserve the `obsidian` CLI for what it uniquely offers: wikilink-aware
rename/move, vault-wide search, property edits, backlinks, history, and hygiene
commands.

Absolute path: prepend the vault path (see
[Resolving the vault path](#resolving-the-vault-path)) to any vault-relative
path returned by the CLI (e.g. `Created: <folder>/note.md`).

```bash
# Read
Read <vault>/<folder>/<note>.md

# Edit a section
Edit <vault>/<folder>/<note>.md

# Full rewrite
Write <vault>/<folder>/<note>.md
```

### When to use `obsidian append` instead

Only when you need fire-and-forget append without reading context first:

```bash
obsidian append \
  path="<folder>/<note>.md" \
  content="\n## New Section\n\nContent here"
```

For anything structural (inserting mid-file, replacing a section, reordering),
use `Read` then `Edit`.

## Links

Obsidian resolves wikilinks **by filename only** - not by `title`, `aliases`, or
headings. Aliases only help with autocomplete suggestions.

### Internal links (wikilinks)

```markdown
[[filename-without-ext]] [[filename-without-ext|Display Text]]
[[filename-without-ext#Heading]] [[#Heading in same note]]
```

### Rules

- **Always use pipe syntax for `related` frontmatter** -
  `"[[filename|Display Title]]"` so the link resolves correctly and the display
  text stays human-readable.
- **Use `[[wikilinks]]`** for internal vault links - Obsidian tracks renames
  automatically.
- **Use `[text](url)`** only for external URLs.
- **No colons in wikilink display text** - Obsidian creates files from these;
  macOS/Windows forbid `:` in filenames.

### Example

```yaml
related:
  - '[[2026-03-17-my-note|My Note Title]]'
  - '[anthropics/claude-code#100](https://github.com/anthropics/claude-code/issues/100)'
  - '[RFC discussion](https://github.com/org/repo/discussions/42)'
```

```markdown
See [[2026-03-17-my-note|My Note Title]] for details. Related:
[anthropics/claude-code#100](https://github.com/anthropics/claude-code/issues/100)
```

## File operations

### Move and rename

`rename` is preferred over `move` when only changing the name - Obsidian
auto-updates all wikilinks pointing to the file.

```bash
# Rename (updates all wikilinks automatically)
obsidian rename path="<folder>/old-name.md" \
  name="new-name.md"

# Move to a different folder
obsidian move path="<folder>/<note>.md" \
  to="<other-folder>/"

# Move and rename (to= is full destination path)
obsidian move path="<folder>/<note>.md" \
  to="<other-folder>/new-name.md"
```

### Delete

```bash
# Soft delete (moves to Obsidian trash)
obsidian delete path="<folder>/<note>.md"

# Permanent delete (skips trash)
obsidian delete path="<folder>/<note>.md" permanent
```

## Property management

Set, read, or remove individual frontmatter properties without editing the whole
file. Useful for updating `status`, `tags`, etc.

```bash
# Read a property
obsidian property:read name="status" \
  path="<folder>/<note>.md"

# Set a property
obsidian property:set name="status" value="completed" \
  path="<folder>/<note>.md"

# Set with explicit type
obsidian property:set name="tags" value="neovim,lsp" \
  type=list path="<folder>/<note>.md"

# Remove a property
obsidian property:remove name="aliases" \
  path="<folder>/<note>.md"
```

Supported types: `text`, `list`, `number`, `checkbox`, `date`, `datetime`.

## Navigation and linking

### Backlinks and outgoing links

```bash
# List what links TO a note
obsidian backlinks path="<folder>/<note>.md"

# With link counts
obsidian backlinks path="<folder>/<note>.md" counts

# List outgoing links FROM a note
obsidian links path="<folder>/<note>.md"
```

### Outline

Show heading structure of a note - useful before appending to find the right
section.

```bash
obsidian outline path="<folder>/<note>.md"
# format: tree (default), md, json
obsidian outline path="<folder>/<note>.md" format=md
```

### Tags

```bash
# List all tags in vault with counts
obsidian tags counts sort=count

# Get files for a specific tag
obsidian tag name="neovim" verbose

# List tags for a specific file
obsidian tags path="<folder>/<note>.md"
```

## Vault hygiene

Find broken links, orphaned notes, and dead-end files.

```bash
# Files with no incoming links (orphans)
obsidian orphans

# Files with no outgoing links (dead ends)
obsidian deadends

# Broken/unresolved wikilinks
obsidian unresolved

# With source file info
obsidian unresolved verbose
```

## Version history

Safety net for accidental overwrites. Obsidian tracks local file versions
automatically.

```bash
# List files that have history
obsidian history:list

# List versions for a file
obsidian history path="<folder>/<note>.md"

# Read a specific version (1 = most recent)
obsidian history:read path="<folder>/<note>.md" \
  version=1

# Diff between versions
obsidian diff path="<folder>/<note>.md" \
  from=1 to=2

# Restore a version
obsidian history:restore path="<folder>/<note>.md" \
  version=1
```

## Working without the Obsidian CLI

Direct file tools are a superset of what the CLI can do for single-file
operations. Use them:

- As the **default** for creating, reading, and editing files (see
  [Creating new files](#creating-new-files) and
  [Editing and reading existing files](#editing-and-reading-existing-files))
- When Obsidian GUI is not running (CLI errors)
- In subagents or CI contexts where launching Obsidian is undesirable
- For bulk operations where `Glob`/`Grep` is faster than vault search

What you lose by skipping the CLI:

- `rename`/`move` wikilink auto-update (manual find-replace needed)
- Property-level edits via `property:set`
- Version history tracking
- Vault-aware search (backlinks, orphans, unresolved)

```bash
# Resolve vault path once (see Resolving the vault path section)
VAULT=$(obsidian vault info=path)   # primary
VAULT=${VAULT:-$SECOND_BRAIN_PATH}   # env var fallback

# Create
Write $VAULT/<folder>/<slug>.md

# Edit
Edit $VAULT/<folder>/<note>.md

# Read
Read $VAULT/<folder>/<note>.md

# Search
Glob $VAULT/**/*.md
Grep "auth middleware" $VAULT/
```

## Vault writing conventions

Apply to every note written into this vault (wiki, ai-memory, quick notes,
daily, etc.). Per-skill rules layer on top.

- Obsidian callouts (`> [!type]`) for highlighted info.
- 80-char line width. Unordered lists use `-` (dash).
- Code fences use short language identifiers (`md`, `ts`, `tsx`, `py`, `bash`).
- No em-dashes (`—`) or en-dashes (`–`) - use `-`.
- British English. No Oxford comma.
- For OFM syntax (wikilinks, embeds, callouts, properties), see
  `obsidian:obsidian-markdown` skill.
- For general formatting (headings, tables, line spacing), see
  `markdown-formatting` skill.

## Sources convention

Applies to any note that cites sources (wiki pages, ai-memory notes, any
long-form note). Goal: investigations stay reproducible. The note itself is the
comparison point if a source changes - `retrieved` dates anchor when the claims
were true.

Rules:

- `## Sources` section at end of note, just above `## Changelog` if one exists.
- Both `## Sources` and any following `## Changelog` heading must be preceded by
  `---` on its own line.
- Never put sources in frontmatter.
- External links (`[Title](https://...)`) and internal wikilinks
  (`[[clipped-article|Title]]`) both valid.
- Empty section is fine - keep the heading.

For new entries (any source cited while writing or updating today):

- Append ` - retrieved YYYY-MM-DD` to the parent bullet, today's date.
- Add a nested bullet with a one-line note on what the source covers. No
  `Extracted:` prefix.

If a pre-existing entry lacks the `retrieved` suffix or the nested note, add
them next time the source is re-consulted.

Example:

```markdown
...

---

## Sources

- [Article Title](https://example.com/article) - retrieved 2026-04-21
  - core tradeoff between X and Y
- [[clipped-article|Local Clipping]] - retrieved 2026-04-21
  - full article preserved in vault
- [Legacy page](https://example.com/old)
  - summary of what was used

---

## Changelog
```
