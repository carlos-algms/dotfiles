# AI Config instructions

## Claude

```bash
mkdir -p ~/.claude
ln -s $(pwd)/AI-configs/claude/claude-settings.json ~/.claude/settings.json
ln -s $(pwd)/AI-configs/claude/{commands,agents,skills,hooks} ~/.claude/

ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.claude/CLAUDE.md
ln -s $(pwd)/AI-configs/claude/claude-statusline.sh ~/.claude/statusline.sh
```

## Gemini

Gemini, only supports commands written in toml, not compatible with claude
skills yet.

For skills to work, it must be enabled after enabling preview mode

```bash
mkdir -p ~/.gemini
ln -s $(pwd)/AI-configs/gemini/settings.json ~/.gemini/settings.json
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.gemini/GEMINI.md
ln -s $(pwd)/AI-configs/claude/skills ~/.gemini/skills
```

## Github Copilot

Only supported by copilot-cli and Copilot Chat in VSCode at the moment.

```bash
mkdir -p .github
cd .github
ln -s ../AI-configs/base-ai-instructions.md copilot-instructions.md
```

## OpenCode

https://opencode.ai/docs/config/

```bash
mkdir -p ~/.config/opencode
ln -s $(pwd)/AI-configs/opencode ~/.config/opencode
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.config/opencode/AGENTS.md
ln -s $(pwd)/AI-configs/claude/{commands,agents,skills} ~/.config/opencode/
```

## Codex CLI

Codex reads `AGENTS.md` natively. Slash commands live in `~/.codex/prompts/`
(top-level files only, filename = command name). Skills are reused from the
Claude folder. `config.toml` is left alone (live state).

```bash
mkdir -p ~/.codex
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.codex/AGENTS.md
ln -s $(pwd)/AI-configs/claude/commands ~/.codex/prompts
ln -s $(pwd)/AI-configs/claude/skills ~/.codex/skills
```

Notes:

- Codex prompts only support `$1..$9` and `$ARGUMENTS` placeholders. No
  shell-prefill. Claude commands relying on bash blocks will not interpolate.
- Codex auto-creates `~/.codex/skills/.system/` with managed skills. Since
  `~/.codex/skills` is a symlink into the repo, that folder lands inside
  `AI-configs/claude/skills/.system/` and is gitignored.

## pi

Pi reads `AGENTS.md` natively. Slash commands live in `~/.pi/agent/prompts/`
(filename = command name). Skills reused from the Claude tree. Pi-specific
config (settings, mcp, extensions) lives under `AI-configs/pi/`.

Install:

```bash
pnpm add -g @earendil-works/pi-coding-agent
pi install npm:pi-mcp-adapter
pnpm add -g pi-acp
```

Symlink:

```bash
mkdir -p ~/.pi/agent/extensions

ln -s $(pwd)/AI-configs/base-ai-instructions.md     ~/.pi/agent/AGENTS.md
ln -s $(pwd)/AI-configs/claude/skills               ~/.pi/agent/skills
ln -s $(pwd)/AI-configs/claude/commands             ~/.pi/agent/prompts

ln -s $(pwd)/AI-configs/pi/agent/settings.json      ~/.pi/agent/settings.json
ln -s $(pwd)/AI-configs/pi/agent/mcp.json           ~/.pi/agent/mcp.json
ln -s $(pwd)/AI-configs/pi/agent/mcp-work.json      ~/.pi/agent/mcp-work.json
ln -s $(pwd)/AI-configs/pi/agent/mcp-personal.json  ~/.pi/agent/mcp-personal.json
```

Auth lives outside dotfiles (OAuth tokens written by `/login`, not git-safe).
Symlink from the private OneDrive vault:

```bash
ln -s ~/OneDrive/work/employers/parloa/dotfiles/parloa-pi-auth.json \
  ~/.pi/agent/auth.json
ln -s ~/OneDrive/work/employers/parloa/dotfiles/parloa-pi-mcp-oauth \
  ~/.pi/agent/mcp-oauth
```

Notes:

- `scoped-mcp.ts` exists in the repo but is left unlinked. Picks `mcp-work.json`
  under `~/work/*` and `mcp-personal.json` under `~/projects/*`, writes a
  `.pi/mcp.json` symlink in the project. Enable only when per-folder MCP scoping
  is needed; add `.pi/` to global gitignore first.
- `terse-nudge.ts` exists in the repo but is left unlinked. Enable only if drift
  appears in long sessions.
- Pi rewrites `settings.json` (e.g., `lastChangelogVersion`) at runtime; expect
  occasional staged diffs.

## crush AI cli

https://github.com/charmbracelet/crush

```bash
mkdir -p ~/.config/crush
ln -s $(pwd)/AI-configs/crush-ai/crush.json ~/.config/crush/crush.json
```
