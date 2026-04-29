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

## Creating New Files

```bash
obsidian create \
  path="<folder>/YYYY-MM-DD-<topic-slug>.md" \
  content="# Title\n\nContent here"
```

**Note:** `obsidian create` creates parent folders automatically.

**Warning:** `obsidian create` without `overwrite` on an existing file creates a
duplicate (e.g. `file 1.md`). Always use `overwrite` when replacing via CLI.

## Creating content with heredoc

Use a **heredoc with single-quoted delimiter** (`<<'EOF'`) to pass content to
`obsidian create`. This prevents shell expansion and lets you write readable
markdown with real line breaks.

```bash
obsidian create \
  path="<folder>/2026-04-14-topic.md" \
  content="$(cat <<'EOF'
---
title: Topic Title Here
date: 2026-04-14
tags:
  - topic-tag
type: project
status: active
---

# Topic title here

Content with $variables, "quotes", tables, and code blocks
all work without escaping.

| Column A | Column B |
|----------|----------|
| value    | $100     |

> [!tip] Callouts work too
> No special handling needed.
EOF
)"
```

### Why `<<'EOF'` (single-quoted delimiter)

- **No shell expansion** - `$HOME`, `$100` stay literal
- **Real line breaks** - no `\n` needed, write markdown naturally
- **All quotes safe** - double quotes, single quotes, backticks
- **Single step** - no temp files to create and clean up

### Known limitation

The obsidian CLI interprets `\t`, `\n`, and `\r` as escape sequences in the
`content=` value. A literal `path\to\file` becomes `path<tab>o\file`. This
rarely occurs in normal markdown - only when backslash precedes `t`, `n`, or
`r`.

If you hit this, use the `Write` tool directly (see
[Working without the Obsidian CLI](#working-without-the-obsidian-cli)).

## Appending to Existing Files

```bash
obsidian append \
  path="<folder>/<note>.md" \
  content="\n## New Section\n\nAdditional findings here"
```

## Editing and reading existing files

**Default to direct file tools (`Read`, `Edit`, `Write`) for any file already
on disk.** They give better diffs, user review, no shell escaping, and work
whether Obsidian GUI is running or not.

Reserve the `obsidian` CLI for what it uniquely offers: creating notes with
rich frontmatter via heredoc, wikilink-aware rename/move, vault-wide search,
property edits, backlinks, history, and hygiene commands.

Absolute path: `$SECOND_BRAIN_PATH/<vault-relative-path>`. `obsidian create`
returns the vault-relative path on success (e.g.,
`Created: <folder>/note.md`) - prepend `$SECOND_BRAIN_PATH/` to use it with
direct tools.

```bash
# Read
Read $SECOND_BRAIN_PATH/<folder>/<note>.md

# Edit a section
Edit $SECOND_BRAIN_PATH/<folder>/<note>.md

# Full rewrite
Write $SECOND_BRAIN_PATH/<folder>/<note>.md
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

- As the **default** for reading and editing existing files (see [Editing
  and reading existing files](#editing-and-reading-existing-files))
- When **creating** a file if the heredoc `\t`/`\n`/`\r` escape limitation
  hits
- When Obsidian GUI is not running (CLI errors)
- In subagents or CI contexts where launching Obsidian is undesirable
- For bulk operations where `Glob`/`Grep` over `$SECOND_BRAIN_PATH/` is
  faster than vault search

What you lose by skipping the CLI:

- `rename`/`move` wikilink auto-update (manual find-replace needed)
- Property-level edits via `property:set`
- Version history tracking
- Vault-aware search (backlinks, orphans, unresolved)

```bash
# Base path: $SECOND_BRAIN_PATH (no trailing slash) - env var pointing
# to the active vault root, set per user.

# Create
Write $SECOND_BRAIN_PATH/<folder>/2026-04-14-topic.md

# Edit
Edit $SECOND_BRAIN_PATH/<folder>/<note>.md

# Read
Read $SECOND_BRAIN_PATH/<folder>/<note>.md

# Search
Glob $SECOND_BRAIN_PATH/**/*.md
Grep "auth middleware" $SECOND_BRAIN_PATH/
```
