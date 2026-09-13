---
name: second-brain
description: >
  Route searches, reads and note management in the user's personal Obsidian
  vault. Load first for personal-vault content routing. Do not load for generic
  Obsidian questions, plugin development, .base files or .canvas files unless
  personal note routing is also required.
---

# Second brain

Route personal vault work. The `project-notes` skill owns repo-specific
findings, investigations, decisions and coding lessons.

## Skill loading

Classify the next operation before using a vault tool:

| Operation                        | Required skills                                              |
| -------------------------------- | ------------------------------------------------------------ |
| Classify the content route       | `second-brain` only                                          |
| Search, read or choose a file    | `second-brain`, `obsidian-mechanics`                         |
| Create or edit Markdown          | `second-brain`, `obsidian-mechanics`, `obsidian-markdown`    |
| Discover or troubleshoot CLI use | Add `obsidian-cli`                                           |
| Create or edit `.base`           | `obsidian-bases`, plus `obsidian-mechanics` for vault access |
| Create or edit `.canvas`         | `json-canvas`, plus `obsidian-mechanics` for vault access    |

Requirements are conditional:

- Load each required skill before its first matching operation.
- Do not load a skill merely because the task concerns Obsidian.
- If the operation changes, load newly required skills before continuing.
- Never skip a required skill because its rules seem familiar or time is short.

## Route selection

- Repo-specific provenance or lessons -> `project-notes`
- Reusable knowledge -> load `references/wiki.md`
- Personal docs, captures, daily notes, travel, people or admin -> rules below

If multiple routes fit, prefer project notes, then wiki, then personal docs.
Load only the selected route reference.

## Personal routes

- Search before choosing a destination.
- `001-Quick-Notes/`: low-context captures and inbox notes
- `010-Daily/`: date-scoped daily notes
- `011-personal/`: personal documentation
- Ask when multiple destinations remain plausible.
- Add folders for durable ownership or lifecycle, not imported headings.

Content units:

- Profile: stable entity facts
- Case: one process, timeline, decision and outcome
- Reference: knowledge reusable outside the personal case
- Raw source: input only unless the user requests archival or quotation

Paths:

```text
011-personal/people/<person-slug>/<person-slug>.md
011-personal/countries/<country>/<domain>/<stable-case>/<unique-note>.md
100-wiki/countries/<country>/<domain>/<unique-reference>.md
```

- Start with one note per case.
- Split only for an independent lifecycle, owner, update cadence or reuse.
- Link personal cases to reusable wiki references instead of duplicating rules.
- Put dates in filenames, not stable folders.
- Person slugs use first name and one surname by default; put full names and
  variants in aliases.

## Filenames

Filenames must be globally unique by vault convention. This avoids ambiguous
basename-only links and keeps concise wikilinks reliable.

- Folders provide context; filenames identify notes.
- Do not use `index.md`.
- Use a descriptive slug even when the folder supplies similar context.
