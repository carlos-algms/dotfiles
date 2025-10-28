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
- `aliases_git.sh` - Git shortcuts (gbdg to delete "gone" branches)
- `aliases_ls.sh` - Directory listing (uses eza when available)
- `aliases_docker.sh` - Docker shortcuts
- `aliases_grep.sh` - Search aliases

### Tool Detection Pattern

Shell scripts check for modern alternatives:

- `fd` over `find` (faster, respects .gitignore)
- `rg` over `grep` (faster, better defaults, also respects .gitignore)
- `nvim` over `vim` over `vi`

## Installation System

The installation system should not be executed or changed by you, unless I ask
you to do so.

It's only mentioned here fore reference and documentation.

### Main Bootstrap

- **Entry point**: `./bootstrap.sh` - Orchestrates all installation scripts
- **Architecture**: Iterates through subdirectories running individual
  `install.sh` scripts
- **Logging**: All scripts source `shell/common/01_logging.sh` for consistent
  output (e_header, e_success, e_error, e_arrow)
- **OS Detection**: Scripts source `shell/common/00_os.sh` which exports
  `IS_WIN`, `IS_MAC`, `IS_LINUX` environment variables

### Module Structure

Each major component has its own `install.sh`:

- `shell/install.sh` - Shell configuration (detects OS and delegates to
  platform-specific installers)
- `neovim/install.sh` - Neovim setup (installs via brew/apt, creates symlink
  from `neovim/nvim` to `~/.config/nvim`)
- `kitty/install.sh` - Kitty terminal (macOS only, symlinks config files)

### Installation Pattern

- Scripts create symlinks to this repository rather than copying files
- Existing files are backed up with timestamp suffix before linking
- Platform-specific installers in `shell/[linux|macos|windows]/install-*.sh`

## Key Commands

### Development Workflow

Also not for you to execute, just for reference.

```bash
# Install/update all configurations
./bootstrap.sh

# Install individual components
./shell/install.sh
./neovim/install.sh
./kitty/install.sh

# Sync neovim config via SSH
# Like a shared host like HostGator, GoDaddy, etc..
./neovim/sync-via-ssh.sh
```

## AI Configuration

The repository includes shared AI assistant configurations in `AI-configs/`:

- `base-ai-instructions.md` - Shared instructions for all AI agents, it's either
  referenced by dedicated AI config file, or symlinked to AGENTS.md, or
  GEMINI.md etc.
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
