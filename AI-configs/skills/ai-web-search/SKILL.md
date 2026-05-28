---
name: ai-web-search
description: >
  Search the internet by delegating to another AI CLI when local web tools are
  unavailable or when a second-opinion search is wanted. Use when the user asks
  to use Gemini or Claude for web research, asks for AI-backed web search, or
  wants an external CLI to verify current information with source URLs.
---

# AI web search

Delegate a web-research query to another AI CLI.

## Arguments

- First token may be `gemini` or `claude` to pick provider
- Default provider: `gemini`
- Remaining text is the query
- Query is required

## Behavior

- Run non-interactive
- Restrict tools to web search, web fetch, and file read only
- Use timeout of at least 60 seconds
- Request source URLs
- Forbid file edits, shell, and write tools in delegated prompt

## Gemini

Built-in tool names:

- `google_web_search`
- `web_fetch`
- `read_file`

Run:

```sh
gemini -p "Research: <query>.
Use ONLY google_web_search, web_fetch, and read_file. Do NOT call write_file,
replace, run_shell_command, or any edit tool. Return concise answer with source
URLs. Do not make any file changes."
```

## Claude

Built-in tool names:

- `WebSearch`
- `WebFetch`
- `Read`

Run:

```sh
claude -p --tools "WebSearch,WebFetch,Read" \
  "Research: <query>. Return concise answer with source URLs."
```

## Output

Return the CLI stdout verbatim, prefixed with provider name:

```text
[provider: gemini]
<output>
```

## Failure modes

- CLI not installed: report which CLI is missing and stop
- Timeout: report timeout and stop
- Non-zero exit: report exit code and stderr tail
