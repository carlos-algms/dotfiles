# Wiki route

Persistent, interlinked LLM-maintained knowledge base at `100-wiki/`.

Use for reusable knowledge that should outlive a single project or personal
task.

## Folder layout

```text
100-wiki/
  <category>/
    <topic>/
      <slug>.md
```

- Categories are dynamic and lowercase-kebab.
- Topic subfolder is required.
- Never put pages directly under a category.
- File slug is kebab-case, no date prefix.
- File slug must be globally unique vault-wide.
- Use `notable-people/` for public person profiles.
- Do not use `people/` for wiki person profiles; reserve
  `011-personal/people/` for people personally relevant to the user.
- Use `people` only when the note is about people as a general concept.
- Country-specific public rules use
  `100-wiki/countries/<country>/<domain>/<note>.md`.
- Use country routes for immigration, tax, healthcare, law and government
  processes.

Examples:

- `technology/neovim/`
- `notable-people/andrej-karpathy/`
- `health/nutrition/`
- `culture/books/`

## Nested entities

When a topic contains a parent entity with multiple sibling pages, add an entity
subfolder:

```text
<category>/<topic>/<entity>/<slug>.md
```

- `<entity>` is the shared parent.
- `<slug>` must still be globally unique on its own.
- Do not repeat the entity in the slug unless needed for uniqueness.
- Flatten when only one entity exists under the topic.
- Promote to nested form later when siblings appear.

Examples:

- `technology/ai-coding-agents/claude-code/claude-opus-effort-levels.md`
- `games/resident-evil/resident-evil-4-remake/re4-remake-cheat-sheet.md`
- `shows/breaking-bad/walter-white.md`

For ordered content, list entries in in-story order. Use tables when values
differ by difficulty, playthrough, or randomised save.

## Frontmatter

```yaml
---
title: Page Title
aliases:
  - Alternate Name
type: concept | person | event | comparison | guide | reference | decision
tags:
  - category-tag
  - subtopic-tag
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

Rules:

- No `status`. Wiki pages are living documents.
- No `date`. Use `created` and `updated`.
- No `related`. Use inline `[[wikilinks]]`.
- No `sources` in frontmatter. Use `## Sources`.
- No colons in `title` or `aliases`.
- `type` describes knowledge shape, not topic.
- Use `playbook` or `pattern` when those fit better than listed examples.

## Page body template

```markdown
---
frontmatter...
---

# Page title

Opening summary paragraph.

## Section heading

Content with [[wikilinks]] to other wiki pages.

Use `[text](url)` for external links only.

---

## Sources

- [Article title](https://example.com/article) - retrieved YYYY-MM-DD
  - one-line note on what source covers

---

## Changelog

- **YYYY-MM-DD**
  - Created. Brief note on source/context.
```

## Conventions

- No index files.
- Search to find pages.
- Link liberally to existing and missing wiki pages.
- When a dedicated sub-page exists, link to it from the relevant section.
- Opening summaries only link sub-pages with no corresponding body section.
- Within a section, link in the heading or body, not both.
- Prefer inline links over heading links.
- Update contradictions to current truth.

## Splitting pages

Each page covers one focused concept, feature, or entity.

Split when:

- Topic has enough standalone content.
- Source covers multiple substantial topics.
- Main page remains a meaningful overview.

Do not split when:

- Content only makes sense together.
- Splitting would create shallow stub pages.

Aim for 2-5 pages from a large source, not 7-10.

## Ingest workflow

When the user asks to save knowledge to the wiki:

1. Identify durable reusable knowledge.
2. Choose or create the category and topic folder.
3. Write or update page frontmatter, body, sources, and changelog.
4. Check existing pages for useful cross-references.
5. Update changed pages' `updated` date.
6. Report created and updated pages.

Do not create a monthly ingestion log.

Do not ask for confirmation before ordinary wiki creates or updates.

## Changelog policy

Log meaningful changes:

- New page.
- New source that changes or extends knowledge.
- Fact correction.
- Structure change.
- Title or route change.
- Contradiction resolution.

Do not log noise:

- Formatting-only edits.
- Rephrases that preserve meaning.
- Word reduction that preserves meaning.
- Same-day appends on creation date.
