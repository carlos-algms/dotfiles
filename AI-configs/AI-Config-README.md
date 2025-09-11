# AI Config instructions

## Claude

```bash
mkdir -p ~/.claude
ln -s ~/projects/dotfiles/AI-configs/claude/claude-settings.json ~/.claude/settings.json
ln -s ~/projects/dotfiles/AI-configs/claude/base-claude-instructions.md ~/.claude/CLAUDE.md
ln -s ~/projects/dotfiles/neovim/nvim/avante_prompts/_shared.avanterules ~/.claude/shared.md
```

## Gemini

```bash
mkdir -p ~/.gemini
ln -s ~/projects/dotfiles/AI-configs/gemini/settings.json ~/.gemini/settings.json
```
