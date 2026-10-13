# bash-bg-run

Pi extension. Runs a bash command in the background so the agent stays
responsive. Pi's built-in `bash` tool is synchronous and has no background mode.

## Tools

- `bash_bg_run(command, timeout?)` - starts the command and returns at once with
  a job id (the pid) and a log file path
- `bash_bg_kill(pid)` - stops a job started by `bash_bg_run`

The agent does not wait or poll. When the command ends, a message with the exit
code, the log path, and the last lines of output wakes the agent. While the
command runs, the agent reads the log with `tail`, `head`, `rg`, or `read`.

## How it works

1. `bash_bg_run` calls `createLocalBashOperations().exec()` from pi, without
   `await`. Pi handles shell config, the detached spawn, timeout, process-tree
   kill on abort, and cleanup of children on pi shutdown.
2. `exec()` does not expose the child pid. The command is prefixed with
   `echo $$;`. The first output line is the shell pid, which `jobs.ts` strips
   from the log and returns as the job id.
3. Pi spawns with `detached: true`, so the pid is also the process group id.
   `kill -- -<pid>` stops the whole tree.
4. Output goes to `/tmp/pi-bash-bg-logs/<iso-date>_<pid>.log`. The date has `:`
   replaced by `-`. The file opens with `wx`, so a name collision fails instead
   of overwriting. Directory mode is `0700`, file mode is `0600`.
5. `bash_bg_kill` aborts the job's `AbortController`. Pi's `exec()` kills the
   process tree. An unknown pid returns an error that names the manual fallback
   `kill -- -<pid>`.
6. On exit, `notify.ts` reads the last 8 KB of the log (positional read, so
   memory stays flat for any log size), drops the partial first line, keeps the
   last 50 lines, and sends them with
   `pi.sendMessage(..., { triggerTurn: true, deliverAs: 'followUp' })`. A throw
   from `sendMessage` (stale `pi` after `/reload`) is swallowed.
7. On `session_shutdown` (exit, `/reload`, `/new`, fork, switch), `index.ts`
   calls `jobs.killAll()`.

## Files

- `index.ts` - coordinator. Registers the two tools and wires the modules. The
  only file that imports Pi at runtime
- `jobs.ts` - `createJobs()` with `start()`, `kill()` and `killAll()`. Takes
  `BashOperations` and a log directory as arguments, so tests can inject a fake
- `notify.ts` - `readTail()` and `createNotifier()`. Takes `sendMessage` and
  `truncateTail` as arguments
- `tools.ts` - `createToolHandlers()`: the `execute` logic of both tools
- `format.ts` - builds the completion message
- `*.test.ts` - tests

## Tests

```bash
node --test 'AI-configs/pi/extensions/bash-bg-run/*.test.ts'
tsc --noEmit -p AI-configs/pi/tsconfig.json
```

`node:test` runs the `.ts` files with Node type stripping (Node 22.19 or newer).
No dependencies. One test runs `sleep 3` through the installed pi's real
`createLocalBashOperations()` and asserts `bash_bg_kill` stops it. It reads the
pi version from `~/.pi/agent/install/current-version` and skips if the install
is missing.

## Why not `bg_wait`

`bg_wait` belongs to the `pi-subagents` extension, not to this one. It waits for
`pi-subagents` runs and for jobs from providers registered through
`registerBackgroundWorkProvider`. This extension does not register one, so
`bg_wait` cannot see `bash_bg_run` jobs.

An agent confused `bg_wait` with the old `bg_run` and `bg_kill` names: same
`bg_` prefix, and `bg_wait` describes itself as waiting for background work.

Decisions:

- Renamed the tools to `bash_bg_run` and `bash_bg_kill`, to drop the shared
  `bg_` prefix
- The tool descriptions say the agent must not wait for a job, and do not name
  `bg_wait`
- Did not register a `bg_wait` provider. It would make this extension depend on
  `pi-subagents`

## Limitations

- macOS and Linux only. Pi does not set `detached` on Windows, so the pid is not
  a process group id there
- Job ids live in memory. After a pi restart `bash_bg_kill` no longer knows old
  pids, but the log files stay on disk
- Jobs stop on `session_shutdown`. Pi also kills its tracked children on exit
- The log has no size cap. A noisy job can fill `/tmp`
- No periodic polling. The agent checks the log only during its own turns, or
  when a job end wakes it

## References

- Pi extension API: [`docs/extensions.md`][pi-ext], and `ExtensionAPI` in
  `packages/coding-agent/src/core/extensions/types.ts` (`registerTool`,
  `sendMessage`)
- Pi bash tool and operations: `packages/coding-agent/src/core/tools/bash.ts`
  (`createLocalBashOperations`, `BashOperations`)
- Pi source: <https://github.com/earendil-works/pi>
- Why pi has no background bash: [pi coding agent blog post, "No background
  bash"][pi-blog] (2025, the section recommends tmux; current docs do not repeat
  it)
- `pi-subagents` provider API: `docs/extension-api.md`, section "Background-work
  provider API", in the `pi-subagents` package
- Local paths:
  - `~/.pi/agent/extensions/` - whole-dir link to `AI-configs/pi/extensions/`.
    Every extension in it auto-loads. Run `/reload` after changes
  - `~/.pi/agent/install/releases/<version>/` - managed pi install. Pinned in
    `AI-configs/pi/tsconfig.json`
  - `~/.pi/agent/npm/node_modules/pi-subagents/` - `pi-subagents` package
  - `/tmp/pi-bash-bg-logs/` - job logs

[pi-ext]:
  https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md
[pi-blog]: https://mariozechner.at/posts/2025-11-30-pi-coding-agent/
