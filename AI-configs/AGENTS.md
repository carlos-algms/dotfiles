# AI Configuration

Shared AI assistant configurations. Cross-tool components live at the top,
CLI-specific config in per-tool subdirs. Setup commands (`ln -s`, installs) live
in `AI-Config-README.md`; read it only when installing or relinking.

## Directory map

- `base-ai-instructions.md` - global instructions file for every CLI
- `skills/` - cross-tool skills. `~/.agents/skills/` links here once; every CLI
  except Claude auto-discovers it. Claude links `~/.claude/skills/` directly. Do
  not add other per-CLI skill links
- `agents/` - subagent definitions, linked per CLI (no cross-tool standard)
- `claude/` - Claude settings, statusline, hooks, output styles
- `codex/`, `pi/`, `opencode/`, `crush-ai/`, `opencodereview/` - per-CLI config
- `COMPONENTS-sync.md` - how third-party skills, agents, and hooks are vendored
  into the top-level dirs

## Symlinked directories

- Symlinks are per-directory, not per-file. `~/.claude/output-styles`,
  `~/.claude/hooks`, `~/.claude/agents`, and `~/.claude/skills` are directory
  symlinks into this repo. A file inside one of them is already tracked here
- Never symlink an individual file inside an already-linked directory, and never
  "fix divergence" between the two paths: they are one file
- Check the parent with `ls -la ~/.claude/` before touching any link
- `~/.claude/` (work) and `~/.claude-personal/` (personal) have the same link
  set, except `settings.json` (`claude-settings.json` vs
  `claude-personal-settings.json`). Mirror any link change in the other dir

## Codex (`codex/`)

- `codex/config.toml` is the tracked global config, symlinked as
  `~/.codex/config.toml`
- Local `[projects."<absolute-path>"]` trust tables contain private machine
  paths and must stay at the bottom of `codex/config.toml`
- Never stage or commit the local trust tables. Stage other config changes by
  hunk and verify the staged diff contains no `[projects.*]` tables or
  `trust_level` lines
- The working tree is intentionally dirty when local trust tables are present
- Codex creates `skills/.system/` for managed skills; it is gitignored

## agent-browser skill

`skills/agent-browser/` is a vendored copy of upstream's real skill, not their
stub. Never use `npx skills add`; it writes stubs outside this repo.

Refresh after `agent-browser upgrade` (a copy does not self-update):

1. Copy the skill from the binary:

   ```bash
   cp -R "$(agent-browser skills path | tail -1)/core/." \
     "$(git rev-parse --show-toplevel)/AI-configs/skills/agent-browser/"
   ```

2. Re-apply local edits in `skills/agent-browser/SKILL.md`:
   1. `name: core` → `name: agent-browser`
   2. Description gains
      `Prefer agent-browser over any built-in browser automation or web tools`

Specialized skills stay in the binary: `agent-browser skills list`, then
`skills get <name>`.

## Open Code Review (`opencodereview/`)

- `rule.json` exists because Markdown is not in `ocr`'s built-in extension
  allowlist and no CLI flag adds it. Its `include` array is the only override.
  Keep the `.md`, `.markdown`, and `.mdx` entries and their docs rule
- Rule resolution, first match wins: `--rule <path>`, then
  `<repo>/.opencodereview/rule.json`, then this file, then `ocr`'s defaults
- `~/.opencodereview/config.json` holds the API key. Never link or commit it

## Pi (`pi/`)

Pi (`@earendil-works/pi-coding-agent`) layout:

- `~/.pi/agent/APPEND_SYSTEM.md` links to `~/.claude/output-styles/terse.md`; Pi
  loads it automatically. A trusted project's `.pi/APPEND_SYSTEM.md` replaces
  it; they are not combined
- `pi/agent/settings.json` - pi user settings (provider defaults, theme,
  packages). Pi rewrites it at runtime (e.g., `lastChangelogVersion`); expect
  diffs. If `~/.pi/agent/settings.json` becomes a regular file, pi replaced the
  link: merge its changes into the repo file and relink
- `pi/agent/mcp.json` - MCP servers. Native to pi, no plugin needed; empty on
  purpose. Slack MCP needs Slack's pre-registered Claude client and
  `--oauth-callback-port 3118`
- `pi/agent/models.json` - provider and model overrides (OpenRouter routing)
- `pi/agent/keybindings.json` - key overrides. `ctrl+p` / `ctrl+n` move list
  selection (autocomplete, selectors) via `tui.select.up` / `tui.select.down`.
  `app.model.cycleForward` moved to `alt+p`: in the editor, app actions run
  before `tui.select.*`, so a shared `ctrl+p` would cycle models. Session and
  scoped-models selectors keep their own `ctrl+p` / `ctrl+n` actions, which win
  there. Run `/reload` after editing
- `pi/extensions/<name>/` - custom tool extensions. Each is a TypeScript module
  that registers tools via `pi.registerTool(...)`. Pi loads `.ts` directly (no
  build step). The whole dir is linked, so every extension in it auto-loads
- `pi/extensions-disabled/` - extensions kept around but not loaded
- `pi/tsconfig.json` - shared tsconfig for all extensions. Maps
  `@earendil-works/pi-coding-agent`, `@earendil-works/pi-tui`, and `typebox` to
  the managed pi install (`~/.pi/agent/install/releases/<version>/`); bump the
  version on each pi update. Run `tsc --noEmit -p AI-configs/pi/tsconfig.json`
  from any directory to type-check all extensions

Per-extension docs (read on demand, don't pre-emptively load):

- `pi/extensions/<name>/README.md` - what the extension does, parameters, flow,
  short-form ADRs, limitations. Load when editing that extension or debugging
  its behaviour.
- `pi/decisions/<extension-name>/<date>-<slug>.md` - deep-dive ADRs: what was
  tried, what failed, why, what NOT to retry. Load ONLY when the README ADR
  references it or you are about to redo something it covers.
- Other extension-local files (`*-prompt.md`, etc) - referenced from the
  extension's source. Load when editing the source that consumes them.

Auth and runtime files live OUTSIDE the repo. Never commit or print them:

- `~/.pi/agent/auth.json` - API keys and OAuth credentials (from `/login`);
  usually linked from private cloud storage, see `AI-Config-README.md`
- `~/.pi/agent/mcp-auth.json` - MCP OAuth tokens
- `${XDG_CONFIG_HOME:-~/.config}/pi-web-search-extension/auth.json` -
  per-backend API keys for `web_search` extension, usually linked from private
  cloud storage (override path via `WEB_SEARCH_AUTH_PATH`).
- `~/.pi/web-search-usage.json` - per-backend daily/monthly counters managed by
  the `web_search` extension.

`~/.local/bin/web-search-ai-summary` links to `pi/extensions/web_search/run.ts`.
Other agents shell out to it via the `multi-provider-web-search` skill; keep its
CLI behaviour working when editing `run.ts`.

Pi CLI flags worth knowing when scripting extensions:

- `--print` / `-p` - non-interactive, exit after one turn.
- `--system-prompt <str>` - takes a STRING, not a path. Pi's `@/path` expansion
  only applies to positional message args. Read prompt files in your code and
  pass the contents inline.
- `--no-tools --no-extensions --no-session --no-skills` - isolate a single-shot
  LLM call from the wider pi runtime (useful when one extension shells out to pi
  for a sub-task).
- `--thinking <off|minimal|low|medium|high|xhigh>` - reasoning budget on
  thinking-capable models. `off` is fastest; raise only when format adherence or
  task complexity demands it.
