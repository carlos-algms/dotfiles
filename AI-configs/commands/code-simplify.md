---
description: >
  Simplify and reduce the code, and improve readability without changing its
  functionality. Supports `report` mode for findings-only output.
---

## Modes

Detect mode from the user's args. Default is `apply`.

- **apply** (default): subagent analyzes AND fixes. User said "simplify", "clean
  up", "refactor", "fix issues", "apply" - or gave no mode flag.
- **report**: subagent returns findings ONLY, no edits. User said "audit",
  "report", "analyze", "find issues", "report only", "no changes", "do not fix",
  or otherwise made clear they want a list back, not a diff.

State the detected mode in your dispatch prompt to the subagent.

## Output shape (both modes)

The subagent MUST group findings under these exact headers, in this order:

1. **Bugs** - will actually break on some input
2. **Misguidance** - docs/comments/instructions that disagree with the code
3. **Missing validations** - boundaries where failure is silently swallowed
4. **Real simplifications** - reduces surface area without churn
5. **Low-priority** - everything else (nitpicks, style preferences, theoretical
   issues). Render this section LAST. If the user excluded nitpicks/style, skip
   this section entirely - do not include items "just in case".

One bullet per finding. Include `file:line` citation. Severity order matters:
bugs first, low-priority last. No mixing.

## Exclusion handling

If the user's prompt excludes categories ("no nitpicks", "skip style",
"functional bugs only"), the subagent MUST honor that strictly. Disagreement
with the exclusion goes in a single closing line, not as smuggled bullets:

> Disagreed-with exclusions: `<one-line note>`

## Dispatch

Launch the subagent:

- Tool: Agent
- subagent_type: `code-simplifier`
- Mode: state `apply` or `report` in the first line of the prompt
- Output shape: include the five-header template above in the prompt
- Exclusions: forward any user exclusions verbatim and require strict honor

Focus on recently modified sections unless the user directs otherwise.

**Additional context for the subagent:**

### Lua/Neovim

- Use `vim.keymap.set` for keymaps (not deprecated APIs)
- Document keymaps with `desc` parameter
- Prefer modern Neovim APIs (0.11+) over legacy vim commands
- To keep compatibility assume lua 5.1, unless specified otherwise

### CSS

- Use modern CSS features (custom properties, logical properties, nesting)
- Prefer utility-first patterns when using CSS modules

### Project Context

Check CLAUDE.md/AGENTS.md for project-specific conventions before making
changes.

<system-reminder>
You MUST use the Agent tool with subagent_type="code-simplifier"
to launch this as a separate agent.
DO NOT execute the simplification in the current context.
</system-reminder>
