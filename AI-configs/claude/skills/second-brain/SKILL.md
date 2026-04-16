---
name: second-brain
description: >
  Use when the user asks to save, store, document, or record research results,
  investigation findings, project notes, technical discoveries, or wiki
  knowledge to their second brain. Triggers on: "save this", "store this",
  "document this", "save my research", "save to second brain", "log this
  investigation", "save findings", "save to wiki", "add to wiki",
  "wiki this", "turn this into knowledge", "save as knowledge".
---

# Second Brain Memory

Save research and project investigations to the Obsidian vault as long lasting
memory.

**Primary tool:** `obsidian` CLI (requires Obsidian GUI to be running).
**Fallback:** Direct file operations via Read/Write/Edit tools against
`$SECOND_BRAIN_PATH`.

**MANDATORY:** Related skills:

You should load these skills when working with the second brain md files,
Obsidian notes, creating or editing existing markdown files

- `markdown-formatting` (personal formatting rules)
- `obsidian:obsidian-cli` (full CLI reference)
- `obsidian:obsidian-markdown` (Obsidian-flavored Markdown syntax)

## Prerequisites

Obsidian GUI must be open for the CLI to work. Assume it's running, and only try
to open it if any of the commands fail:

```bash
open -a Obsidian
```

Also, only verify connectivity if any of the commands fail: `obsidian vault` -
should return vault info. If it fails, wait a few seconds after opening and
retry.

## Finding Existing Content

```bash
# Returns matching file paths only (like grep -l)
obsidian search query="auth middleware"

# Returns file:line: content for each match (like grep -n)
obsidian search:context query="auth middleware"

# Limit to a folder
obsidian search query="e2e tests" path="ai-memory/Projects"

# List files in a folder
obsidian files folder="ai-memory/Projects/dotfiles"

# Read a file
obsidian read path="ai-memory/Projects/dotfiles/2026-03-17-research.md"
```

## Decision: Where to Save

```
User says "wiki" / "knowledge" / "add to wiki" / "save to wiki"?
  → Save under 100-wiki/<category>/
  → See "Wiki workflow" section below

User says "save research" / "store research"?
  → Save under ai-memory/Researches/

User says "save" / "store" (no explicit destination)?
  → Get current folder/project name (from cwd basename or context)
  → Save under ai-memory/Projects/<project-name>/
    (folders are auto-created by obsidian create)
```

## Wiki workflow

**MANDATORY:** Before writing any wiki content, you MUST know
the conventions in `CLAUDE.md` from the vault root. It contains
the frontmatter spec, folder structure, file naming,
cross-reference rules and markdown conventions. Without it you
will produce incorrect output and the task will fail.

**How to get it:** If `CLAUDE.md` is already in your context
(check your conversation - it's auto-loaded when cwd is the
vault, including for subagents), do NOT re-read it. Only fetch
it manually when it's not in your context:

```bash
obsidian read path="CLAUDE.md"
```

This section only covers the **ingest workflow steps**.

### Wiki ingest workflow

When the user asks to save knowledge to the wiki:

1. Identify key knowledge from the conversation context
2. Choose or create the category folder (lowercase-kebab)
3. Write the page: frontmatter + body + changelog
4. Check existing wiki pages for cross-references - update them
   with wikilinks to the new page (and update their changelogs
   and `updated` date)
5. Append an entry to the current month's log file at
   `100-wiki/log/<year>/<MM>-wiki-ingestion.md`
6. Report what was created and what was updated

**Do not ask for confirmation** - just create. The user will
request changes if needed.

### Wiki log entries

Monthly log at `100-wiki/log/<year>/<MM>-wiki-ingestion.md`:

```md
## [YYYY-MM-DD] ingest | Page Title

- **Created:** [[slug|Page Title]] in `<category>/`
- **Updated:** [[other-slug|Other Page]] - added cross-reference
- **Source:** brief description or URL
```

Entries are append-only. Each entry starts with `##` for
parseability with grep.

## ai-memory frontmatter (NOT for wiki)

**This section applies ONLY to ai-memory/ notes.** For wiki
pages (100-wiki/), use the frontmatter spec in `CLAUDE.md`.
The two formats are different - do not mix them.

Every ai-memory note must have YAML frontmatter. Required fields:

```yaml
---
title: Note Title Here
date: 2026-03-17
tags:
  - project/project-name
  - topic-tag
type: project | research | reference | fleeting
status: active | completed | archived
aliases:
  - Alternate Name
related:
  - '[[filename-without-ext|Display Title]]'
---
```

