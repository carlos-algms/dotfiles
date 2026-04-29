---
name: personal-wiki
description: >
  Save durable, reusable knowledge to the Obsidian vault wiki at `100-wiki/`.
  Use when the user asks to save, store, or ingest knowledge to the wiki.
  Triggers on: "save to wiki", "add to wiki", "wiki this", "turn this into
  knowledge", "save as knowledge", "save knowledge", "document in wiki".
---

# Personal Wiki

Ingest durable, reusable knowledge to the Obsidian vault wiki at
`100-wiki/<category>/`.

**MANDATORY:** Load these skills before any operation:

- `obsidian-mechanics` (CLI patterns, heredoc, file ops, fallback)
- `markdown-formatting` (personal formatting rules)
- `obsidian:obsidian-markdown` (Obsidian-flavored Markdown syntax)

## Vault conventions

**MANDATORY:** Before writing any wiki content, you MUST know the conventions in
`CLAUDE.md` from the vault root. It is the single source of truth for the
frontmatter spec, the `## Sources convention`, the wiki page body template,
folder structure, file naming, cross-reference rules, and markdown conventions.
If you write a page without having read it, the page will violate the spec and
the task will fail.

**How to get it:** If `CLAUDE.md` is already in your context (check your
conversation - it's auto-loaded when cwd is the `secondBrain` folder, including
for subagents), do NOT re-read it. If it is NOT in your context, you MUST fetch
it before writing anything:

```bash
obsidian read path="CLAUDE.md"
```

Do not proceed without it.

## Ingest workflow

When the user asks to save knowledge to the wiki:

1. Identify key knowledge from the conversation context
2. Choose or create the category folder (lowercase-kebab)
3. Write the page: frontmatter + body + changelog
4. Check existing wiki pages for cross-references - update them with wikilinks
   to the new page (and update their changelogs and `updated` date)
5. Append an entry to the current month's log file at
   `100-wiki/log/<year>/<MM>-wiki-ingestion.md`
6. Report what was created and what was updated

**Do not ask for confirmation** - just create. The user will request changes if
needed.

## Wiki log entries

Monthly log at `100-wiki/log/<year>/<MM>-wiki-ingestion.md`.

Format: `## YYYY-MM-DD - Weekday` as date heading, then `### action | title` for
each entry. Group all entries on the same day under one date heading.

Actions: `ingest`, `update`, `setup`, `lint`, etc.

```markdown
## 2026-04-18 - Saturday

### ingest | Page Title

- **Created:** [[slug|Page Title]] in `<category>/<topic>/`
- **Source:** brief description or URL

### update | Another page

- **Updated:** [[other-slug|Other Page]] - added cross-reference
- **Source:** brief description or URL
```

Entries are append-only.

## Related skills

- `ai-memory` - for saving project-specific notes
- `obsidian-mechanics` - CLI mechanics, file ops, direct file fallback
