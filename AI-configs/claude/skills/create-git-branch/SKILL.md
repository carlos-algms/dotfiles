---
name: create-git-branch
description: >
  Rules for creating new git branches - naming and workflow. Load on intent to
  start a branch. Triggers: "new branch", "create branch", "checkout -b",
  "switch -c", "start branch", "branch off", or Jira ticket as starting point.
---

# Create git branch

## Hard rules

- Never create without explicit user request.
- Branch off the default branch (`main`/`master`) unless user names a base.
- Pull base before branching.
- FORBIDDEN: `git checkout`, `git revert`, `git reset`. Use `git switch` /
  `git switch -c`.

## Naming

### With Jira ticket

```
cgomes/XXX-000-short-topic
```

- Ticket: `[A-Z]{3,}-[0-9]+`.
- Topic: 2-5 kebab-case words.

Example: `cgomes/XXX-1234-fix-login-redirect`.

### Without Jira ticket

```
scope/short-topic
```

- Scope: conventional type (`feat`, `fix`, `docs`, `test`, `chore`, `ci`) or
  affected module.
- Topic: 2-7 kebab-case words.

Example: `nvim/agentic-keymaps`.

### Shared rules

- ASCII, lowercase, kebab-case.
- No spaces, underscores, dots, trailing slash/dash.
- <= 60 chars total where practical.

## Workflow

1. Ticket vs no-ticket: Jira key/URL/id -> Jira form. Else scope form.  
   Unclear: ask.
2. Topic: 2-7 kebab words from user goal. Strip filler.
3. Scope (no-ticket only): most-affected module, or category fallback.  
   Unavailable: ask.
4. Show + create (same turn):
   - Output name as inline code.
   - Call `git switch -c <name>` immediately.
   - Never create without showing.
   - Never show and end turn without creating (unless draft-only).
5. Sync base when stale:

   ```bash
   git switch <base>
   git pull --ff-only
   git switch -c <name>
   ```

   Uncommitted work present: ask before switching.

## Draft-only path

User says "just suggest", "don't create yet":

- Output name as inline code.
- Do NOT call `git switch -c`.

Visibility gate (step 4) skipped.
