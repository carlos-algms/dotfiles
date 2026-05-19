---
name: second-brain
description: >
  Second-brain long-term wiki notes and personal documentation. High-priority
  over generic Obsidian skills for vault content routing. Load this first when
  the user asks to search, read, create, update, move, or organize notes in
  their vault. Routes reusable knowledge and vault-wide personal docs. Triggers:
  "second brain", "my vault", "Obsidian", "my notes", "my wiki", "save to
  second brain", "what do I have on", "find notes about", "quick note",
  "daily note".
---

# Second brain

Route long-term Obsidian vault work before loading route-specific details.

Do not handle project-memory requests. The `project-memory` skill owns
repo-specific findings, investigations, decisions, and coding lessons.

**MANDATORY:** Load these skills before any operation:

- `obsidian-mechanics` - vault path, file ops, sources convention, safety
- `markdown-formatting` - markdown style
- `obsidian-markdown` - Obsidian Flavoured Markdown syntax

## Route selection

- Reusable knowledge -> `references/wiki.md`
- Personal docs, quick captures, daily notes, travel, family, admin -> inline
  vault-wide rules below

Load only the selected route reference.

If multiple routes fit, prefer:

1. `project-memory` skill when tied to a repo, investigation, command, failure,
   implementation decision, or coding lesson.
2. `wiki` when reusable outside one repo or personal context.
3. Vault-wide rules for everything else.

## Vault-wide rules

Use these for content that is not wiki and not project memory.

- Search the vault before choosing a destination.
- Prefer existing folders and nearby note conventions.
- Use `011-personal/` for personal documentation.
- Use `001-Quick-Notes/` for low-context captures and inbox notes.
- Use `010-Daily/` only for date-scoped daily notes.
- Ask only when multiple destinations are plausible and materially different.
- Create new folders only when no existing home fits.
- Do not create specialised routes for travel, visa, residency, or admin until
  repeated use proves a need.

## Root folders

```text
001-Quick-Notes/
010-Daily/
011-personal/
020-work/
100-wiki/
999-system/
```

Root folder numbers are visual sorting only. Do not include them in skill
trigger text.

## Filenames

All note filenames must be globally unique vault-wide because Obsidian
wikilinks resolve by filename, not folder path.

Good:

```text
011-personal/countries/germany/visa/renew-2026/germany-visa-renew-2026.md
011-personal/people/carlos-gomes/carlos-gomes.md
```

Bad:

```text
011-personal/countries/germany/visa/renew-2026/renew-2026.md
011-personal/people/carlos-gomes/index.md
```

Folders organize. Filenames identify.
