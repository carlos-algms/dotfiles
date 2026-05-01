# AI Config instructions

## Claude

```bash
mkdir -p ~/.claude
ln -s $(pwd)/AI-configs/claude/claude-settings.json ~/.claude/settings.json
ln -s $(pwd)/AI-configs/claude/{commands,agents,skills} ~/.claude/

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

## crush AI cli

https://github.com/charmbracelet/crush

```bash
mkdir -p ~/.config/crush
ln -s $(pwd)/AI-configs/crush-ai/crush.json ~/.config/crush/crush.json
```
