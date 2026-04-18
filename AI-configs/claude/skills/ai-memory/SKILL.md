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
- **No `sources` in frontmatter** - keep source URLs in a `## Sources` section
  at the end of the note with labeled markdown links. Frontmatter `sources`
  strips context and duplicates what's already inline.
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

## Sources

- [Neovim 0.11 release notes](https://neovim.io/doc/user/news-0.11.html)
EOF
)"
```

## Related skills

- `personal-wiki` - for saving reusable knowledge to the wiki
- `obsidian-mechanics` - CLI mechanics, file ops, direct file fallback
