---
name: personal-wiki
description: >
  Save durable, reusable knowledge to the Obsidian vault wiki at `100-wiki/`.
  Use when the user asks to save, store, or ingest knowledge to the wiki.
  Triggers on: "save to wiki", "add to wiki", "wiki this", "turn this into
  knowledge", "save as knowledge", "save knowledge", "document in wiki".
---

# Personal Wiki

Persistent, interlinked LLM-maintained knowledge base at `100-wiki/`. Inspired
by Karpathy's LLM Wiki pattern: the LLM writes and maintains content; the user
curates sources, directs analysis, asks questions.

**MANDATORY:** Load these skills before any operation:

- `obsidian-mechanics` - vault context, file ops, sources convention, vault
  writing conventions.
- `markdown-formatting` - personal markdown formatting rules.
- `obsidian:obsidian-markdown` - OFM syntax (wikilinks, callouts, etc.).

## Folder layout

```
100-wiki/
  <category>/         lowercase-kebab, dynamic (technology, health, finance, ...)
    <topic>/          REQUIRED subfolder, never put pages directly under category
      <slug>.md       kebab-case, no date prefix
  log/<year>/<MM>-wiki-ingestion.md   monthly logs
```

Examples:

- `technology/neovim/`
- `people/andrej-karpathy/`
- `health/nutrition/`
- `culture/books/`

### Media and entertainment

Games, books, movies, shows, music, etc. add a franchise/series level when
multiple titles exist:

```
<media-type>/<franchise-or-series>/<title-slug>/<title-slug>-<topic>.md
```

Topic files prefix the title slug so filenames are unique vault-wide (Obsidian
wikilinks resolve by filename only). Examples:

- `games/resident-evil/resident-evil-2-remake/resident-evil-2-remake-cheat-sheet.md`
- `shows/breaking-bad/breaking-bad/breaking-bad-characters.md`

Flatten when only one title exists (e.g. `movies/oppenheimer/`). Promote to
franchise-nested form later if siblings appear.

For ordered content (puzzles, episodes, chapters), list entries in
in-game/in-story order. Use tables when values differ by difficulty,
playthrough, or randomized per save.

## Frontmatter

```yaml
---
title: Page Title
aliases:
  - Alternate Name
type: concept | person | event | comparison | guide | reference
tags:
  - category-tag
  - subtopic-tag
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

Rules:

- **No `status`** - wiki pages are always living documents.
- **No `date`** - use `created` and `updated`.
- **No `related`** - use inline `[[wikilinks]]` and the `## Sources` section.
- **No `sources` in frontmatter** - see Sources convention in
  `obsidian-mechanics`.
- **`type`** describes the shape of knowledge, not the topic.
- **No colons in `title` or `aliases`** - use `-`.

## Page body template

```markdown
---
frontmatter...
---

# Page Title

Opening summary paragraph (2-3 sentences).

## Section Heading

Content with [[wikilinks]] to other wiki pages. Link liberally, even to pages
that don't exist yet.

Use `[text](url)` for external links only.

---

## Sources

- [Article Title](https://example.com/article) - retrieved YYYY-MM-DD
  - brief note on what the source covers

---

## Changelog

- **YYYY-MM-DD**
  - Created. Brief note on source/context.
```

## Conventions

- **No index files.** Use Grep / Obsidian search to find pages.
- **Categories are dynamic.** Judge and create folders as needed.
- **File naming:** `kebab-case-slug.md`, no date prefix.
- **Cross-references:** liberal `[[wikilinks]]` inline in prose AND in section
  headings - link to pages that don't exist yet to surface knowledge gaps.
  - When a dedicated sub-page exists for a topic, link to it from the section
    that discusses it, NOT the opening summary.
  - Opening summary may only link to sub-pages whose topic has no corresponding
    section in the body.
  - Within a section: link in the heading OR inline in the body, never both.
    Prefer inline (e.g. "major [[neovim-lsp|LSP improvements]]"). Heading link
    only when the sub-page isn't naturally mentioned in text.
- **Contradictions:** update the page to current truth, log the change in the
  page's `## Changelog` and the monthly log file.

## Splitting content into focused pages

Each page covers one focused concept, feature, or entity. When a source covers
multiple substantial topics, split and interlink.

- **When to split:** topic has enough standalone content (full API with
  examples, person's biography, detailed process). Main page must be a
  meaningful overview, not just a list of links.
- **When NOT to split:** closely related content that only makes sense together
  (editor improvements + new commands from same release; a person's education +
  career).
- **Aim for 2-5 pages from a large source, not 7-10.** Avoid splitting so
  aggressively that the main page becomes a shallow table of contents.

## Ingest workflow

When the user asks to save knowledge to the wiki:

1. Identify key knowledge from conversation context.
2. Choose or create the category folder (lowercase-kebab) and required topic
   subfolder.
3. Write the page: frontmatter + body + sources + changelog.
4. Check existing pages for cross-references; update them with wikilinks to the
   new page (and bump their `updated` date + add changelog entries).
5. Append an entry to the current month's log file at
   `100-wiki/log/<year>/<MM>-wiki-ingestion.md`.
6. Report what was created and what was updated.

**Do not ask for confirmation** - just create. The user will request changes if
needed.

## Monthly log entries

Path: `100-wiki/log/<year>/<MM>-wiki-ingestion.md`.

Format: `## YYYY-MM-DD - Weekday` as date heading; `### action | title` per
entry; group same-day entries under one date heading.

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

- `ai-memory` - project-specific notes (different folder, different rules).
- `obsidian-mechanics` - vault context, file ops, sources convention.
