---
name: obsidian-markdown
description: >
  Author or edit Obsidian-specific Markdown syntax such as wikilinks, embeds,
  callouts and properties. Do not load for routing, searching, reading, renaming
  or moving notes unless Markdown content will be changed.
---

# Obsidian Flavoured Markdown

Use standard Markdown normally. Apply the extensions below only when the note
needs them; do not add frontmatter, links, embeds or callouts by default.

## Wikilinks

Use wikilinks for vault content and Markdown links for external URLs.

<!-- prettier-ignore -->
```markdown
[[Note Name]]
[[Note Name|Display Text]]
[[Note Name#Heading]]
[[Note Name#^block-id]]
[[#Heading in same note]]
```

Append `^block-id` to a paragraph. Put it on its own line after a list or
blockquote. Obsidian resolves links by filename; aliases affect suggestions, not
resolution.

## Embeds

Prefix a wikilink with `!`:

```markdown
![[Note Name]]
![[Note Name#Heading]]
![[image.png|300]]
![[document.pdf#page=3]]
```

Load `references/EMBEDS.md` only for other media, search embeds or sizing
details.

## Callouts

<!-- prettier-ignore -->
```markdown
> [!note]
> Content.

> [!warning] Custom title
> Content.

> [!faq]- Collapsed
> Content.
```

Load `references/CALLOUTS.md` only for aliases, nesting or custom callouts.

## Properties

```yaml
---
title: My Note
tags:
  - project
aliases:
  - Alternate Name
cssclasses:
  - custom-class
---
```

Load `references/PROPERTIES.md` only when selecting property types or handling
advanced property and tag syntax.

## Other extensions

<!-- prettier-ignore -->
```markdown
#nested/tag
==highlighted text==
Visible text %%hidden text%%

%%
Hidden block
%%
```

Obsidian also supports standard fenced Mermaid, LaTeX and footnote syntax; use
normal Markdown knowledge for those.
