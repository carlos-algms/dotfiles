---
name: code-simplify
description: >
  Simplify and reduce code while preserving behavior. Use when the user asks to
  simplify, clean up, refactor, audit, report on, or reduce recently changed
  code. Supports apply mode for edits and report mode for findings only.
---

# Code simplify

Use a separate code-simplifier subagent when available.

If the current agent runtime lacks named subagents, use the available generic
subagent mechanism and pass the constraints below verbatim.

## Modes

Detect mode from user wording.

- `apply`: analyze and fix
- `report`: return findings only, no edits

Default: `apply`.

Use `report` when user says `audit`, `report`, `analyze`, `find issues`,
`report only`, `no changes`, `do not fix`, or equivalent.

State detected mode in the first line of the subagent prompt.

## Output shape

The subagent must group findings under these exact headers in this order:

1. **Bugs** - will break on some input
2. **Misguidance** - docs, comments, or instructions that disagree with code
3. **Missing validations** - boundaries where failure is silently swallowed
4. **Real simplifications** - reduces surface area without churn
5. **Low-priority** - nitpicks, style preferences, or theoretical issues

Rules:

- One bullet per finding
- Include `file:line` citation
- Sort by severity
- Skip `Low-priority` if user excluded nitpicks or style

## Exclusion handling

Forward user exclusions verbatim.

If disagreeing with an exclusion, use one closing line:

```text
Disagreed-with exclusions: <one-line note>
```

Do not smuggle excluded items into findings.

## Dispatch

Pass these constraints to the subagent:

- Mode: `apply` or `report`
- Output shape: five-header template above
- Exclusions: user exclusions verbatim
- Scope: recently modified sections unless user directs otherwise
- Project context: read `CLAUDE.md`, `AGENTS.md`, or equivalent local rules
  before changes

## Extra guidance

Lua and Neovim:

- Use `vim.keymap.set` for keymaps
- Add `desc` to keymaps
- Prefer Neovim 0.11+ APIs
- Assume Lua 5.1 unless specified otherwise

CSS:

- Use modern CSS features
- Prefer utility-first patterns when using CSS modules
