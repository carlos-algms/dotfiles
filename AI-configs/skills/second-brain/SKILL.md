---
name: second-brain
description: >
  Second-brain long-term wiki notes and personal documentation. High-priority
  over generic Obsidian skills for vault content routing. Load this first when
  the user asks to search, read, create, update, move, or organize notes in
  their vault. Routes reusable knowledge and vault-wide personal docs. Triggers:
  "second brain", "my vault", "Obsidian", "my notes", "my wiki", "save to second
  brain", "what do I have on", "find notes about", "quick note", "daily note".
---

# Second brain

Route long-term Obsidian vault work before loading route-specific details.

Do not handle project-notes requests. The `project-notes` skill owns
repo-specific findings, investigations, decisions, and coding lessons.

**MANDATORY:** Load these skills before any operation:

- `obsidian-mechanics` - vault path, file ops, sources convention, safety
- `obsidian-markdown` - Obsidian Flavoured Markdown syntax

## Route selection

- Reusable knowledge -> `references/wiki.md`
- Personal docs, quick captures, daily notes, travel, people, admin -> inline
  vault-wide rules below

Load only the selected route reference.

If multiple routes fit, prefer:

1. `project-notes` skill when tied to a repo, investigation, command, failure,
   implementation decision, or coding lesson.
2. `wiki` when reusable outside one repo or personal context.
3. Vault-wide rules for everything else.

## Vault-wide rules

Use these for content that is not wiki and not project notes.

- Search the vault before choosing a destination.
- Prefer existing folders and nearby note conventions.
- Use `011-personal/` for personal documentation.
- Use `001-Quick-Notes/` for low-context captures and inbox notes.
- Use `010-Daily/` only for date-scoped daily notes.
- Ask when multiple destinations are plausible.
- Create folders when needed for durable ownership or lifecycle.
- Example folders are guidance, not a closed taxonomy.

### Dynamic routing

Route content units, not imported headings.

- Profile: stable entity facts
- Case: personal process, timeline, documents, decisions and outcome
- Reference: reusable knowledge
- Raw source: input only unless the user asks to archive, attach or quote

Rules:

- People use `011-personal/people/<common-person-slug>/<common-person-slug>.md`
- Country cases use
  `011-personal/countries/<country>/<domain>/<stable-case>/<unique-note>.md`
- Country references use
  `100-wiki/countries/<country>/<domain>/<unique-reference>.md`
- Start with one note per case.
- Keep status, outcome, decision and action plan together for one episode.
- Split only for independent lifecycle, owner, update cadence or reuse.
- Link personal case notes to wiki reference notes.
- Do not duplicate reusable rules in personal notes.
- Put dates in filenames, not stable folders.
- Person paths use first name and one surname by default.
- Full legal names and variants go in aliases.

### Example structure

Add folders when the same routing rules call for them.

```text
011-personal/
  people/
    <person-slug>/
      <person-slug>.md
  countries/
    germany/
      visa/
        renewal/
          <unique-case-note>.md

100-wiki/
  countries/
    germany/
      immigration/
        <unique-reference-note>.md
```

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

All note filenames must be globally unique vault-wide because Obsidian wikilinks
resolve by filename, not folder path.

Rules:

- Folders organise context
- Filenames identify the note
- Do not use `index.md`
- Use a descriptive slug even when folder names already provide context

Pattern:

```text
<folder-context>/<globally-unique-note-slug>.md
```
