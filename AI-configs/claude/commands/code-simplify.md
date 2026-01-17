---
description: >
  Simplify and reduce the code, and improve readability without changing its
  functionality
---

Launch the code-simplifier subagent to analyze and simplify the code, focusing
on recently modified sections unless directed otherwise.

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
You MUST use the Task tool with subagent_type="code-simplifier:code-simplifier" 
to launch this as a separate agent. 
DO NOT execute the simplification in the current context.
</system-reminder>
