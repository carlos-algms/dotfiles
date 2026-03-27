---
name: second-brain
description: >
  Use when the user asks to save, store, document, or record research results,
  investigation findings, project notes, or technical discoveries to their
  second brain. Triggers on: "save this", "store this", "document this", "save
  my research", "save to second brain", "log this investigation", "save
  findings".
---

# Second Brain Memory

Save research and project investigations to the Obsidian vault as long lasting
memory.

**Primary tool:** `obsidian` CLI (requires Obsidian GUI to be running).
**Fallback:** Direct file operations via Read/Write/Edit tools against
`$SECOND_BRAIN_PATH`.

**Related skills:** `obsidian:obsidian-cli` (full CLI reference),
`obsidian:obsidian-markdown` (Obsidian-flavored Markdown syntax).

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
User says "save research" / "store research"?
  → Save under ai-memory/Researches/

User says "save" / "store" (no explicit destination)?
  → Get current folder/project name (from cwd basename or context)
  → Save under ai-memory/Projects/<project-name>/
    (folders are auto-created by obsidian create)
```

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

## Long or Complex Content

The CLI does **not** support piping/stdin. For short content, use `\n` inline.
For long content, use a **heredoc with command substitution**:

**Short content** — inline `\n`:

```bash
obsidian create path="ai-memory/Researches/2026-03-27-topic.md" \
  content="# Title\n\nParagraph one.\n\n## Section\n\n- item 1\n- item 2"
```

**Long content** — heredoc via `content="$(cat <<'EOF' ... EOF)"`:

````bash
obsidian create path="ai-memory/Researches/2026-03-27-topic.md" \
  content="$(cat <<'EOF'
# Research Title

## Context

Long explanation with **bold**, `code`, and $variables preserved.

## Findings

- Finding 1
- Finding 2

```bash
echo "code blocks work too"
```

EOF )"

````

This also works with `append` and `prepend`.

**From an existing file** — use `$(cat ...)`:

```bash
obsidian create path="ai-memory/Researches/2026-03-27-copy.md" \
  content="$(cat /path/to/source.md)"
```

## Appending to Existing Files

```bash
obsidian append \
  path="ai-memory/Projects/dotfiles/2026-03-17-research.md" \
  content="\n## New Section\n\nAdditional findings here"
```

## Editing Existing Files

1. **Append/prepend**: `obsidian append` or `obsidian prepend`
2. **Full replace**: `obsidian create path="<path>" content="..." overwrite`
3. **Mid-file edit** (read → modify → write back):

```bash
CONTENT=$(obsidian read path="<path>")
# modify $CONTENT with sed, variable substitution, etc.
obsidian create path="<path>" content="$CONTENT" overwrite
```

**Warning:** `create` without `overwrite` on an existing file creates a
duplicate (e.g. `file 1.md`). Always use `overwrite` when replacing.

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
