---
name: orchestrate-agent-clis
description:
  Run different AI agent CLIs and orchestrate them for complex tasks or
  alternative approaches or opinions.
---

# Orchestrate Agent CLIs

For read-only tasks (questions, plans, reviews, analysis), instruct agents not
to make file changes.

## Available CLIs

| CLI          | Command                                    |
| ------------ | ------------------------------------------ |
| gemini       | `gemini -p "<prompt>"`                     |
| codex        | `codex exec "<prompt>"` (no internet)      |
| claude-code  | `claude -p "<prompt>"`                     |
| cursor-agent | `cursor-agent --model=MODEL -p "<prompt>"` |

cursor-agent models: `composer-1` (preferred), `sonnet-4.5-thinking`, `grok`,
`gpt-5-codex`

## File References

Use `@` prefix with relative path:

```bash
codex exec "Review @src/components/Button.tsx"
gemini -p "Create tests for @src/utils/helpers.ts"
```
