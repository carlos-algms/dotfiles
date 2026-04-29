---
name: ai-memory
description: >
  Save project notes, findings, and investigations to the Obsidian vault under
  `ai-memory/Projects/<project-name>/`. Use when the user asks to save, store,
  document, or record project-related notes. Triggers on: "save this", "store
  this", "document this", "record this", "save findings", "save my findings",
  "log this investigation", "save my notes", "save project notes", "save to
  memory", "save to second brain", "save to ai memory".
---

# AI Memory

Save project notes, findings, and investigations to the Obsidian vault as
long-lasting memory under `ai-memory/Projects/<project-name>/`.

**MANDATORY:** Load these skills before any operation:

- `obsidian-mechanics` (CLI patterns, heredoc, file ops, fallback)
- `markdown-formatting` (personal formatting rules)
- `obsidian:obsidian-markdown` (Obsidian-flavored Markdown syntax)

For saving to the wiki instead, use the `personal-wiki` skill.

## Vault conventions

**MANDATORY:** Before writing any ai-memory note, you MUST know the conventions
in `CLAUDE.md` from the vault root. It is the single source of truth for the
`## Sources convention`, markdown conventions, and vault structure. If you write
a note without having read it, the note will violate the spec and the task will
fail.

**How to get it:** If `CLAUDE.md` is already in your context (check your
conversation - it's auto-loaded when cwd is the `secondBrain` folder, including
for subagents), do NOT re-read it. If it is NOT in your context, you MUST fetch
it before writing anything:

```bash
obsidian read path="CLAUDE.md"
```

Do not proceed without it.

## Where to save

```
ai-memory/Projects/<project-name>/YYYY-MM-DD-<topic-slug>.md
```

Derive `<project-name>` from the current working directory basename or
conversation context. Folders are auto-created by `obsidian create`.

**Note:** `ai-memory/Researches/` is a frozen historical folder. Do NOT save new
notes there - everything new goes under `Projects/`.

## File naming

Format: `YYYY-MM-DD-<topic-slug>.md` (date-first for filesystem sort order).

## Frontmatter

Every ai-memory note must have YAML frontmatter. Required fields:

```yaml
---
title: Note Title Here
date: 2026-03-17
tags:
  - project/project-name
  - topic-tag
type: project | reference | fleeting
status: active | completed | archived
aliases:
  - Alternate Name
related:
  - '[[filename-without-ext|Display Title]]'
---
```

### Frontmatter rules

- **No colons in `title` or `aliases`** - Obsidian uses these as filenames;
  macOS/Windows forbid `\` `/` `:` in filenames. Use `-` (space-dash-space)
  instead of `:` in titles.
- **No `sources` in frontmatter** - see `## Sources convention` in the vault
  `CLAUDE.md` for the canonical format.
- **Tags use nested hierarchy** - `project/platform-fe`, `testing/e2e`, not flat
  tags.
- **`related` uses pipe wikilinks** - `"[[filename|Display Title]]"`. See link
  rules in `obsidian-mechanics`.
- **`date` from file creation date** - use filesystem birthtime or filename date
  prefix (e.g., `2026-03-17-note-name.md`).
- **`type`** - use `project` for project notes, `reference` for reusable
  knowledge snippets, `fleeting` for temporary captures.

## Content guidelines

- Title: H1 heading, concise and descriptive
- Body: include findings, key decisions, links, code snippets as needed
- Include the date (`2026-03-17` format) in the H1 or first paragraph
- Use Obsidian-flavored Markdown (wikilinks, callouts OK - see
  `obsidian:obsidian-markdown`)
- Reference links and file links with line numbers when available (GitHub, etc.)
- Investigations must be reproducible: include queries, scripts, commands, steps

## Example

```bash
obsidian create \
  path="ai-memory/Projects/dotfiles/2026-04-14-neovim-lsp-config.md" \
  content="$(cat <<'EOF'
---
title: Neovim LSP configuration migration
date: 2026-04-14
tags:
  - project/dotfiles
  - neovim
  - lsp
type: project
status: active
---

# Neovim LSP configuration migration - 2026-04-14

Migrated from `lspconfig` setup calls to `vim.lsp.config(...)` API
available in Neovim 0.11+.

## Key changes

- Per-server config files moved to `neovim/nvim/lsp/`
- `mason-lspconfig.nvim` auto-enables configs, no manual setup needed

<!-- Append a `## Sources` section per the `## Sources convention` in CLAUDE.md -->
EOF
)"
```

## Related skills

- `personal-wiki` - for saving reusable knowledge to the wiki
- `obsidian-mechanics` - CLI mechanics, file ops, direct file fallback
