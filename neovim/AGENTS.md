# Neovim Configuration

Neovim `v0.11+`. Answers must be valid for that version or higher.

Reading Neovim help docs / Lua APIs: load the `neovim-documentation` skill.

## Architecture

- Entry: `neovim/nvim/init.lua` (leader `<space>` and `,`, bootstraps
  lazy.nvim).
- Plugin configs: `neovim/nvim/lua/plugins/<name>.lua`, one file per
  plugin/feature.
- Helpers: `neovim/nvim/lua/helpers/`. Snippets: `neovim/nvim/lua/snippets/`.
- LSP custom configs: `neovim/nvim/lsp/` (merged on top of `mason-lspconfig`
  defaults, not overrides).
- Thread limiting: fallback for shared hosting via `THREAD_LIMITED_USERS` env
  var.

## Reading plugin source

For source, README, or any code file of a plugin:

1. **First**: read from the local lazy.nvim clone:
   `~/.local/share/nvim/lazy/<plugin>/`. All installed plugins live there.
2. **Fallback** (plugin not installed, or exploring a different repo): fetch
   the GitHub raw URL, not the HTML page.

   - HTML: `https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/init.lua`
   - Raw:  `https://raw.githubusercontent.com/folke/snacks.nvim/main/lua/snacks/picker/init.lua`

   ```bash
   curl -sfL https://raw.githubusercontent.com/folke/snacks.nvim/main/lua/snacks/picker/init.lua
   ```

## Most important plugins

- **Agentic.nvim** (`neovim/nvim/lua/plugins/agentic.lua`)
  - Main chat interface. My plugin, talks to AI models via Claude Agent
    Coding Protocol (ACP). Supports Claude, OpenCode, others.
  - Repo: https://github.com/carlos-algms/agentic.nvim
  - Local dev clone (when NOT on ssh): `~/projects/agentic.nvim`.

- **Snacks.nvim** (`neovim/nvim/lua/plugins/snacks.lua`)
  - File pickers, project-wide search/grep, and many other tools. Each tool
    has its own doc page linked from the main README. The one I use most is
    the picker.
  - README: https://github.com/folke/snacks.nvim/blob/main/README.md
  - Picker docs: https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
  - Local clone: `~/.local/share/nvim/lazy/snacks.nvim`

- **Mason + LSP** (`neovim/nvim/lua/plugins/mason.lua`)
  - All LSP servers, DAP, linters, formatters installed via Mason, never
    globally.
  - Config style: `vim.lsp.config('…')`, enabled automatically by
    `mason-lspconfig.nvim`.
  - Custom per-server config in `neovim/nvim/lsp/`, merged on top of
    `mason-lspconfig` defaults (not an override).
  - README: https://github.com/mason-org/mason.nvim/blob/main/README.md
  - mason-lspconfig: https://github.com/mason-org/mason-lspconfig.nvim

## Conventions

- Use `vim.keymap.set` for keymaps. Always pass `desc`.
