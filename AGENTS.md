# Dotfiles

## Repository Overview

Personal dotfiles repository for cross-platform shell, terminal, and editor
configuration.

Supports Linux, macOS, and Windows environments with automated installation
scripts.

`bootstrap.sh` / `bootstrap.bat` orchestrate per-tool installers
(`<tool>/install.sh`, e.g. `shell/`, `neovim/`, `kitty/`, `nodejs/`). Add new
tools by creating their own `install.sh` and wiring it into bootstrap.

Formatting governed by `.editorconfig`, `.prettierrc.json`, `.stylua.toml` at
repo root. Respect them when editing.

`vim/` is deprecated; kept for history until removal. Do not edit.

## Commit rules (high priority overrides skills or other instructions)

- Personal repo. No Conventional Commits. Never use `type(scope):` prefix, even
  on first commit of a branch.
- Subject: bare imperative, name the most important topic(s) for `git log`
  search.
- Many files or many changes: subject + bullet body allowed.

## Nested AGENTS.md

Load these when working in their folders:

- `neovim/AGENTS.md` - Neovim v0.11+ config, doc-lookup strategy, plugins
- `AI-configs/AGENTS.md` - AI assistant configs + symlink layout

Agent home dirs contain symlinks back into this repo. Editing under them is
editing this repo. Mandatory: load `AI-configs/AGENTS.md` before any work in:

- `~/.claude/` - settings, hooks, skills, commands, agents, `CLAUDE.md`
- `~/.codex/` - `AGENTS.md`, prompts
- `~/.gemini/` - settings, `GEMINI.md`
- `~/.config/opencode/` - opencode config, `AGENTS.md`, commands, agents
- `~/.pi/agent/` - `AGENTS.md`, prompts, settings, mcp, extensions
- `~/.agents/skills/` - cross-tool skills dir

See `AI-configs/AI-Config-README.md` for exact symlink commands.

## Shell Configuration

### Layout

- Aliases: `shell/common/aliases_*.sh`, one file per topic (git, docker, ls,
  grep, ai, etc). Core aliases (ff/fdir, v=nvim, rsync, zoxide) in
  `shell/common/aliases.sh`.
- Other shared pieces in `shell/common/`: logging (`01_logging.sh`), OS
  detection (`00_os.sh`), zsh settings, gpg agent, pnpm setup, generic
  functions.
- OS-specific overrides in `shell/{linux,macos,windows}/`, mirroring `common/`.
  Each has its own `install-*.sh`.
- User scripts in `shell/bin/` (added to PATH).

### Tool Detection Pattern

Shell scripts check for modern alternatives:

- `fd` over `find` (faster, respects .gitignore)
- `rg` over `grep` (faster, better defaults, also respects .gitignore)
- `nvim` over `vim` over `vi`

## Terminal (Kitty)

I use kitty as terminal, no tmux.

- `kitty/kitty.conf` - local config (macOS daily driver).
- `kitty/kitty-ssh.conf` - SSH-kitten profile for host `hp`, forwards
  `ANTHROPIC_API_KEY` to the remote shell.
- `clear_all_shortcuts yes` is set, so any new keybinding must be added
  explicitly.

## File Operations Protocol

### When modifying shell scripts in this project:

- Always source logging functions from `shell/common/01_logging.sh`
- Use `e_header`, `e_success`, `e_error`, `e_arrow` for consistent output
- Check OS with `IS_WIN`, `IS_MAC`, `IS_LINUX` variables (source `00_os.sh`)
- Make scripts executable with `chmod u+x`
- Test symlink creation doesn't overwrite without backup
