# bash-async

Pi extension. Runs a bash command in the background so the agent stays
responsive. Pi's built-in `bash` tool is synchronous and has no background mode.

## Tools

- `bash_async_run(command, timeout?)` - starts the command and returns at once
  with a job id (the pid) and a log file path
- `bash_async_kill(pid)` - stops a job started by `bash_async_run`

The agent does not wait or poll. When the command ends, a message with the exit
code, the log path, and the last lines of output wakes the agent. While the
command runs, the agent reads the log with `tail`, `head`, `rg`, or `read`.

## How it works

1. `bash_async_run` calls `createLocalBashOperations().exec()` from pi, without
   `await`. Pi handles shell config, the detached spawn, timeout, process-tree
   kill on abort, and cleanup of children on pi shutdown.
2. `exec()` does not expose the child pid. The command is prefixed with
   `echo $$;`. The first output line is the shell pid, which `jobs.ts` strips
   from the log and returns as the job id.
3. Pi spawns with `detached: true`, so the pid is also the process group id.
   `kill -- -<pid>` stops the whole tree. A process that calls `setsid` (for
   example the `crit _serve` daemon) leaves that group and survives it, see
   step 7.
4. Output goes to `/tmp/pi-bash-async-logs/<iso-date>_<pid>.log`. The date has
   `:` replaced by `-`. The file opens with `wx`, so a name collision fails
   instead of overwriting. Directory mode is `0700`, file mode is `0600`.
5. `bash_async_kill` first runs `sweep(pid, { walkTree: true })`, then aborts
   the job's `AbortController`. Pi's `exec()` kills the process group. An
   unknown pid returns an error that names the manual fallback `kill -- -<pid>`.
6. On exit, `notify.ts` reads the last 8 KB of the log (positional read, so
   memory stays flat for any log size), drops the partial first line, keeps the
   last 50 lines, and sends them with
   `pi.sendMessage(..., { triggerTurn: true, deliverAs: 'followUp' })`. A throw
   from `sendMessage` (stale `pi` after `/reload`) is swallowed.
