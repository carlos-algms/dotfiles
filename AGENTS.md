# Dotfiles

## Repository Overview

Personal dotfiles repository for cross-platform shell, terminal, and editor
configuration.

Supports Linux, macOS, and Windows environments with automated installation
scripts.

## Neovim Configuration

I use Neovim `v0.11+`, so I can use the most modern configuration options and
plugins, also newest Lua features. Make sure your answers are valid for this
version or higher.

Neovim documentation index is `https://neovim.io/doc/user/` from where you
should be able to find all other relevant documentation links.

### Architecture

- **Plugin manager**: lazy.nvim (auto-bootstrapped in `init.lua`)
- **Configuration layout**: Modular Lua structure
  - `neovim/nvim/init.lua` - Entry point, sets leader keys (`<space>` and `,`),
    loads lazy.nvim
  - `neovim/nvim/lua/` - All configuration modules
  - `neovim/nvim/lua/plugins/` - 36+ plugin configuration files (one file per
    plugin/feature, with possible many plugins per file)
  - `neovim/nvim/lua/helpers/` - Utility functions created by me
  - `neovim/nvim/lua/snippets/` - Custom code snippets for many languages

### Plugin Management

- Plugins are organized by feature (e.g., `git.lua`, `lspsaga.lua`, `dap.lua`)
- No centralized plugin list - each file in `plugins/` is auto-loaded by
  lazy.nvim automatically
- Thread limiting: Configuration includes fallback for shared hosting
  environments (checks `THREAD_LIMITED_USERS` env var)

### Most important plugins

You can use any fetch tool to read the code from GitHub, you must convert the
url to the raw static content format to focus on the code only, not Github HTML.

- **Avante.nvim**
  - Configured at `neovim/nvim/lua/plugins/avante.lua`
  - Provides a Chat interface to interact with AI models (like Copilot, GPT-5,
    Gemini, Claude) and tool permissions and execution interface, like the
    Cursor IDE.
  - It's documentation page is:
    https://github.com/yetone/avante.nvim/blob/main/README.md
  - It's default configuration can be found at
    https://github.com/yetone/avante.nvim/blob/main/lua/avante/config.lua
  - If these URLs aren't enough, you can investigate the local codebase at
    `~/.local/share/nvim/lazy/avante.nvim`

- **Snacks.nvim**
  - Configured at `neovim/nvim/lua/plugins/snacks.lua`
  - Provides file pickers, project wise search and grep, and many other tools
  - Documentation: https://github.com/folke/snacks.nvim/blob/main/README.md
    - However, each tool has it's onw documentation page linked from the main
      readme.
    - The one I use the most is the `picke`:
      https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
  - It's local codebase is at `~/.local/share/nvim/lazy/snacks.nvim`

- **Mason and LSP Config**
  - Configured at `neovim/nvim/lua/plugins/mason.lua`
  - Provides utilities to install and manage LSP servers, DAP servers, linters,
    and formatters.
  - Documentation: https://github.com/mason-org/mason.nvim/blob/main/README.md
  - My LSPs are all installed by Mason, not globally
  - I use `vim.lsp.config('…')`
  - Configurations are enabled automatically by `mason-lspconfig.nvim`
    - Documentation: https://github.com/mason-org/mason-lspconfig.nvim
  - Custom config for each LSP server is in `neovim/nvim/lsp/` folder
    - Custom configs are merged on top of default configs provided by
      `mason-lspconfig.nvim`, it's not an override.

## Shell Configuration

### Aliases System

Modular alias files in `shell/common/`:

- `aliases.sh` - Core aliases (ff/fdir for file search, v for nvim, custom
  rsync, zoxide integration)
- `aliases_git.sh` - Git shortcuts
- `aliases_ls.sh` - Directory listing (uses eza when available)
- `aliases_docker.sh` - Docker shortcuts
- `aliases_grep.sh` - Search aliases

### Tool Detection Pattern

Shell scripts check for modern alternatives:

- `fd` over `find` (faster, respects .gitignore)
- `rg` over `grep` (faster, better defaults, also respects .gitignore)
- `nvim` over `vim` over `vi`

## AI Configuration

Shared AI assistant configurations in `AI-configs/`:

- `base-ai-instructions.md` - Shared instructions for all AI agents, it's either
  referenced by dedicated AI config file, or symlinked to AGENTS.md, or
  GEMINI.md, globally, not per project.
- Platform-specific configs for Claude, Gemini, OpenCode, and Crush
- Installation creates symlinks to
  - `~/.claude/`
  - `~/.gemini/`
  - `~/.config/opencode`
  - etc.

## File Operations Protocol

### When modifying shell scripts in this project:

- Always source logging functions from `shell/common/01_logging.sh`
- Use `e_header`, `e_success`, `e_error`, `e_arrow` for consistent output
- Check OS with `IS_WIN`, `IS_MAC`, `IS_LINUX` variables (source `00_os.sh`)
- Make scripts executable with `chmod u+x`
- Test symlink creation doesn't overwrite without backup

### When modifying Neovim configs:

- Plugin configs go in separate files in `neovim/nvim/lua/plugins/`
- Use `vim.keymap.set` for keymaps (see `remap.lua` for patterns)
- Document keymaps with `desc` parameter
- Follow existing require() pattern for module imports
