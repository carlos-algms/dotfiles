# Dotfiles

## Repository Overview

Personal dotfiles repository for cross-platform shell, terminal, and editor
configuration.

Supports Linux, macOS, and Windows environments with automated installation
scripts.

## Neovim Configuration

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
