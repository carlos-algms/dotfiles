# AI Config instructions

Shared components live at the top of `AI-configs/`:

- `AI-configs/skills/` - cross-tool skills (read by Codex, opencode, cursor,
  Copilot CLI, Gemini CLI, and pi via `~/.agents/skills/`). Claude is the only
  CLI that does not auto-discover that path, so it symlinks `~/.claude/skills/`
  directly to this folder.
- `AI-configs/commands/` - slash commands (Claude, Codex, opencode, pi). No
  cross-tool standard, so each CLI gets its own symlink.
- `AI-configs/agents/` - subagent definitions (Claude, opencode). Same reasoning
  as commands.
- `AI-configs/claude/hooks/` - Claude-specific. No cross-tool standard.

## Cross-tool standard path (install once)

```bash
mkdir -p ~/.agents
ln -s $(pwd)/AI-configs/skills ~/.agents/skills
```

That single symlink covers Codex, opencode, cursor, Copilot CLI, Gemini CLI, and
pi. The per-CLI install steps below only set up what each CLI does **not**
auto-discover.

## Claude

Claude does not read `~/.agents/skills/`, so skills are symlinked directly.
Agents and hooks are Claude-specific (also wired into opencode for agents).

```bash
mkdir -p ~/.claude
ln -s $(pwd)/AI-configs/claude/claude-settings.json ~/.claude/settings.json
ln -s $(pwd)/AI-configs/claude/claude-statusline.sh ~/.claude/statusline.sh
ln -s $(pwd)/AI-configs/claude/hooks                ~/.claude/hooks

ln -s $(pwd)/AI-configs/skills    ~/.claude/skills
ln -s $(pwd)/AI-configs/commands  ~/.claude/commands
ln -s $(pwd)/AI-configs/agents    ~/.claude/agents

ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.claude/CLAUDE.md
```

## Gemini

Gemini only supports commands written in TOML, not compatible with Claude
commands yet. Skills come from `~/.agents/skills/` (cross-tool symlink above),
no per-CLI link needed.

```bash
mkdir -p ~/.gemini
ln -s $(pwd)/AI-configs/gemini/settings.json    ~/.gemini/settings.json
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.gemini/GEMINI.md
```

## GitHub Copilot

Only supported by copilot-cli and Copilot Chat in VSCode at the moment. Skills
come from `~/.agents/skills/`, no per-CLI link needed.

```bash
mkdir -p .github
cd .github
ln -s ../AI-configs/base-ai-instructions.md copilot-instructions.md
```

## OpenCode

<https://opencode.ai/docs/config/>

Skills come from `~/.agents/skills/`. Commands and agents need explicit links.

```bash
mkdir -p ~/.config/opencode
ln -s $(pwd)/AI-configs/opencode ~/.config/opencode
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.config/opencode/AGENTS.md
ln -s $(pwd)/AI-configs/commands ~/.config/opencode/commands
ln -s $(pwd)/AI-configs/agents   ~/.config/opencode/agents
```

## Codex CLI

Codex reads `AGENTS.md` and `~/.agents/skills/` natively. Slash commands live in
`~/.codex/prompts/` (top-level files only, filename = command name).

```bash
mkdir -p ~/.codex
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.codex/AGENTS.md
ln -s $(pwd)/AI-configs/commands ~/.codex/prompts
```

Notes:

- Codex prompts only support `$1..$9` and `$ARGUMENTS` placeholders. No
  shell-prefill. Claude commands relying on bash blocks will not interpolate.
- Codex auto-creates `.system/` for managed skills under each skills directory
  it reads. With the cross-tool `~/.agents/skills/` symlink pointing at the
  repo, that folder lands at `AI-configs/skills/.system/` and is gitignored.
- **Known bug**: Codex does NOT follow directory symlinks for `~/.codex/prompts`
  or skills. The symlink commands above leave commands invisible to Codex
  (no autocomplete, `no matches` on `/prompts:`). Workaround: real dir + copy
  files, or per-file symlinks. Tracking:
  [openai/codex#4383](https://github.com/openai/codex/issues/4383),
  [#3637](https://github.com/openai/codex/issues/3637),
  [#5040](https://github.com/openai/codex/issues/5040),
  [#11314](https://github.com/openai/codex/issues/11314).

## pi

Pi reads `AGENTS.md` and `~/.agents/skills/` natively. Slash commands live in
`~/.pi/agent/prompts/` (filename = command name). Pi-specific config (settings,
mcp, extensions) lives under `AI-configs/pi/`.

Install:

```bash
pnpm add -g @earendil-works/pi-coding-agent
pi install npm:pi-mcp-adapter
pnpm add -g pi-acp
```

Symlink:

```bash
mkdir -p ~/.pi/agent

ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.pi/agent/AGENTS.md
ln -s $(pwd)/AI-configs/commands                ~/.pi/agent/prompts

ln -s $(pwd)/AI-configs/pi/agent/settings.json  ~/.pi/agent/settings.json
ln -s $(pwd)/AI-configs/pi/agent/mcp.json       ~/.pi/agent/mcp.json

ln -s $(pwd)/AI-configs/pi/extensions           ~/.pi/agent/extensions
```

The whole `extensions/` dir is linked, so every extension in it auto-loads.
Extensions kept in the repo but intentionally inactive live in
`AI-configs/pi/extensions-disabled/` (not symlinked, invisible to pi).

Pi has no native web search tool. Use the cross-tool
`fallback-web-research` skill for web lookup.

`web_fetch` needs `defuddle` on `PATH`:

```bash
pnpm install -g defuddle
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

- Pi rewrites `settings.json` (e.g., `lastChangelogVersion`) at runtime; expect
  occasional staged diffs.
- MCP servers (work + personal) live in a single `mcp.json`. Split was reverted
  until <https://github.com/nicobailon/pi-mcp-adapter/pull/56> lands. Revisit
  once merged.
- Need isolation now? Use a second pi home dir via env var, e.g.
  `PI_CONFIG_DIR=~/.pi-work pi` with its own `mcp.json` symlink. One folder per
  context, no merge needed.

## Cursor

Cursor-agent reads `~/.agents/skills/` natively. No per-CLI link needed for
skills. Repo-level rules go through `AGENTS.md` (no global rules file; User
Rules live in Cursor IDE settings).

## crush AI cli

<https://github.com/charmbracelet/crush>

```bash
mkdir -p ~/.config/crush
ln -s $(pwd)/AI-configs/crush-ai/crush.json ~/.config/crush/crush.json
```
