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

```bash
mkdir -p ~/.gemini
ln -s $(pwd)/AI-configs/gemini/settings.json ~/.gemini/settings.json
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.gemini/GEMINI.md
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
mkdir -p ~/.config
ln -s $(pwd)/AI-configs/opencode ~/.config/opencode
ln -s $(pwd)/AI-configs/base-ai-instructions.md ~/.config/opencode/AGENTS.md
```

## crush AI cli

https://github.com/charmbracelet/crush

```bash
mkdir -p ~/.config/crush
ln -s $(pwd)/AI-configs/crush-ai/crush.json ~/.config/crush/crush.json
```
