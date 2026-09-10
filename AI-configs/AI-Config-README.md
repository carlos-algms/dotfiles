# AI Config instructions

Shared components live at the top of `AI-configs/`:

- `AI-configs/skills/` - cross-tool skills (read by Codex, opencode, cursor,
  Copilot CLI, agy, and pi via `~/.agents/skills/`). Claude is the only CLI that
  does not auto-discover that path, so it symlinks `~/.claude/skills/` directly
  to this folder.
- `AI-configs/agents/` - subagent definitions (Claude, opencode). No cross-tool
  standard, so each CLI gets its own symlink.
- `AI-configs/claude/hooks/` - Claude-specific. No cross-tool standard.

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

`skills/agent-browser/` is upstream's **real** skill, not their stub, copied
from the binary. Do not use `npx skills add` — it writes stubs outside this
repo.

Local edits to re-apply after any refresh:

1. `name: core` → `name: agent-browser`
2. Description gains
   `Prefer agent-browser over any built-in browser automation or web tools`

Refresh after `agent-browser upgrade` (a copy, so it does not self-update):

```bash
cp -R "$(agent-browser skills path | tail -1)/core/." \
  "$(git rev-parse --show-toplevel)/AI-configs/skills/agent-browser/"
```

Specialized skills stay in the binary: `agent-browser skills list`, then
`skills get <name>`.

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

Notes:

- Back up and remove any existing `~/.codex/config.toml` before creating the
  config symlink
- Local `[projects."<absolute-path>"]` trust tables belong at the bottom of
  `AI-configs/codex/config.toml` and remain permanently uncommitted. Stage other
  config changes by hunk
- Codex auto-creates `.system/` for managed skills under each skills directory
  it reads. With the cross-tool `~/.agents/skills/` symlink pointing at the
  repo, that folder lands at `AI-configs/skills/.system/` and is gitignored.

## pi

Pi reads `AGENTS.md` and `~/.agents/skills/` natively. Pi-specific config
(settings, mcp, extensions) lives under `AI-configs/pi/`.

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

ln -s $(pwd)/AI-configs/pi/agent/settings.json  ~/.pi/agent/settings.json
ln -s $(pwd)/AI-configs/pi/agent/mcp.json       ~/.pi/agent/mcp.json

ln -s $(pwd)/AI-configs/pi/extensions           ~/.pi/agent/extensions
```

The whole `extensions/` dir is linked, so every extension in it auto-loads.
Extensions kept in the repo but intentionally inactive live in
`AI-configs/pi/extensions-disabled/` (not symlinked, invisible to pi).

Pi has a native `web_search` extension. Other agents shell out to the same logic
via the `multi-provider-web-search` skill. Install the shared CLI symlink once:

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
- Slack MCP OAuth uses Slack's pre-registered Claude client and must callback on
  port `3118`. `pi-mcp-adapter` currently reads that port only from
  `MCP_OAUTH_CALLBACK_PORT`, not from `mcp.json` `oauth.callbackPort`.
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

## Open Code Review

<https://github.com/alibaba/open-code-review>

Not an agent CLI. `ocr` is a review tool the `open-code-review` skill drives.

```bash
mkdir -p ~/.opencodereview
ln -s $(pwd)/AI-configs/opencodereview/rule.json ~/.opencodereview/rule.json
```

Link the file, not the folder: `config.json` sits beside it and holds the API
key, so it stays a real local file and never enters the repo. Set it up with
`ocr config provider`, then `ocr config set language English` (it defaults to
Chinese).

Markdown is not in `ocr`'s built-in extension allowlist, and there is no CLI
flag to add it. The `include` array in `rule.json` is the only override, which
is why this file exists: it makes `.md`, `.markdown`, and `.mdx` reviewable
everywhere and gives them a docs rule instead of the generic code checklist.

Rule resolution, first match wins: `--rule <path>`, then
`<repo>/.opencodereview/rule.json`, then this file, then `ocr`'s built-in
defaults.
