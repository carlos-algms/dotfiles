---
name: project-notes
description: >
  Search, create or update durable repo-specific notes in the user's Obsidian
  vault. Use for investigations, decisions, failures and coding lessons tied to
  a repository. Use `second-brain` for reusable or personal knowledge.
---

# Project notes

Store repo-specific provenance under `020-work/project-notes/<project-name>/`.

## Skill loading

| Operation                        | Required skills                                  |
| -------------------------------- | ------------------------------------------------ |
| Choose the project-notes route   | `project-notes` only                             |
| Search or read project notes     | Add `obsidian-mechanics`                         |
| Create or edit a project note    | Add `obsidian-mechanics` and `obsidian-markdown` |
| Discover or troubleshoot CLI use | Add `obsidian-cli`                               |

Load each skill before its first matching operation. If the operation changes,
load newly required skills before continuing. Never skip a required skill
because its rules seem familiar or time is short.

## Location

```text
020-work/project-notes/<project-name>/YYYY-MM-DD-<topic-slug>.md
```

- Derive the project name from the working-directory basename or context.
- Create folders as needed.
- Use date-first, globally unique filenames.

## Frontmatter

```yaml
---
title: Note Title
date: YYYY-MM-DD
tags:
  - project/project-name
  - topic-tag
type: project
status: active
aliases:
  - Alternate Name
---
```

- No colons in `title` or `aliases`.
- Put sources in `## Sources`, not frontmatter.
- Use inline wikilinks instead of `related`.
- Use `type: reference` for reusable material scoped to one project and
  `type: fleeting` for temporary captures.

## Content

- Add an H1 and include the date in it or the first paragraph.
- Record enough commands, errors, links and steps to reproduce an investigation.
- Cite file paths and line numbers when available.
- Apply the source convention from `obsidian-mechanics`.

### Coding lesson

```markdown
## YYYY-MM-DD - <symptom>

- Tool/cmd: `<failed command>`
- Error: <verbatim error>
- Cause: <root cause>
- Fix: <what worked>
- Lesson: <general rule>
- Tags: [tag-one, tag-two]
```

### Decision

```markdown
## YYYY-MM-DD - <decision>

- Status: accepted | superseded | deprecated
- Context: <constraint or trigger>
- Options: A) <...> B) <...>
- Decision: <choice>
- Rationale: <why>
- Consequences: <commitments>
- Revisit-when: <invalidation signal>
```

Give each lesson or decision its own date-prefixed note unless it belongs to the
same subject captured that day. Never rewrite decision history; create a new
note and link superseded decisions.