### Frontmatter rules

- **No colons in `title` or `aliases`** — Obsidian uses these as filenames;
  macOS/Windows forbid `\` `/` `:` in filenames. Use `-` (space-dash-space)
  instead of `:` in titles.
- **No `sources` in frontmatter** — keep source URLs in a `## Sources` section
  at the end of the note with labeled markdown links. Frontmatter `sources`
  strips context and duplicates what's already inline.
- **Tags use nested hierarchy** — `project/platform-fe`, `testing/e2e`, not flat
  tags.
- **`related` uses pipe wikilinks** — see [Links](#links) section below.
- **`date` from file creation date** — use filesystem birthtime or filename date
  prefix (e.g., `2026-03-17-note-name.md`).

## Creating New Files

```bash
# Create under Researches
obsidian create \
  path="ai-memory/Researches/YYYY-MM-DD-<topic-slug>.md" \
  content="# Title\n\nContent here"

# Create under a project folder
obsidian create \
  path="ai-memory/Projects/<project-name>/YYYY-MM-DD-<topic-slug>.md" \
  content="# Title\n\nContent here"
```

**Note:** `obsidian create` creates parent folders automatically.

## Creating content

Use a **heredoc with single-quoted delimiter** (`<<'EOF'`) to pass
content to `obsidian create`. This prevents shell expansion and
lets you write readable markdown with real line breaks.

```bash
obsidian create \
  path="ai-memory/Researches/2026-04-14-topic.md" \
  content="$(cat <<'EOF'
---
title: Topic Title Here
date: 2026-04-14
tags:
  - topic-tag
type: research
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

- **No shell expansion** — `$HOME`, `$100` stay literal
- **Real line breaks** — no `\n` needed, write markdown naturally
- **All quotes safe** — double quotes, single quotes, backticks
- **Single step** — no temp files to create and clean up

### Known limitation

The obsidian CLI interprets `\t`, `\n`, and `\r` as escape
sequences in the `content=` value. This means a literal
`path\to\file` becomes `path<tab>o\file`. This rarely occurs in
normal markdown — only when backslash precedes `t`, `n`, or `r`.

If you hit this, use the `Write` tool directly as a fallback:

```bash
Write $SECOND_BRAIN_PATH/ai-memory/Researches/2026-04-14-topic.md
```

## Appending to Existing Files

```bash
obsidian append \
  path="ai-memory/Projects/dotfiles/2026-03-17-research.md" \
  content="\n## New Section\n\nAdditional findings here"
```

## Editing Existing Files

Once a file exists on disk, **prefer `Read`/`Edit`/`Write` tools
directly** — they give better diffs, user review, and avoid shell
escaping issues.

The absolute path is `$SECOND_BRAIN_PATH/<vault-relative-path>`.
`obsidian create` returns the vault-relative path on success
(e.g., `Created: ai-memory/Projects/dotfiles/note.md`).

**Preferred approach** — direct file tools:

```bash
# Read
Read $SECOND_BRAIN_PATH/ai-memory/Projects/dotfiles/note.md

# Edit a section
Edit $SECOND_BRAIN_PATH/ai-memory/Projects/dotfiles/note.md

# Full rewrite
Write $SECOND_BRAIN_PATH/ai-memory/Projects/dotfiles/note.md
```

**Alternative** — CLI for quick append/prepend:

```bash
obsidian append \
  path="ai-memory/Projects/dotfiles/note.md" \
  content="\n## New Section\n\nContent here"
```

**Warning:** `obsidian create` without `overwrite` on an existing
file creates a duplicate (e.g. `file 1.md`). Always use `overwrite`
when replacing via CLI.

## Links

Obsidian resolves wikilinks **by filename only** — not by `title`, `aliases`, or
headings. Aliases only help with autocomplete suggestions.

### Internal links (wikilinks)

```md
[[filename-without-ext]] Link by filename [[filename-without-ext|Display Text]]
Link with display text (pipe syntax) [[filename-without-ext#Heading]] Link to a
heading [[#Heading in same note]] Same-note heading link
```

### Rules

- **Always use pipe syntax for `related` frontmatter** —
  `"[[filename|Display Title]]"` so the link resolves correctly and the display
  text stays human-readable.
- **Use `[[wikilinks]]`** for internal vault links — Obsidian tracks renames
  automatically.
- **Use `[text](url)`** only for external URLs.
- **No colons in wikilink display text** — Obsidian creates files from these;
  macOS/Windows forbid `:` in filenames.

### Example

```yaml
related:
  - '[[2026-03-17-my-note|My Note Title]]'
  - '[anthropics/claude-code#100](https://github.com/anthropics/claude-code/issues/100)'
  - '[RFC discussion](https://github.com/org/repo/discussions/42)'
```

```md
See [[2026-03-17-my-note|My Note Title]] for details.
Related: [anthropics/claude-code#100](https://github.com/anthropics/claude-code/issues/100)
```

## File operations

### Move and rename

`rename` is preferred over `move` when only changing the name —
Obsidian auto-updates all wikilinks pointing to the file.

```bash
# Rename (updates all wikilinks automatically)
obsidian rename path="ai-memory/Researches/old-name.md" \
  name="new-name.md"

# Move to a different folder
obsidian move path="ai-memory/Researches/note.md" \
  to="ai-memory/Projects/dotfiles/"

# Move and rename (to= is full destination path)
obsidian move path="ai-memory/Researches/note.md" \
  to="ai-memory/Projects/dotfiles/new-name.md"
```

### Delete

```bash
# Soft delete (moves to Obsidian trash)
obsidian delete path="ai-memory/Researches/old-note.md"

# Permanent delete (skips trash)
obsidian delete path="ai-memory/Researches/old-note.md" permanent
```

## Property management

Set, read, or remove individual frontmatter properties without
editing the whole file. Useful for updating `status`, `tags`,
etc.

```bash
# Read a property
obsidian property:read name="status" \
  path="ai-memory/Researches/2026-03-27-topic.md"

# Set a property
obsidian property:set name="status" value="completed" \
  path="ai-memory/Researches/2026-03-27-topic.md"

# Set with explicit type
obsidian property:set name="tags" value="neovim,research" \
  type=list path="ai-memory/Researches/2026-03-27-topic.md"

# Remove a property
obsidian property:remove name="aliases" \
  path="ai-memory/Researches/2026-03-27-topic.md"
```

Supported types: `text`, `list`, `number`, `checkbox`, `date`,
`datetime`.

## Navigation and linking

### Backlinks and outgoing links

```bash
# List what links TO a note
obsidian backlinks path="ai-memory/Researches/topic.md"

# With link counts
obsidian backlinks path="ai-memory/Researches/topic.md" counts

# List outgoing links FROM a note
obsidian links path="ai-memory/Researches/topic.md"
```

### Outline

Show heading structure of a note — useful before appending to
find the right section.

```bash
obsidian outline path="ai-memory/Researches/topic.md"
# format: tree (default), md, json
obsidian outline path="ai-memory/Researches/topic.md" format=md
```

### Tags

```bash
# List all tags in vault with counts
obsidian tags counts sort=count

# Get files for a specific tag
obsidian tag name="neovim" verbose

# List tags for a specific file
obsidian tags path="ai-memory/Researches/topic.md"
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

Safety net for accidental overwrites. Obsidian tracks local file
versions automatically.

```bash
# List files that have history
obsidian history:list

# List versions for a file
obsidian history path="ai-memory/Researches/topic.md"

# Read a specific version (1 = most recent)
obsidian history:read path="ai-memory/Researches/topic.md" \
  version=1

# Diff between versions
obsidian diff path="ai-memory/Researches/topic.md" \
  from=1 to=2

# Restore a version
obsidian history:restore path="ai-memory/Researches/topic.md" \
  version=1
```

## Fallback: Direct File Operations

Use when Obsidian CLI fails (GUI not running, CLI error, etc.):

1. Base path: `$SECOND_BRAIN_PATH` (no trailing slash)
2. Use `Write` tool to create files, `Edit` tool to modify
3. Use `Glob`/`Grep` to search within `$SECOND_BRAIN_PATH/`

## File Naming

Format: `YYYY-MM-DD-<topic-slug>.md` (date-first for filesystem sort order)

## Content Guidelines

- Title: H1 heading, concise and descriptive
- Body: include findings, key decisions, links, code snippets as needed
- Include the date (`2026-03-17` format) in the H1 or first paragraph
- Use Obsidian-flavored Markdown (wikilinks, callouts OK — see
  `obsidian:obsidian-markdown` skill)
- Reference links and file links with line numbers when available (GitHub, etc.)
- Research must be reproducible: include queries, scripts, commands, steps
