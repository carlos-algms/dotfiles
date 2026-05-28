---
name: project-notes
description: >
  Durable repo-specific notes: project findings, investigations, decisions,
  coding lessons, failure analyses, and implementation findings. Distinct from
  the agent's native memory feature. Triggers: "save to project notes", "project
  notes", "save this to my notes", "note this for the project", "log this
  finding", "save project notes", "save this project finding", "log this
  investigation", "coding lesson", "project decision", "remember this for this
  repo", "document this bug investigation".
---

# Project notes

Save project notes, findings, and investigations as long-lasting repo-scoped
notes under `020-work/project-notes/<project-name>/`.

Use for repo-specific provenance: what happened, what was tried, why a decision
was made, and what future agents need to know.

For reusable wiki-style knowledge, use `second-brain`.

**MANDATORY:** Load these skills before any operation:

- `obsidian-mechanics` - vault path, file ops, sources convention, safety
- `obsidian-markdown` - Obsidian Flavoured Markdown syntax

## Where to save

```text
020-work/project-notes/<project-name>/YYYY-MM-DD-<topic-slug>.md
```

- Derive `<project-name>` from current working directory basename or context.
- Create folders as needed.
- File names are date-first for filesystem sort order.
- File names must still be globally unique vault-wide.

## Frontmatter

```yaml
---
title: Note Title Here
date: YYYY-MM-DD
tags:
  - project/project-name
  - topic-tag
type: project | reference | fleeting
status: active | completed | archived
aliases:
  - Alternate Name
---
```

Rules:

- No colons in `title` or `aliases`.
- No `sources` in frontmatter. Use `## Sources`.
- No `related`. Use inline `[[wikilinks]]`.
- Tags use nested hierarchy.
- `date` comes from file creation date or filename date prefix.
- `type: project` for project notes.
- `type: reference` for reusable snippets scoped to a project.
- `type: fleeting` for temporary captures.

## Content

- Title as H1.
- Include `YYYY-MM-DD` in H1 or first paragraph.
- Include findings, decisions, links, snippets, commands, and steps as needed.
- Use OFM per `obsidian-markdown`.
- Reference file links with line numbers when available.
- Investigations must be reproducible.
- Add `## Sources` per `obsidian-mechanics`.

## Coding lessons

When a note captures a coding lesson, use this body shape inside the
date-prefixed file:

```markdown
## YYYY-MM-DD - <one-line symptom>

- Tool/cmd: `<command that failed>`
- Error: <verbatim error>
- Cause: <real root cause>
- Fix: <what worked>
- Lesson: <generalised rule for next time>
- Tags: [test-runner, vitest, monorepo]
```

Each lesson gets its own date-prefixed note unless it is part of the same
subject captured on the same day.

## Decisions

When a note captures a decision, use this MADR-derived shape:

```markdown
## YYYY-MM-DD - <decision title>

- Status: accepted | superseded | deprecated
- Context: <constraint or trigger>
- Options: A) <...> B) <...>
- Decision: <chosen option>
- Rationale: <why this option over alternatives>
- Consequences: <what this commits us to>
- Revisit-when: <signal that would invalidate this>
```

Each decision gets its own date-prefixed note.

If a decision supersedes another, link the notes with wikilinks instead of
appending to one shared decision file.

Never edit past decision notes to rewrite history. Status changes flow forward
with a new decision note and links to superseded notes.
