---
name: markdown-formatting
description: >
  Load before any `.md` or `.markdown` operation: create, edit, append, rewrite,
  review, format, or generate Markdown. Applies to READMEs, docs, notes,
  reports, specs, RFCs, ADRs, plans, changelogs, and agent-authored Markdown.
  Required because Markdown style is file-wide, not task-local.
---

# Markdown formatting

Apply these rules to every Markdown file you create or modify.

## Baseline

- Follow CommonMark/GFM syntax
- Prefer markdownlint-compatible formatting
- Match stricter local project conventions when present
- Keep docs short, direct, and source-readable
- Preserve existing content unless the task asks for content changes

## Lines and spacing

- Wrap prose at 80 characters
- Let URLs and code exceed 80 characters when needed
- Use one blank line around headings, lists, tables, and fences
- Use one blank line between paragraphs
- Remove trailing whitespace
- End files with one newline

## Headings

- Use one H1 per file
- Use ATX headings, (`#`, `##`, ...)
- Add one space after `#`
- Do not skip levels
- Use sentence case
- Use unique, complete names
- Do not end headings with punctuation

## Lists

- Use `-` for unordered lists
- Use ordered lists only when order matters
- Use sequential numbers for ordered lists
- Renumber ordered lists after inserting, deleting, or moving items
- Do not use repeated `1.` for ordered lists, use sequenced numbers
- Do not mix ordered-list styles inside one list
- Use one space after list markers
- Indent nested unordered items by two spaces
- Indent nested ordered items to align with parent text
- Do not end list items with punctuation
- Keep punctuation only when required by syntax or quoted text
- Do not create one-item lists

## Code

- Use fenced code blocks
- Declare language on every fence
- Use `text` for plain text
- Use `markdown`, not `md`
- Use `tsx` for JSX or React
- Use short identifiers otherwise: `ts`, `js`, `py`, `sh`, `json`
- For nested fences, make the outer fence longer than any inner fence
- Use four backticks outside a block that contains triple-backtick fences
- Increase outer fence length again for deeper nesting
- Set outer language to the content shown, usually `markdown` or `text`
- Never escape inner backticks
- Use inline code for commands, paths, symbols, and file extensions

## Links

- Use descriptive link text
- Use inline links for single-use URLs
- Use reference links for repeated URLs
- Wrap bare URLs in angle brackets when the URL is the link text

## Tables

- Use tables only for repeated comparable values
- Prefer lists when values do not vary by row
- Align pipes by column
- Pad cells with one space
- Include leading and trailing pipes
- Use one blank line before and after tables
