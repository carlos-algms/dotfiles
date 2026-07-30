---
name: orchestrate-agent-clis
description: >
  Execute and orchestrate multiple AI agent CLIs (agy, Codex, Cursor, Claude
  Code, Pi) for getting alternative opinions, comparing approaches, or
  leveraging different AI models' strengths. Use when the user explicitly
  mentions agent names like "ask agy", "ask cursor", "ask codex", "ask pi", "use
  composer", "use pi", "try grok", or when needing diverse perspectives on
  complex problems, alternative implementation approaches, or multi-agent
  collaboration.
---

# Orchestrate Agent CLIs

Execute different AI agent CLIs to get alternative perspectives, compare
approaches, or leverage specific model strengths.

## Never truncate agent output

- Run every command in this skill raw. Never pipe it through anything that drops
  lines
- Forbidden: `tail`, `head`, `sed -n`, `grep`/`rg` filters, `cut`, `wc -l`,
  `| less`, `--quiet`-style flags
- Truncated output is gone. The agent's answer is the deliverable, and the cut
  part is unrecoverable without paying for a full rerun
- Output too long for chat: redirect the FULL output to a file in the scratchpad
  dir, then read the file with the read tool
  - `codex exec --skip-git-repo-check "<prompt>" < /dev/null >/path/to/scratchpad/codex.log 2>&1`
- Same rule for model discovery (`agy models`, `cursor-agent models`,
  `pi --list-models`)

## Always redirect stdin

- Append `< /dev/null` to EVERY invocation in this skill, unless you are
  deliberately piping input
- Cause: these CLIs read the prompt from stdin when it is piped. An open pipe
  that never closes means they block waiting for EOF
- `codex exec` is the worst case: it prints
  `Reading additional input from stdin...`, never processes the argument prompt,
  and produces zero output. Signature: process alive, ~0% CPU, no output
- `agy -p`, `cursor-agent -p`, `claude -p` answer the prompt but then fail to
  exit. Work is done, process hangs
- `< /dev/null` fixes all four (verified: exit 0)

```bash
# hangs
codex exec --skip-git-repo-check "<prompt>"

# correct
codex exec --skip-git-repo-check "<prompt>" < /dev/null
```

## Defaults

- If user names an agent but not provider, model, or effort, use that CLI's
  default
- Do not ask which provider, model, or effort to use unless user explicitly asks
  to choose
- Do not pause to recommend alternatives when the requested agent can run with
  defaults
- Ask only for missing task inputs that block execution, such as absent file
  paths or destructive write intent

## Available CLIs

### agy (Antigravity CLI)

Google's Antigravity CLI, the successor to Gemini CLI.

```bash
agy -p "<prompt>" < /dev/null
```

Has internet access. Good for research and current information.

| Alias       | Model                   | Use                                           |
| ----------- | ----------------------- | --------------------------------------------- |
| `default`   | omit `--model`          | CLI default                                   |
| `flash`     | `gemini-3.6-flash-high` | default pick, beats 3.1 Pro on coding/agentic |
| `flash low` | `gemini-3.6-flash-low`  | cheapest, simple tasks                        |
| `pro`       | `gemini-3.1-pro-high`   | fallback when Flash quota drained             |
| `oss`       | `gpt-oss-120b-medium`   | open-weight alternative perspective           |

`--effort low|medium|high` controls reasoning depth.

Quota: two separate buckets. Flash refills ~every 5h; Pro and oss refill weekly.
Prefer Flash; save Pro/oss for a drained Flash bucket or a genuinely different
model.

Discover models (use when a `--model` name fails or may be stale):

```bash
agy models
```

### Codex

```bash
codex exec --skip-git-repo-check "<prompt>" < /dev/null
```

No model-list subcommand. Set with `-m <model>` (e.g. `-m gpt-5.6-sol`).
Discover current OpenAI model IDs at <https://platform.openai.com/docs/models>
or the interactive `/model` picker in `codex` (no subcommand).

### Claude Code

```bash
claude -p "<prompt>" < /dev/null
```

Full-featured Claude agent with tool access.

No model-list subcommand. `--model` takes an alias (`opus`, `sonnet`, `haiku`)
or a full ID (e.g. `claude-opus-4-8`). Discover current IDs at
<https://docs.claude.com/en/docs/about-claude/models/overview>.

### Cursor Agent

```bash
cursor-agent --model=MODEL -p "<prompt>" < /dev/null
```

Available models (not extensive, favorites):

| Alias         | Model                              | Use                                        |
| ------------- | ---------------------------------- | ------------------------------------------ |
| `composer`    | `composer-2.5-fast`                | default, fastest composer variant          |
| `codex`       | `gpt-5.3-codex-xhigh-fast`         | extra-high coding                          |
| `opus`        | `claude-opus-5-thinking-high-fast` | 1M ctx                                     |
| `opus max`    | `claude-opus-5-thinking-max`       | 1M ctx, max thinking                       |
| `sonnet`      | `claude-sonnet-5-thinking-medium`  | 1M ctx, medium thinking                    |
| `gemini`      | `gemini-3.1-pro`                   | code investigation, planning, web research |
| `gemini fast` | `gemini-3.6-flash-high`            | simple tasks                               |
| `grok`        | `cursor-grok-4.5-high`             | creative solutions, unconventional         |
| `gpt`         | `gpt-5.6-sol-xhigh`                | 1M extra-high reasoning                    |
| `fable`       | `claude-fable-5-thinking-xhigh`    | 1M ctx, extra-high thinking (NO ZDR)       |
| `kimi`        | `kimi-k3-max`                      | open-weight alternative perspective        |

Note: If these models fail, get the list of available models with this command
(no truncation, see "Never truncate agent output"):

```bash
cursor-agent models
```

### Pi

```bash
pi -p "<prompt>" < /dev/null
```

Multi-provider agent (Anthropic, OpenAI, Google, xAI, etc)

Model and thinking mode are optional for Pi. Omit `--model` and `--thinking`
unless user requested them.

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
codex exec --skip-git-repo-check "Review @src/components/Button.tsx" < /dev/null
agy -p "Create tests for @src/utils/helpers.ts" < /dev/null
cursor-agent --model=composer-2.5 -p "Refactor @src/api/client.ts" < /dev/null
pi -p "Review @src/api/client.ts" < /dev/null
```

## Task Guidelines

### Read-Only Tasks

For questions, plans, reviews, or analysis, instruct agents not to make file
changes:

```bash
cursor-agent --model=gemini-3.1-pro -p "Analyze the architecture in @src/core/ - explain only, do not modify files" < /dev/null
```

### Comparison Workflows

Get multiple perspectives on the same problem:

```bash
# Get agy's opinion first
agy -p "How would you implement feature X?" < /dev/null

# Then compare with Codex
codex exec --skip-git-repo-check "How would you implement feature X?" < /dev/null
```
