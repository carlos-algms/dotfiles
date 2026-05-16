---
name: orchestrate-agent-clis
description: >
  Execute and orchestrate multiple AI agent CLIs (Gemini, Codex, Cursor, Claude
  Code) for getting alternative opinions, comparing approaches, or leveraging
  different AI models' strengths. Use when the user explicitly mentions agent
  names like "ask gemini", "ask cursor", "ask codex", "ask pi", "use composer",
  "use pi", "try grok", or when needing diverse perspectives on complex
  problems, alternative implementation approaches, or multi-agent collaboration.
---

# Orchestrate Agent CLIs

Execute different AI agent CLIs to get alternative perspectives, compare
approaches, or leverage specific model strengths.

## Available CLIs

### Gemini

```bash
gemini -p "<prompt>"
```

Has internet access. Good for research and current information.

### Codex

```bash
codex exec "<prompt>"
```

No internet access. Fast, focused on code generation.

### Claude Code

```bash
claude -p "<prompt>"
```

Full-featured Claude agent with tool access.

### Cursor Agent

```bash
cursor-agent --model=MODEL -p "<prompt>"
```

Available models:

- `composer-2` preferred for multi-file edits, also fast
- `composer-2-fast` default, fastest composer variant
- `claude-opus-4-7-thinking-high` Opus 4.7 1M ctx, strongest reasoning
- `claude-4.6-sonnet-medium-thinking` Sonnet 4.6 1M ctx with thinking
- `gemini-3.1-pro` better for code investigation, planning and web research
- `gemini-3-flash` faster, good for simple tasks
- `grok-4.3` creative solutions, unconventional approaches (1M ctx)
- `gpt-5.4-xhigh` High reasoning
- `gpt-5.5-high` GPT-5.5 1M high reasoning

Note: If these models fail, you can get the list of available models by running
this command, but don't use head or tail, otherwise you'll cut out important
models out:

```bash
cursor-agent models
```

### Pi

```bash
pi -p "<prompt>"
```

Multi-provider agent (Anthropic, OpenAI, Google, xAI, etc)

- `--model claude-opus-4-7` strongest reasoning (1M ctx).
- `--model claude-sonnet-4-6` fast, 1M ctx.
- `--model gpt-5.4-xhigh` high reasoning via OpenAI.
- `--thinking <off|minimal|low|medium|high|xhigh>` controls reasoning depth.
- `--tools read,grep,find,ls` for read-only runs.
- `--continue` / `--resume` to reuse sessions.
- `--list-models [search]` to discover models.

## File References

Reference files using `@` prefix with relative paths:

```bash
codex exec "Review @src/components/Button.tsx"
gemini -p "Create tests for @src/utils/helpers.ts"
cursor-agent --model=composer-2 -p "Refactor @src/api/client.ts"
pi -p "Review @src/api/client.ts"
```

## Task Guidelines

### Read-Only Tasks

For questions, plans, reviews, or analysis, instruct agents not to make file
changes:

```bash
cursor-agent --model=gemini-3.1-pro -p "Analyze the architecture in @src/core/ - explain only, do not modify files"
```

### Comparison Workflows

Get multiple perspectives on the same problem:

```bash
# Get Gemini's opinion first
gemini -p "How would you implement feature X?"

# Then compare with Codex
codex exec "How would you implement feature X?"
```
