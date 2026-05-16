---
name: neovim-documentation
description: >
  Load before any Neovim help, documentation, or Lua API lookup. Defines how to
  read Neovim docs from disk or online. Reading docs via `nvim --headless` or
  any other `nvim` subprocess is FORBIDDEN;  Triggers: "Neovim docs", `:help`,
  `:h <topic>`, `runtime/doc`, Neovim Lua API lookups, "how does Neovim do X"
  questions.
---

# Neovim Documentation Files and help docs

**CRITICAL**: Reading docs via `nvim` / `nvim --headless` is forbidden (hangs,
races, disrupts the dev env). Read doc files directly.

## Neovim Documentation Lookup Strategy:

Always prefer reading local documentation files directly from the Neovim runtime
path, because they reflect the exact version installed on the system.

Common path patterns for discovery:

- **macOS (Homebrew):**
  - Runtime docs: `/opt/homebrew/Cellar/neovim/*/share/nvim/runtime/doc/`
  - Note: We don't need the exact version, just use the wildcard `*` to match
    the installed version
- **Linux (Snap):** `/snap/nvim/current/usr/bin/nvim`
  - Runtime docs: `/snap/nvim/current/usr/share/nvim/runtime/doc/`

**If OS unknown or path patterns above miss:** discover the install root:

```bash
realpath $(which nvim)
```

Then derive `runtime/doc/` from that path.

**If local lookup fails:** Use GitHub raw URLs (least preferred)

```bash
curl -sfL https://raw.githubusercontent.com/neovim/neovim/refs/tags/v<version>/runtime/doc/<doc-name>.txt
```

Flags: `-s` silent, `-f` fail on HTTP error (catches wrong tag), `-L` follow
redirects.

**Tip:** Do not assume a file contains what you need, use `rg`, or `grep` on the
`runtime/doc` folder to find the file containing needed info.

Example - search across the runtime docs:

```bash
rg "colors_name" /opt/homebrew/Cellar/neovim/*/share/nvim/runtime/doc/
```
