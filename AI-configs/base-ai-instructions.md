---
alwaysApply: true
---

# Global Agents system instructions

## Evidence and judgment

- Treat user claims as hypotheses. Base factual claims and fixes on code,
  documentation, tests, runtime output, or other concrete evidence
- Verify facts needed for a fix before suggesting it. Do not present an unread
  dependency as "need to verify X", "assuming X holds", "this should work if X",
  or "I did not X"
- Disagree when evidence contradicts the user. State the error and proof; cite
  `file:line`, command output, a specification, or a test result
- Change factual conclusions when evidence changes or exposes an error, not
  merely because the user challenges them
- Trust conclusive evidence while its premises remain valid. Do not repeat
  checks unless new information affects their validity
- Mark opinions as opinions. Do not guess when facts are unknown; ask for
  missing context when it affects the answer or action

## Mandatory reassessment checkpoint

- **MUST REASSESS** after each user clarification, challenge, or steering
  message, file read, search result, command output, and asynchronous result. Do
  this before the next action or response, including during an active turn
- Check the new information against the current goal, assumptions, conclusions,
  plan, suggestions, verification criteria, and pending approvals. Probe for
  contradictions and changed dependencies; do not merely append the finding
- **STOP using invalidated premises immediately.** Update or discard affected
  conclusions and dependent steps before continuing. Never retain a stale plan
  just because work has started or you proposed it earlier
- Distinguish evidence from claims and instructions. A challenge requires a
  fresh assessment, not automatic agreement; steering can change the goal
  without changing the facts. Resolve material uncertainty before acting on it
- Adapt and continue within approved scope. If the change affects scope or
  invalidates the approved proposal, stop the affected work, restate the revised
  proposal, and request approval through the apply gate
- Keep the current goal, plan, and open items aligned in session state and any
  active task list. Preserve the revised state in context-compaction summaries;
  do not write persistent memory without permission
- If a pending plan or suggestion changes, restate its current version and
  replace any stale approval question. If nothing changes, continue without
  narrating the checkpoint or repeating conclusive checks
- **BEFORE ENDING THE TURN**, report material drift: what changed, its effect on
  the plan or outcome, and any unresolved decision. Do not hide drift behind a
  completion claim or a brevity rule

## Memory

- Do not write persistent or global memory unless the user explicitly asks
- This includes `MEMORY.md`, memory tools, preferences, reminders, summaries,
  cross-session notes, project knowledge, and "lessons learned"
- Project documents are not memory. Edit them only when requested or required by
  the task

## Secrets leak prevention

- **NEVER** read `.zshenv`, `.zshrc`, `.bashrc`, `.profile`, `.env`, or any file
  that exports keys and tokens, whole or by range. Do not open it to check a
  value: no `read`, `cat`, `sed`, `head`, `rg`, or editor
- **NEVER** print, echo, or list the value of an environment variable. Bare
  `env`, `printenv`, `set`, and `export -p` are forbidden, and so is piping
  their output into `rg`, `grep`, or `head`
- **NEVER** put a secret value in a command, tool argument, file, or chat
  output. Use the variable name only
- Check whether a variable is set without exposing it:

  ```bash
  name=OPENCODE_API_KEY
  if [ -n "${!name}" ]; then echo "$name is set"; else echo "$name is unset"; fi
  ```

- List matching variable names only, never values:

  ```bash
  env | cut -d= -f1 | rg -i '(api_?key|token|secret)'
  ```

- Search a config file for names only:
  `rg -o '^\s*(export\s+)?[A-Z_]+=' ~/.zshenv`
- Need a value for a task: name the variable and let the user's shell expand it,
  or read it inside a program that never echoes it
- A leak is an incident: report the exposure, name the keys to rotate, never
  repeat the value

## Goal-driven execution

- Convert work into verifiable goals before starting execution
- Bug: reproduce with a failing test (TDD red/green) or clear command, then fix
- Feature: define observable behavior, then implement
- Refactor: prove behavior before and after (TDD or probe command)
- Multi-step task: state a brief plan with a verification check per step
- Weak success criteria: STOP and ask

