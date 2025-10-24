# AI Config instructions

## Claude

```bash
mkdir -p ~/.claude
ln -s $(pwd)/AI-configs/claude/claude-settings.json ~/.claude/settings.json
ln -s $(pwd)/AI-configs/claude/commands ~/.claude/commands
ln -s $(pwd)/AI-configs/claude/agents ~/.claude/agents

ln -s $(pwd)/AI-configs/claude/base-claude-instructions.md ~/.claude/CLAUDE.md
ln -s $(pwd)/AI-configs/claude/claude-statusline.sh ~/.claude/statusline.sh

ln -s $(pwd)/neovim/nvim/avante_prompts/_shared.avanterules ~/.claude/shared.md
```

## Gemini

```bash
mkdir -p ~/.gemini
ln -s $(pwd)/AI-configs/gemini/settings.json ~/.gemini/settings.json
```

## OpenCode

https://opencode.ai/docs/config/

```bash
mkdir -p ~/.config
ln -s $(pwd)/AI-configs/opencode ~/.config/opencode
ln -s $(pwd)/neovim/nvim/avante_prompts/_shared.avanterules ~/.config/opencode/AGENTS.md
```

## crush AI cli

https://github.com/charmbracelet/crush

```bash
mkdir -p ~/.config/crush
ln -s $(pwd)/AI-configs/crush-ai/crush.json ~/.config/crush/crush.json
```