7. `sweep.ts` stops what the process group kill misses. The command is prefixed
   with `export PI_ASYNC_JOB=$$;`, so the job id is also an environment tag that
   children inherit through `setsid` and double forks. `sweep` reads `ps axeww`
   (which appends each process's environment) and sends `SIGTERM` to:
   - every process that carries `PI_ASYNC_JOB=<pid>` (exact match)
   - with `walkTree`, every descendant of the job shell, found through `ppid`.
     It runs before the abort, because after the group dies a daemon that stayed
     attached loses its parent link. It is only valid while the shell is alive,
     because a dead pid can be reused

   It runs in `kill()` and `killAll()` (tree and tag), and when a job ends for
   any reason (exit, timeout, abort, log error) in `finish()` (tag only). So a
   job that ends on its own also stops its leftover daemons.

8. On `session_shutdown` (exit, `/reload`, `/new`, fork, switch), `index.ts`
   calls `jobs.killAll()`, then `ui.stop()`, which closes the panel and removes
   the count line.

## Interactive UI

Only with a UI (`ctx.hasUI`); print and RPC modes skip it.

- Count line: `N async running · → to inspect`, left-aligned in a `belowEditor`
  widget, so it renders just above the footer, like the pi-subagents roster. It
  re-renders on every job start and end (`jobs` `onChange`) and is empty at 0
  jobs. `setStatus` cannot reach the first footer line, so it is not used.
- `→` on an empty prompt opens an overlay panel: running jobs on the left, the
  log tail of the selected job on the right. `ui.ts` consumes the key only when
  the editor text is empty, the prompt editor has focus, no panel is open and at
  least one job runs. Otherwise it passes through.
- Panel keys: `j`/`k`/`↑`/`↓` select, `X` (shift+x) kills the selected job at
  once with no confirmation, `J`/`K` scroll the log, `Esc`/`q`/`ctrl+c` close.
  The log follows the tail until scrolled.
- The panel polls the log every 500 ms with `readTail()` from `notify.ts`, so it
  shows the last 8 KB (50 lines) of the log. The full log stays on disk.
- A job that ends leaves the list at once. The panel closes when the last job
  ends.
- `ui.ts` gets the `TUI` from the same widget factory, because pi-tui exposes
  the focused component only there. The focus check duck-types the editor, like
  pi-subagents does.

## Files

- `index.ts` - coordinator. Registers the two tools and wires the modules. With
  `ui.ts` and `panel.ts`, the only files that import Pi at runtime
- `jobs.ts` - `createJobs()` with `start()`, `kill()`, `killAll()` and `list()`,
  and an `onChange` hook. Takes `BashOperations` and a log directory as
  arguments, so tests can inject a fake
- `ui.ts` - count widget, `→` key handler and panel lifecycle
- `panel.ts` - panel rendering, key mapping and log polling. Not unit tested
- `panel-state.ts` - pure selection and scroll logic, `cleanLog()`
- `input.ts` - pure rules for when `→` opens the panel
- `footer.ts` - `formatFooter()`, `footerLines()`
- `sweep.ts` - `sweep()` and the pure `findTargets()`. `createJobs` takes
  `sweep` as an option, so tests can inject a fake
- `notify.ts` - `readTail()` and `createNotifier()`. Takes `sendMessage` and
  `truncateTail` as arguments
- `tools.ts` - `createToolHandlers()`: the `execute` logic of both tools
- `format.ts` - builds the completion message
- `*.test.ts` - tests

## Tests

```bash
node --test 'AI-configs/pi/extensions/bash-async/*.test.ts'
tsc --noEmit -p AI-configs/pi/tsconfig.json
```

`node:test` runs the `.ts` files with Node type stripping (Node 22.19 or newer).
No dependencies. One test runs `sleep 3` through the installed pi's real
`createLocalBashOperations()` and asserts `bash_async_kill` stops it. It reads
the pi version from `~/.pi/agent/install/current-version` and skips if the
install is missing.

## Why not `bg_wait`

`bg_wait` belongs to the `pi-subagents` extension, not to this one. It waits for
`pi-subagents` runs and for jobs from providers registered through
`registerBackgroundWorkProvider`. This extension does not register one, so
`bg_wait` cannot see the jobs started here.

Two agent failures drove the current names:

1. An agent passed the job id to `bg_wait`. Same `bg_` prefix as the old
   `bg_run` and `bg_kill`, and `bg_wait` describes itself as waiting for
   background work
2. After starting a job, an agent ran a second command to wait, sleep or poll
   for it, because the result arrives as a follow-up message rather than as the
   tool result

Decisions:

- Named the extension `bash-async` and the tools `bash_async_run` and
  `bash_async_kill`. No shared prefix with `bg_wait`, and the names read as
  fire-and-forget
- Both descriptions and the prompt guidelines state that nothing waits for the
  job: no sleeping, no polling, no second command, and `bg_wait` cannot see it.
  When nothing else is left to do, the agent ends the turn and reports the job
  id
- The descriptions name `bg_wait` and say it belongs to `pi-subagents`. An
  earlier version deliberately avoided naming it, and agents kept mixing the two
  up
- Did not register a `bg_wait` provider. It would make this extension depend on
  `pi-subagents`

## Limitations

- macOS and Linux only. Pi does not set `detached` on Windows, so the pid is not
  a process group id there
- Job ids live in memory. After a pi restart `bash_async_kill` no longer knows
  old pids, but the log files stay on disk
- `sweep` is best effort, not a lock. A process that clears its environment
  escapes the tag. A macOS system binary (SIP-protected, such as `/bin/sleep`)
  hides its environment from `ps`, so it escapes the tag too. A process forked
  after the scan escapes both. Tested only on macOS; Linux uses the same `ps`
  syntax but is untested
- A command that daemonizes itself and exits right away (`foo --daemon`) has its
  daemon stopped when the job ends. Use `bash` for it
- Jobs stop on `session_shutdown`. Pi also kills its tracked children on exit
- The log has no size cap. A noisy job can fill `/tmp`
- No periodic polling. The agent checks the log only during its own turns, or
  when a job end wakes it
- The panel layout, the focus check and the count widget have no automated test.
  Check them by hand in pi after `/reload`

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
  - `/tmp/pi-bash-async-logs/` - job logs

[pi-ext]:
  https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md
[pi-blog]: https://mariozechner.at/posts/2025-11-30-pi-coding-agent/
