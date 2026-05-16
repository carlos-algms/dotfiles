---
description: >
  Search the internet by delegating to another AI CLI when local web tools are
  unavailable or when a second-opinion search is wanted. Providers: gemini
  (default), claude.
argument-hint: "[gemini|claude] <query>"
---

## Args

- First token in `$ARGUMENTS` may be `gemini` or `claude` to pick provider.
  Default `gemini` if omitted or not one of those two.
- Remainder is the query. Required.

## Behavior

- Run non-interactive (headless).
- Restrict tools to web search + web fetch + file read only.
- Timeout >= 60s (web is slow).
- Always request source links.
- Forbid file edits, shell, or any write tool.

## Provider: gemini

Built-in tool names:

- `google_web_search` - web search
- `web_fetch` - URL fetch
- `read_file` - file read

```bash
gemini -p "Research: <QUERY>.
Use ONLY google_web_search, web_fetch, and read_file. Do NOT call write_file,
replace, run_shell_command, or any edit tool. Return concise answer with source
URLs. Do not make any file changes."
```

## Provider: claude

Built-in tool names:

- `WebSearch` - web search
- `WebFetch` - URL fetch
- `Read` - file read

`--tools` restricts what the model sees; Edit/Bash/Write are not available.

```bash
claude -p --tools "WebSearch,WebFetch,Read" \
  "Research: <QUERY>. Return concise answer with source URLs."
```

## Output

Return the CLI's stdout verbatim to the user, prefixed with the provider name
on its own line:

```
[provider: gemini]
<output>
```

## Failure modes

- CLI not installed: report which one and stop. Do not fall back silently.
- Timeout: report and stop.
- Non-zero exit: report exit code and stderr tail.
