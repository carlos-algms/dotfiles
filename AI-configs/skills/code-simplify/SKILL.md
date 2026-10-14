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

Priority: correct, safe, tested, lean. Group findings under these exact headers
in this order. Skip empty groups:

1. **Must fix** - bugs, security holes, data loss
2. **Should fix** - misguidance (docs, comments, or instructions that disagree
   with code), missing validations (failure silently swallowed), risky logic
   without a test, lean findings
3. **Nice to have** - shorter forms. Only when the user asks for nitpicks

Lean findings:

- delete: dead code, unused options, flags, config, speculative features
- reuse: the repo already has this helper; name the path
- stdlib/native: the standard library or platform already does it
- yagni: interface with one implementation, pass-through wrapper, config nobody
  sets
- merge: near-copies that must change together
- split: one function doing unrelated jobs. Split by job, never by line count

Rules:

- Number findings across all groups, so the user can say "fix 2 and 5"
- Each finding: bold title, `file:line`, then What, Problem, Fix, If skipped;
  one sentence each
- Every finding needs a concrete case: this input leads to this wrong result. No
  case, no finding
- Before calling code unused, grep the whole tree, including tests, fixtures,
  config, and string or dynamic references
- Propose the smallest fix. Prefer fixes that delete code. Never add layers,
  config, or frameworks
- A `shortcut: <limit>, <upgrade>` comment is a decision, not a finding
- No style taste, no "consider", no vague worries

End with:

- `Verdict:` one line: ship, or what to fix first
- `Lean: -<N> lines possible.` when lean findings exist

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
- Output shape: three-group template above
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
