---
name: Git and Source Control Management
description: Git protocols and best practices for commit messages and workflows
---

# GIT PROTOCOL

## Commit Messages

- Never use `git log` to infer message style based on history
- Use imperative mood, concise, clear, descriptive
- Standard markdown only, no special characters
- Title: ≤70 characters (including type, scope, parens, colon, spaces)
- Multi-change commits: bulleted list in description, each line ≤72 characters
- Never include: co-authors, sign-offs, AI attribution

### Standard Format

```
title

description....
```

### Conventional Commit Format

```
type(scope): subject

description...
```

**Rules:**

- Infer type from changes; if unable, ask and wait
- Scope sources: user-provided, ticket ID matching `[A-Z]{3}-[0-9]+`, branch
  name (if not main/master)
- If scope unavailable: ask and wait

## Commit Workflow

1. Check for confirmation tool availability
2. Check staged files; if none, ask to stage all modified files
3. Use `git add .` (not individual file names)
4. Generate commit message per protocol
5. Display full commit message in chat using triple backticks
6. Request approval via confirmation tool to commit, even if previously approved
