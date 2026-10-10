# AI Config instructions

Setup commands per CLI. Folder layout and rules: see `AGENTS.md`.

## Cross-tool standard path (install once)

```bash
mkdir -p ~/.agents
ln -s $(pwd)/AI-configs/skills ~/.agents/skills
```

That single symlink covers Codex, opencode, cursor, Copilot CLI, agy, and pi.
The per-CLI install steps below only set up what each CLI does **not**
auto-discover.

## Skills needing a binary on PATH

The symlink is not enough; install the tool too.

| Skill                       | Install                                                                                   |
| :-------------------------- | :---------------------------------------------------------------------------------------- |
| `agent-browser`             | `pnpm add -g agent-browser && agent-browser install`                                      |
| `multi-provider-web-search` | `web-search-ai-summary` on `PATH` (see [pi](#pi))                                         |
| `defuddle`                  | `pnpm install -g defuddle`                                                                |
| `open-code-review`          | `pnpm add -g @alibaba-group/open-code-review` (see [Open Code Review](#open-code-review)) |

### agent-browser

The skill is a vendored copy. Refresh after `agent-browser upgrade`: ask an
agent, or follow `AGENTS.md`.

## Claude

Claude does not read `~/.agents/skills/`, so skills are symlinked directly.
Agents and hooks are Claude-specific (also wired into opencode for agents).

```bash
mkdir -p ~/.claude
ln -s $(pwd)/AI-configs/claude/claude-settings.json ~/.claude/settings.json
ln -s $(pwd)/AI-configs/claude/claude-statusline.sh ~/.claude/statusline.sh
ln -s $(pwd)/AI-configs/claude/hooks                ~/.claude/hooks
ln -s $(pwd)/AI-configs/claude/output-styles        ~/.claude/output-styles

ln -s $(pwd)/AI-configs/skills    ~/.claude/skills
ln -s $(pwd)/AI-configs/agents    ~/.claude/agents

ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.claude/CLAUDE.md
```

### Claude personal account (macOS)

`~/.claude/` is the work account. `~/.claude-personal/` is the personal account.
The `claude()` function in `shell/common/aliases_ai.sh` sets
`CLAUDE_CONFIG_DIR=~/.claude-personal` outside `~/work/`. Each config dir has
its own Keychain login, plugins, MCP servers, and history.

```bash
mkdir -p ~/.claude-personal
ln -s $(pwd)/AI-configs/claude/claude-personal-settings.json ~/.claude-personal/settings.json
ln -s $(pwd)/AI-configs/claude/claude-statusline.sh          ~/.claude-personal/statusline.sh
ln -s $(pwd)/AI-configs/claude/hooks                         ~/.claude-personal/hooks
ln -s $(pwd)/AI-configs/claude/output-styles                 ~/.claude-personal/output-styles

ln -s $(pwd)/AI-configs/skills    ~/.claude-personal/skills
ln -s $(pwd)/AI-configs/agents    ~/.claude-personal/agents

ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.claude-personal/CLAUDE.md
```

Then run `claude` outside `~/work/`, `/login` with the personal account, and
install the plugins again.

## agy (Antigravity CLI)

Google's Antigravity CLI (`agy`) replaced Gemini CLI. It keeps `~/.gemini/` as
its config home and reads the same global context file, `~/.gemini/GEMINI.md`.
Skills come from `~/.agents/skills/` (cross-tool symlink above), no per-CLI link
needed.

```bash
mkdir -p ~/.gemini
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.gemini/GEMINI.md
```

`agy` writes its own settings under `~/.gemini/antigravity-cli/`; not tracked
here.

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

Skills come from `~/.agents/skills/`. Agents need explicit links.

```bash
mkdir -p ~/.config/opencode
ln -s $(pwd)/AI-configs/opencode ~/.config/opencode
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.config/opencode/AGENTS.md
ln -s $(pwd)/AI-configs/agents   ~/.config/opencode/agents
```

## Codex CLI

Codex reads `AGENTS.md` and `~/.agents/skills/` natively. Custom prompts were
removed; reusable workflows belong in skills.

```bash
mkdir -p ~/.codex
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.codex/AGENTS.md
ln -s $(pwd)/AI-configs/codex/config.toml ~/.codex/config.toml
```

Back up and remove any existing `~/.codex/config.toml` before creating the
config symlink.

## pi

Pi reads `AGENTS.md` and `~/.agents/skills/` natively. `APPEND_SYSTEM.md` links
to Claude's terse output style to share the output rules.

Install with the managed script. This is the recommended method. A global
pnpm/npm install conflicts with the `@agentclientprotocol/*-acp` packages.

```bash
curl -fsSL https://pi.dev/install.sh | sh
pi install npm:@gotgenes/pi-anthropic-auth
pnpm add -g pi-acp
```

Symlink:

```bash
mkdir -p ~/.pi/agent

ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.pi/agent/AGENTS.md
ln -s ~/.claude/output-styles/terse.md ~/.pi/agent/APPEND_SYSTEM.md

ln -s $(pwd)/AI-configs/pi/agent/settings.json  ~/.pi/agent/settings.json
ln -s $(pwd)/AI-configs/pi/agent/mcp.json       ~/.pi/agent/mcp.json
ln -s $(pwd)/AI-configs/pi/agent/models.json    ~/.pi/agent/models.json

ln -s $(pwd)/AI-configs/pi/extensions           ~/.pi/agent/extensions
```

MCP is native. Add servers to `mcp.json` with `pi mcp add`, sign in with `/mcp`.
Tokens go to `~/.pi/agent/mcp-auth.json` (untracked, re-auth per machine).

Shared `web_search` CLI for other agents (`multi-provider-web-search` skill):

```bash
chmod +x $(pwd)/AI-configs/pi/extensions/web_search/run.ts
ln -s $(pwd)/AI-configs/pi/extensions/web_search/run.ts \
  ~/.local/bin/web-search-ai-summary
```

`web_fetch` needs `defuddle` on `PATH`:

```bash
pnpm install -g defuddle
```

Auth lives outside dotfiles (OAuth tokens written by `/login`, not git-safe).
The real file is usually kept in private cloud storage. Link it, or skip the
link on a machine without access and run `/login` in Pi to create it:

```bash
ln -s <path-to-stored-auth.json> ~/.pi/agent/auth.json
```

`web_search` API keys also live outside dotfiles, at
`${XDG_CONFIG_HOME:-~/.config}/pi-web-search-extension/auth.json`. The real file
is usually kept in private cloud storage. Link it:

```bash
mkdir -p ~/.config/pi-web-search-extension
ln -s <path-to-stored-web-search-auth.json> \
  ~/.config/pi-web-search-extension/auth.json
```

On a machine without access to that storage, create the file with your own keys.
Use an empty `apiKey` for backends you do not use; `marginalia` accepts
`public`:

```bash
mkdir -p ~/.config/pi-web-search-extension
cat > ~/.config/pi-web-search-extension/auth.json <<'EOF'
{
  "langsearch": { "apiKey": "" },
  "tavily": { "apiKey": "" },
  "exa": { "apiKey": "" },
  "brave": { "apiKey": "" },
  "marginalia": { "apiKey": "public" }
}
EOF
chmod 600 ~/.config/pi-web-search-extension/auth.json
```

Set `WEB_SEARCH_AUTH_PATH` to use another location.

Claude Pro/Max OAuth needs `@gotgenes/pi-anthropic-auth`. Log in with
`/login anthropic`. API-key requests pass through unchanged.

## Cursor Agent CLI

Cursor Agent reads `~/.agents/skills/` natively. It does not read a global
`AGENTS.md`; global file-based instructions use `~/.cursor/rules/*.mdc` instead.
`base-ai-instructions.md` includes the required `alwaysApply` frontmatter.

```bash
mkdir -p ~/.cursor/rules
ln -s $(pwd)/AI-configs/base-ai-instructions.md \
  ~/.cursor/rules/agents-md.mdc
```

Repo-level rules still use `AGENTS.md`, `CLAUDE.md`, or `.cursor/rules/`.

## crush AI cli

<https://github.com/charmbracelet/crush>

```bash
mkdir -p ~/.config/crush
ln -s $(pwd)/AI-configs/crush-ai/crush.json ~/.config/crush/crush.json
```

## Open Code Review

<https://github.com/alibaba/open-code-review>

Not an agent CLI. `ocr` is a review tool the `open-code-review` skill drives.

```bash
mkdir -p ~/.opencodereview
ln -s $(pwd)/AI-configs/opencodereview/rule.json ~/.opencodereview/rule.json
```

Link the file, not the folder: `config.json` sits beside it and holds the API
key. Set it up with `ocr config provider`, then
`ocr config set language English` (it defaults to Chinese).