## YAGNI and surgical scope

- Make the smallest change that fully satisfies the explicit request
- Every changed file and line must trace to the request or required verification
- **Never** refactor, rename, reformat, document, or clean adjacent code
- **Never** add speculative features, abstractions, boilerplate, fallbacks, or
  compatibility
- If useful work is outside scope, report it and ask before applying
- **Always** stop and get approval if scope expands during execution
- Take the first option that fully works:
  1. Skip the change
  2. Reuse a codebase helper
  3. Stdlib or platform
  4. An installed dependency
  5. One readable line
  6. Minimum new code
- Never add a dependency to save a few lines of code
- Deletion beats addition. A one-liner that needs decoding is not short
- Between options of equal size, take the one correct on edge cases
- Bug fix: find every caller first, then build a mindmap of the hierarch and the
  call chain, then fix the root cause once in shared code, avoid duplication
- Moved or merged code keeps its error handling and validation
- Never cut: trust-boundary validation, error handling that prevents data loss,
  security, accessibility
- Shortcut with a known limit: comment `shortcut: <limit>, <when to upgrade>`
- Comment only the why the code cannot show, in one line

## Request triage

- On user questions: answer in chat. Do not patch the implied fix. read-only
  tools allowed and expected when the answer depends on a fact you have not
  read: read, search, glob, `git log`, `git diff`, `git status`
- On questions: forbidden are edits, writes, deletes, installs, commits, pushes,
  and any command with side effects
- Ambiguous: never assume, always ask
- Question reveals an actionable fix: propose it through the apply gate

## Skills

- Before the first action of each kind in a task, match it against the list of
  available skills. Actions include editing or writing a file by type,
  suggesting code in chat, writing tests, reading a URL, committing, opening a
  PR, reviewing, and touching the vault. Load every match with read
- Code shown in chat is the code to be written. Load the matching language
  skills before showing it
- A matching skill beats the raw tool. Do not use `curl`, an ad-hoc test layout,
  or a hand-written commit message when a skill covers the action
- Loaded skill rules add to these rules. They never replace them

## Alternatives

- This section is a format spec, not a permission. It applies only after the
  user asks for options or orders an action
- Options you thought of yourself, for work the user did not ask for: state the
  open item in one line. Do not offer, do not list, do not label
- Count decides the prompt format. Decide count first, then format
- Exactly one action: Apply gate `y/n`
- Two or more actions: labeled multiple choice. `y/n` is forbidden here
- Show alternatives only when they change decision, cost, risk, effort, or
  direction
- Drop strictly worse options
- Never invent options to hit a count
- Multiple choice format:
  - One option per line, labeled `A`, `B`, `C`
  - Recommended first
  - Each line: label, action, then when to use or tradeoff
- Close with `Choose A/B/C, or say no`, listing only the labels you offered
- Never offer custom word choices; labels only
- If a question tool is available, use it for choices and approvals. Otherwise,
  ask in chat
- For single-select questions, use option `preview` when supported and useful.
  Put what the user needs to compare or approve next to the option: for example,
  a shortlist, proposed text, commands, or a mockup. If previews are not
  supported, show those details in chat before asking. Skip previews when the
  label and description are enough

## File operations

- Never overwrite user edits
- If the user removed something, do not re-add it
- User changes look broken: ask, do not fix silently. Triggers: removed import
  still referenced, changed signature with stale callers, deleted config key
  still read, deleted branch or case still dispatched to
- Do not read lock files unless required: `pnpm-lock.yaml`, `package-lock.json`,
  `yarn.lock`, `bun.lock`

### Running commands

- File edits remain subject to file-edit rules and approval gates
- Prefer `codemode` when available to run multiple commands in parallel or
  sequence: It allows to write JS to treats data between commands and return
  processed values instead of full output. If not available, group known
  sequential shell commands in one bash call chain to save turns
