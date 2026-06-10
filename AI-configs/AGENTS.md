# AI Configuration

Shared AI assistant configurations in `AI-configs/`. Cross-tool components live
at the top, CLI-specific overrides in per-tool subdirs.

- `base-ai-instructions.md` - shared instructions, symlinked globally as the
  main instructions file for each agent:
  - `~/.claude/CLAUDE.md`
  - `~/.gemini/GEMINI.md` (read by agy, Google's Antigravity CLI)
  - `~/.config/opencode/AGENTS.md`
  - `~/.codex/AGENTS.md`
  - `~/.pi/agent/AGENTS.md`
  - `.github/copilot-instructions.md` (per-repo, for Copilot)
- `skills/` are cross-tool. `~/.agents/skills/` is symlinked once to `skills/`;
  Codex, opencode, cursor, Copilot CLI, agy, and pi auto-discover it. Claude
  does not, so it gets a direct symlink. `agents/` has no cross-tool standard,
  so each CLI symlinks it directly.
- `claude/` holds Claude-specific bits (`claude-settings.json`,
  `claude-statusline.sh`, `hooks/`).
- Third-party components (skills, agents, hooks) are vendored into these
  top-level directories via a single sync script. See ./COMPONENTS-sync.md for
  the manifest format, run instructions, and how to add a new source.
- See ./AI-Config-README.md for the exact symlink commands per agent.

## Pi (`pi/`)

Pi (`@earendil-works/pi-coding-agent`) is configured here. Layout:

- `pi/agent/settings.json` - pi user settings (provider defaults, theme, etc).
- `pi/agent/mcp.json` - MCP servers wired into pi.
- `pi/extensions/<name>/` - custom tool extensions. Each is a TypeScript module
  that registers tools via `pi.registerTool(...)`. Pi loads `.ts` directly (no
  build step). Current extensions: `web_fetch`, `web_search`, `vim-mode`.
- `pi/extensions-disabled/` - extensions kept around but not loaded.
- `pi/tsconfig.json` - shared tsconfig for all extensions. Maps
  `@earendil-works/pi-coding-agent`, `@earendil-works/pi-tui`, and `typebox` to
  the pnpm global install. Run `tsc --noEmit -p AI-configs/pi/tsconfig.json`
  from any directory to type-check all extensions.

Per-extension docs (read on demand, don't pre-emptively load):

- `pi/extensions/<name>/README.md` - what the extension does, parameters, flow,
  short-form ADRs, limitations. Load when editing that extension or debugging
  its behaviour.
- `pi/decisions/<extension-name>/<date>-<slug>.md` - deep-dive ADRs: what was
  tried, what failed, why, what NOT to retry. Load ONLY when the README ADR
  references it or you are about to redo something it covers.
- Other extension-local files (`*-prompt.md`, etc) - referenced from the
  extension's source. Load when editing the source that consumes them.

Auth and runtime config live OUTSIDE the repo:

- `~/.pi/agent/auth.json` - provider API keys (Anthropic etc). Resolved by env
  var name; pi inherits env from the parent shell.
- `~/OneDrive/work/mac-pro/dotfiles/web-search-auth.json` - per-backend API keys
  for `web_search` extension (override path via `WEB_SEARCH_AUTH_PATH`).
- `~/.pi/web-search-usage.json` - per-backend daily/monthly counters managed by
  the `web_search` extension.
- `~/.local/bin/web-search-ai-summary` ->
  `AI-configs/pi/extensions/web_search/run.ts`
  - user-installed symlink so other agents (via `multi-provider-web-search`
    skill) can shell out to the same logic pi uses in-process.

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
