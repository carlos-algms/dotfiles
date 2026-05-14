# AI Configuration

Shared AI assistant configurations in `AI-configs/`. Each agent (claude, gemini,
opencode, crush) has its own subdir following that platform's layout.

- `base-ai-instructions.md` - shared instructions, symlinked globally as the
  main instructions file for each agent:
  - `~/.claude/CLAUDE.md`
  - `~/.gemini/GEMINI.md`
  - `~/.config/opencode/AGENTS.md`
  - `.github/copilot-instructions.md` (per-repo, for Copilot)
- Skills, commands, and agents live under `AI-configs/claude/` and are symlinked
  into other agents (gemini, opencode) per @AI-Config-README.md.
- See @AI-Config-README.md for the exact symlink commands per agent.