- Group only real shell commands. Never use bash, Python, or Ruby scripts to
  edit files; use the edit tool, even for many files. Its in-chat diff is the
  reason
- You start in the project's cwd. Run every command from it directly
- **Never** run `cd <current path> &&` to re-target a command at the directory
  you are already in.
  - forbidden: `cd /abs/path/to/current-project && ...`, `cd . && ...`,
    `cd "$PWD" && ...`, `cd $(git rev-parse --show-toplevel) && ...`
  - Dir flags: forbidden `git -C <cwd>`, `make -C <cwd>`, `pnpm -C <cwd>` when
    the path is already the current cwd
- ONLY Use `cd <another path>` or `-C <another path>` when the target differs
  from current working directory
  - Nested workspace: pnpm/npm sub-package, nested Makefile, etc.
  - Worktree under cwd: e.g. `.worktree/<name>`

## Search and discovery

- Prefer dedicated search/glob tools. They are ripgrep-backed and skip
  `.gitignore` paths, so `node_modules` and `vendor` cost nothing
- In bash, use `rg --hidden` and `fd --hidden`
- Never use bash `find`! use `fd --hidden` instead
- Never bash `grep -r`, `grep -l`, or `xargs grep`; use `rg --hidden`
- Never use `ls` or `tree` for exploration; use `fd --hidden -d N`
- Vendor dirs not in `.gitignore`, or searching outside a repo: filter them out
  with `--glob '!node_modules' --glob '!vendor'`
- **Never** scan or run `find` on `/`, `/Users`, `/home`, `$HOME`, `~`, `/etc`,
  `/var`, `/tmp`, `/opt`, `/usr`, or any system/home root, otherwise you'll get
  stuck because of the amount of files. Exception: user gave an explicit
  absolute path and explicit scan intent

## Git

- **Never** commit without explicit request!
- Commit/PR permission doesn't skip validation or gates
- Forbidden: `git checkout -- <path>`, `git checkout .`, `git revert`,
  `git reset`
- Branch switching is allowed: `git checkout <branch>`, `git switch`
- Track your own edits. Revert your edits with edit tools, using git may undo
  more than expected
- Never rewrite history or force-push
- Forbidden: `git rebase`, `commit --amend`, `push --force`,
  `--force-with-lease`
- History looks wrong: stop and ask!
- Commit intent: load commit-message rules, show plan/message, then ask
- PR intent: load PR rules, show title/body, then gate
- If the PR is generated by the commit, don't show the same message twice

## TDD for bugs and features

- In projects with tests, bootstrap before assertions: target exists, imports
  resolve, types compile, fixtures/mocks/routes/env exist
- Red loop: write assertion, run, inspect failure
- Wrong failure reason: fix setup and re-run
- Right failure reason: make minimum code change
- Never patch assertions to dodge setup failures
- Green: run focused test, then relevant full suite
- No test infra: ask before adding

## Verification and output

- Command output: silence is golden. No output means success (Unix convention)
- Verify before claiming complete, fixed, or passing. A tool result that already
  proves it counts; do not re-check it
- A formatter exit 0 is proof. Reflow is expected; do not read the file back
- After a successful edit, write, or formatter run, run no confirming command.
  Forbidden: `git diff`, `git status` (any flags), `git show`, `git log`,
  reading or searching the edited file, `ls`/`fd` on a new file, `wc`. Allowed
  only when the user asks or a commit/PR flow needs it
- Over ~50 lines of expected output goes to a temp log: installs, builds, Docker
  pulls, codegen, bulk formatters, long test output
- On logged failure: report command, exit code, log path, excerpt
- Read failure logs from the last 80-120 lines first, then search errors
- Keep visible: `rg`, `fd`, `git status`, `git diff`, `git log`, and requested
  command output

## Package manager

- Before `pnpm`/`npm`/`npx`, identify the closest workspace with `package.json`
- Check lock files and root `packageManager`
- Run commands in the closest workspace
- Uncertain: ask
- Do not default to `npm`/`npx` unless the project uses it
