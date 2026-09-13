---
name: obsidian-mechanics
description: >
  Personal vault paths, safety rules and file-operation choices. Load when
  accessing or mutating the user's Obsidian vault. Load `obsidian-cli` only to
  discover, verify or troubleshoot command syntax. Load `obsidian-markdown` only
  before creating or editing Markdown content.
---

# Obsidian mechanics

## Skill gate

- Direct search/read: this skill only.
- Direct Markdown create/edit: add `obsidian-markdown`.
- Command specified by this skill: run it directly.
- Unknown, uncertain or failed CLI command: add `obsidian-cli`.
- `.base` create/edit: add `obsidian-bases`.
- `.canvas` create/edit: add `json-canvas`.

If the operation changes, load the newly required skill before continuing. Never
skip a required skill because its rules seem familiar or time is short.

## Vault context

- OneDrive sync, no git: avoid destructive edits and track changed files.
- No build, tests or package manager.
- Strict line breaks are enabled.
- Attachments: `999-system/Attachments/`
- Community plugins: `.obsidian/community-plugins.json`

```text
001-Quick-Notes/                inbox
010-Daily/                      daily notes
011-personal/                   personal documentation
020-work/project-notes/<name>/  project notes
100-wiki/                       reusable knowledge
999-system/                     internals, archive, attachments, templates
```

Content routing belongs to `second-brain` or `project-notes`.

## Resolve the vault once

```bash
VAULT=$(obsidian vault info=path)
VAULT=${VAULT:-$SECOND_BRAIN_PATH}
```

Cache the result for the session. Assume Obsidian is open. If a CLI command
fails, run `open -a Obsidian`, wait briefly and retry once. Use
`$SECOND_BRAIN_PATH` when the GUI is unavailable.

## Choose the operation

Use direct file tools for creating, reading and editing files. They provide
reviewable diffs, avoid shell escaping and work without Obsidian.

Use the CLI only for vault-aware behaviour:

- search context, backlinks, outgoing links and outlines
- rename or move with wikilink updates
- property updates
- history and restore
- orphan, dead-end and unresolved-link checks
- saved Base queries

Run commands specified below directly. For other commands, unclear flags or a
failed invocation, load `obsidian-cli` and consult `obsidian help <command>`.

### Search and read

```bash
obsidian search query="auth middleware"
obsidian search:context query="auth middleware"
obsidian search query="e2e tests" path="<folder>"
obsidian files folder="<folder>"
obsidian read path="<folder>/<note>.md"
```

For direct fallback or bulk search, use file tools against `$VAULT`.

### Rename and move

Prefer `rename` when only the filename changes so Obsidian updates wikilinks.

```bash
obsidian rename path="<folder>/old.md" name="new.md"
obsidian move path="<folder>/<note>.md" to="<other-folder>/"
obsidian move path="<folder>/<note>.md" to="<other-folder>/new.md"
```

Use `obsidian delete` for soft deletion. Never add `permanent` unless the user
explicitly requests irreversible deletion.

### Links, properties and hygiene

```bash
obsidian backlinks path="<folder>/<note>.md"
obsidian links path="<folder>/<note>.md"
obsidian outline path="<folder>/<note>.md" format=md
obsidian property:set name="status" value="done" path="<folder>/<note>.md"
obsidian orphans
obsidian deadends
obsidian unresolved verbose
```

Use `obsidian base:query file="<base>" view="<view>" format=json` for a saved
Base. Use one-off shell composition for one-off multi-hop graph queries.

### History

```bash
obsidian history path="<folder>/<note>.md"
obsidian history:read path="<folder>/<note>.md" version=1
obsidian diff path="<folder>/<note>.md" from=1 to=2
obsidian history:restore path="<folder>/<note>.md" version=1
```

Inspect a version before restoring it.

## Vault writing conventions

These apply only when writing Markdown; load `obsidian-markdown` first.

- 80-character lines, strict line breaks and British English
- Dashes for unordered lists; no em or en dashes
- Short code-fence identifiers such as `md`, `ts`, `py` and `bash`
- Wikilinks for vault files; Markdown links for external URLs
- No colons in wikilink display text
- In `related` frontmatter, use quoted pipe links:
  `"[[filename|Display Title]]"`

Basename-only wikilinks may be ambiguous; Obsidian also supports
folder-qualified links. Aliases affect suggestions, not link targets.

## Sources

For notes that cite sources:

- Put `## Sources` at the end, immediately before `## Changelog` when present.
- Precede either heading with `---`.
- Never put sources in frontmatter.
- For sources consulted today, append ` - retrieved YYYY-MM-DD`.
- Add one nested bullet describing what each source supports.
- Preserve older entries until they are consulted again.

```markdown
---

## Sources

- [Article](https://example.com) - retrieved YYYY-MM-DD
  - claim or topic supported by the article

---

## Changelog
```
