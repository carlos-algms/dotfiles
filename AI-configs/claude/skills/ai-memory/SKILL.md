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

Save project notes, findings, and investigations as long-lasting memory under
`ai-memory/Projects/<project-name>/`.

For reusable wiki-style knowledge, use `personal-wiki` instead.

**MANDATORY:** Load these skills before any operation:

- `obsidian-mechanics` - vault context, file ops, sources convention, vault
  writing conventions.
- `markdown-formatting` - personal markdown formatting rules.
- `obsidian:obsidian-markdown` - OFM syntax (wikilinks, callouts, etc.).

## Where to save

```
ai-memory/Projects/<project-name>/YYYY-MM-DD-<topic-slug>.md
```

- Derive `<project-name>` from the current working directory basename or
  conversation context.
- Folders are auto-created by `Write` (and by `obsidian create`).
- `ai-memory/Researches/` is a frozen historical folder. **Do NOT save new notes
  there** - everything new goes under `Projects/`.

## File naming

`YYYY-MM-DD-<topic-slug>.md` (date-first for filesystem sort order).

## Frontmatter

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

Rules:

- **No colons in `title` or `aliases`** - Obsidian uses these as filenames;
  macOS/Windows forbid `:` in filenames. Use `-` instead.
- **No `sources` in frontmatter** - see Sources convention in
  `obsidian-mechanics`.
- **Tags use nested hierarchy** - `project/dotfiles`, `testing/e2e`. Not flat
  tags.
- **`related` uses pipe wikilinks** - `"[[filename|Display Title]]"`.
- **`date`** from file creation date (filesystem birthtime or filename date
  prefix).
- **`type`**: `project` for project notes, `reference` for reusable snippets,
  `fleeting` for temporary captures.

## Content

- Title as H1, concise and descriptive.
- Include the date (`2026-03-17` format) in the H1 or first paragraph.
- Body: findings, key decisions, links, code snippets as needed.
- Use OFM (wikilinks, callouts) per `obsidian:obsidian-markdown`.
- Reference links and file links with line numbers when available (GitHub,
  etc.).
- Investigations must be reproducible: include queries, scripts, commands,
  steps.
- Append a `## Sources` section per the Sources convention in
  `obsidian-mechanics`.

## Example

Default tool is `Write` (see `obsidian-mechanics`). Resolve the vault path once
with `obsidian vault info=path` (fallback `$SECOND_BRAIN_PATH`).

```
Write <vault>/ai-memory/Projects/dotfiles/2026-04-14-neovim-lsp-config.md
```

Content:

```markdown
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

Migrated from `lspconfig` setup calls to `vim.lsp.config(...)` API available in
Neovim 0.11+.

## Key changes

- Per-server config files moved to `neovim/nvim/lsp/`
- `mason-lspconfig.nvim` auto-enables configs, no manual setup needed

---

## Sources

- [neovim 0.11 lsp.txt](...) - retrieved 2026-04-14
  - canonical reference for vim.lsp.config

---

## Changelog

- **2026-04-14**
  - Created during migration of dotfiles repo.
```

## Related skills

- `personal-wiki` - reusable wiki-style knowledge (different folder, rules).
- `obsidian-mechanics` - vault context, file ops, sources convention.
