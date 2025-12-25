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

**IMPORTANT**: For dealing with neovim native features and APIs, refer to the
official docs. Common documentation files include:

- api.txt - Neovim Lua API
- autocmd.txt - Autocommands
- change.txt - Changing text
- channel.txt - Channels and jobs
- cmdline.txt - Command-line editing
- diagnostic.txt - Diagnostics
- diff.txt - Diff mode
- editing.txt - Editing files
- fold.txt - Folding
- indent.txt - Indentation
- insert.txt - Insert mode
- job_control.txt - Job control
- lsp.txt - LSP client
- lua.txt - Lua API
- lua-guide.txt - Lua guide
- map.txt - Key mapping
- motion.txt - Motion commands
- options.txt - Options
- pattern.txt - Patterns and search
- quickfix.txt - Quickfix and location lists
- syntax.txt - Syntax highlighting
- tabpage.txt - Tab pages
- terminal.txt - Terminal emulator
- treesitter.txt - Treesitter
- ui.txt - UI
- undo.txt - Undo and redo
- windows.txt - Windows
- various.txt - Various commands

Use GitHub raw URLs or local paths (see section below) to access these files.

### 🚨 NEVER Execute `nvim` to Read Help Manuals

**CRITICAL**: Do NOT run `nvim --headless` or any other `nvim` command to read
help documentation. Use direct file access instead.

**Documentation Lookup Strategy:**

Follow this priority order to locate Neovim documentation:

1. **If OS and Neovim version are known from context:**
   - **macOS (Homebrew assumed):** Compose path directly

     ```
     /opt/homebrew/Cellar/neovim/<version>/share/nvim/runtime/doc/<doc-name>.txt
     ```

     Example for v0.11.5:
     `/opt/homebrew/Cellar/neovim/0.11.5/share/nvim/runtime/doc/api.txt`

     **Note:** Homebrew may add revision suffixes like `_1`, `_2` to the version
     directory (e.g., `0.11.5_1`) when the formula is updated without a version
     bump (dependency updates, patches, rebuilds). If the exact version path
     doesn't exist, check for version directories with suffixes.

   - **Linux (Snap assumed):** Compose path directly

     ```
     /snap/nvim/current/usr/share/nvim/runtime/doc/<doc-name>.txt
     ```

2. **If OS or version unknown:** Run discovery commands to find Neovim path

   Find Neovim installation:

   ```bash
   realpath $(which nvim)
   ```

   Then, use appropriate path pattern based on the result

3. **If local lookup fails:** Use GitHub raw URLs (least preferred)

   ```
   https://raw.githubusercontent.com/neovim/neovim/refs/tags/v<version>/runtime/doc/<doc-name>.txt
   ```

**Why:** Running `nvim` commands can hang, cause race conditions, or interfere
with development environment.

**Tip:** Use grep on doc folder when unsure which file contains needed info.

Example - search for `colors_name` in Neovim docs:
```bash
rg "colors_name" /opt/homebrew/Cellar/neovim/0.11.5*/share/nvim/runtime/doc/
```

**Note:** Use `rg` (ripgrep) if available, fallback to `grep -r` only if `rg` fails.

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

- **Agentic.nvim**
  - Configured at `neovim/nvim/lua/plugins/agentic.lua`
  - **Main chat interface** - My own plugin for interacting with AI models
    through Claude Agent Coding Protocol (ACP)
  - Provides chat interface with tool execution, file operations, and code
    generation capabilities
  - Supports multiple ACP providers: Claude, OpenCode, and others
  - Repository: https://github.com/carlos-algms/agentic.nvim
  - Local codebase: `~/projects/agentic.nvim` (development setup, when NOT on
    ssh)
  - Key bindings:
    - `<C-\>` - Toggle Agentic window
    - `<C-'>` - Add selection/file to context
    - `<C-,>` - New session
    - `<C-t>` - Stop generation

- **Avante.nvim**
  - Configured at `neovim/nvim/lua/plugins/avante.lua`
  - Alternative AI chat interface (Cursor-like UI)
  - Documentation: https://github.com/yetone/avante.nvim/blob/main/README.md

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