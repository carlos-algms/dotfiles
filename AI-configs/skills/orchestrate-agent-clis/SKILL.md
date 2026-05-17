---
name: orchestrate-agent-clis
description: >
  Execute and orchestrate multiple AI agent CLIs (Gemini, Codex, Cursor, Claude
  Code, Pi) for getting alternative opinions, comparing approaches, or
  leveraging different AI models' strengths. Use when the user explicitly
  mentions agent names like "ask gemini", "ask cursor", "ask codex", "ask pi",
  "use composer", "use pi", "try grok", or when needing diverse perspectives on
  complex problems, alternative implementation approaches, or multi-agent
  collaboration.
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

Available models (not extensive, favorites):

| Alias         | Model                                 | Use                                        |
| ------------- | ------------------------------------- | ------------------------------------------ |
| `composer`    | `composer-2-fast`                     | default, fastest composer variant          |
| `codex`       | `gpt-5.3-codex-xhigh-fast`            | extra-high coding                          |
| `opus`        | `claude-opus-4-7-thinking-xhigh-fast` | 1M ctx                                     |
| `opus max`    | `claude-opus-4-7-thinking-max`        | 1M ctx, max thinking                       |
| `sonnet`      | `claude-4.6-sonnet-medium-thinking`   | 1M ctx, medium thinking                    |
| `gemini`      | `gemini-3.1-pro`                      | code investigation, planning, web research |
| `gemini fast` | `gemini-3-flash`                      | simple tasks                               |
| `grok`        | `grok-4.3`                            | creative solutions, unconventional, 1M ctx |
| `gpt`         | `gpt-5.5-extra-high`                  | 1M extra-high reasoning                    |

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

Model is optional for Pi. Omit `--model` for the default.

| Alias             | Model flag                  | Use                       |
| ----------------- | --------------------------- | ------------------------- |
| `opus`, `default` | omit `--model`              | default general reasoning |
| `sonnet`          | `--model claude-sonnet-4-6` | fast 1M ctx               |
| `haiku`           | `--model claude-haiku-4-5`  | fastest simple tasks      |
| `codex`           | `--model gpt-5.3-codex`     | code-focused OpenAI       |
| `gpt`             | `--model gpt-5.5`           | latest GPT via OpenAI     |

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
