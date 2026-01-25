---
name: markdown-formatting
description: >
  Enforces strict Markdown formatting standards for ALL Markdown file
  operations. Use when creating, writing, or editing ANY Markdown file (.md),
  regardless of purpose (plans, documentation, README, notes, etc.). Ensures
  consistent formatting with 80-character line limit, proper spacing, correct
  list syntax, and clean hierarchical structure.
---

# Markdown Formatting Standards

Enforce consistent, professional Markdown formatting across all files.

## Core Formatting Rules

Apply these rules to **every Markdown file** you create or modify:

### Line Length

- **80 character maximum per line**
- Break long sentences naturally at word boundaries
- URLs and code blocks may exceed 80 chars when necessary
- Use soft wrapping for readability

### Spacing

- **One blank line** between paragraphs
- **One blank line** before and after headings
- **One blank line** before and after code blocks
- **One blank line** before and after lists
- **No trailing whitespace** at line ends
- **Single newline** at end of file

### Headings

- Use ATX-style headings (`#`, `##`, `###`)
- Space after hash marks: `## Heading` not `##Heading`
- Only one H1 (`#`) per document (typically title)
- Hierarchical structure: don't skip levels (## → ### not ## → ####)
- Sentence case preferred: "Core principles" not "Core Principles"
- No punctuation at end of headings
- Don't add punctuation in existing lines, if not asked to.

### Lists

#### Unordered Lists

- Use `-` (dash) for bullet points consistently
- Space after marker: `- Item` not `-Item`
- Indent nested items with 2 spaces

```md
- First level
  - Second level
    - Third level
```

#### Ordered Lists

- Use `1.` for all items (auto-numbering)
- Space after marker: `1. Item` not `1.Item`
- Indent nested items with 3 spaces (align with parent text)

```md
1. First item
   1. Nested item
   1. Another nested item
1. Second item
```

#### Task Lists (Checkboxes)

- Use `- [ ]` for incomplete tasks
- Use `- [x]` for completed tasks
- Space inside brackets and after closing bracket
- Correct: `- [ ] Task` or `- [x] Done`
- Wrong: `- []Task`, `-[ ]Task`, `- [X] Done`

### Code Blocks

- Use fenced code blocks with **short** language identifiers
- Common identifiers: `ts`, `tsx`, `js`, `jsx`, `py`, `bash`, `sh`, `md`, `json`
- **ALWAYS use `tsx`** when code contains JSX or React components
- Examples:

````md
```ts
const example = 'code here';
```
````

````md
```tsx
export function Button({ label }: { label: string }) {
  return <button>{label}</button>;
}
```
````

- Inline code uses single backticks: `variable` or `function()`
- No language identifier for plain text blocks

### Links and References

- Inline links: `[text](url)` with no space between `]` and `(`
- Reference links allowed for repeated URLs
- Descriptive link text (not "click here")

### Emphasis

- **Bold**: `**text**` (always use double asterisks)
- _Italic_: `_text_` (always use underscores)

### Horizontal Rules

- Use `---` (three dashes) on its own line
- Blank line before and after

## Content Guidelines

### Clarity and Conciseness

- No filler words or storytelling
- Short, clear sentences
- Active voice preferred
- One idea per paragraph

### Structure

- Logical flow from general to specific
- Related information grouped together
- Consistent section ordering across similar documents

## When to Apply

**ALWAYS** apply these formatting rules when:

- Creating new Markdown files
- Editing existing Markdown files
- Writing content to `.md` files
- Generating documentation
- Creating plans, notes, or reports
- Modifying README files

**NO EXCEPTIONS**: These rules apply regardless of file purpose or content type.

