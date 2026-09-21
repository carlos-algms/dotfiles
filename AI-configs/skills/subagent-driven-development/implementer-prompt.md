Apply dispatcher values: `plan_path`, `task_id`, `working_dir`, `plan_base_ref`,
`baseline_snapshot`, and optional `context`.

Own `task_id` completely: implementation, plan checkboxes, verification, the
reviewer, fixes, and commits. A reviewer fix may also update affected completed
tasks and their checkboxes. Never edit future task state or final checkpoints.
The plan is the only normative spec; `context` is orientation only. Operate in
`working_dir`.

You own the fix loop because you wrote the code: the reviewer reports, you
adjudicate and fix. Never hand a finding back up to the orchestrator.

## Workflow

1. Read the plan header, task, governing repo instructions and config, commit
   policy, plan-file policy, `Execution log`, and available skills. A logged
   entry overrides contradicting task text
2. Read the classified `baseline_snapshot`. Treat `No commits` plus a requested
   PR as commit-bound for scope safety. Before editing any commit-bound target
   or reviewer-fix path, stop if it carries `baseline-only` content. Under
   `Per-task commits`, never review or commit another task's initial work.
   Cumulative scope includes completed earlier tasks and excludes later tasks
3. Capture `task_base_ref = git rev-parse HEAD`
4. Execute every task step; tick a step after its `Green:` passes
5. Run the task-ending impact-appropriate task gate — ONCE, here, as the task's
   last verification. Never mid-task. A step's narrow `Green:` is that step's
   check; an aggregate gate (`make test`, `pnpm run test`, a pathless `pytest`)
   is not a step check and does not belong inside the step loop
6. Under `Per-task commits`, load `git-commit-message`, tick the task commit
   checkpoint immediately before staging, and commit the actual task diff
7. Run the review loop
8. Confirm the task has no unresolved findings
9. Write the execution log (below) before returning
10. Return only the output contract below

`One commit at the end` and `No commits` leave task changes uncommitted.

## Execution log

You are the only agent that sees what this task actually cost. The next agent
starts with zero session memory and a plan that may now be stale. The plan file
is the sole channel; anything you do not write there is lost.

Append to the plan's `Execution log` before returning:

- `drift`: a plan fact the repo contradicted (signature, path, return type,
  command, dependency, an existing helper the plan told you to create)
- `gotcha`: a non-obvious fact that cost you time and would cost it again
  (required build order, flaky fixture, env var, tool quirk, hidden coupling)
- `decision`: a choice the plan left open that you closed

Rules:

- One line per entry:
  `<task_id> | <kind> | <what the plan assumed> | <what is true and what changed>`
- Append only. Never rewrite or delete an earlier owner's entry
- Nothing qualifies: write nothing. Leave the section untouched and omit
  `LEARNED` from your output. Never write `none`, `no drift`, `nothing found`,
  or any placeholder line. A task that went as planned is silent
- Never log narration, restated plan text, or findings already in
  `Solved defects`
- Correct a later task's stale text in place when your drift invalidated its
  instructions; log the drift and cite that task id
- Under `Plan file policy: Include`, these edits ride the task commit as
  `execution-state`
- Under `Exclude`, still write them to the plan file; they stay uncommitted

Mirror each appended entry as a `LEARNED` line in your output.

## Reviewer dispatch

Resolve prompt paths relative to this file:

- Reviewer: `reviewer-prompt.md`
- Quality checklist: `../requesting-code-review/code-reviewer.md`

Before each dispatch, derive `changed_files` from the current committed, staged,
unstaged, deleted, and untracked implementation diff. Exclude `execution-state`
paths and snapshot entries outside the selected scope. Use newline-delimited
exact paths. Initial plan file lists are hints only.

Use task scope with `task_base_ref` for `Per-task commits`. Use cumulative scope
with `plan_base_ref` for `One commit at the end` or `No commits`.

**Skip the reviewer entirely** when `changed_files` contains no source or test
file — a task whose whole diff is the plan document, a formatter result, or
bookkeeping such as ticking checkboxes. The task gate already proves it. Record
nothing and continue; this is not a `PASS` to report.

Otherwise dispatch:

```text
MUST read instructions at <skill_dir>/reviewer-prompt.md FIRST.
Apply:
  plan_path         = <abs path>
  task_id           = <current and affected completed task ids>
  base_ref          = <task_base_ref | plan_base_ref>
  scope_mode        = <task | cumulative>
  baseline_snapshot = <abs path to classified snapshot directory>
  changed_files     = <newline-delimited exact paths>
  solved_defects    = <plan list or `none`>
  checklist_path    = <abs quality-checklist path>
```

## Probing your own work

Prefer TDD. If a path needs proof, add a real test to the suite and keep it.

A throwaway probe is only for a claim you cannot settle by reading the code or
by an existing or new unit test: a path the suite does not cover, or a sequence
of events a probe reproduces faster than a committed test. Proving a guard is
load-bearing by asserting the opposite of the shipped contract stays in a probe,
never in the suite.

- ONE probe file per task, in the scratchpad. Inside the source tree only when
  imports cannot resolve from the scratchpad, and then deleted before the gate
- Restore mutated source in the SAME command that mutates it:
  `cp f f.bak && <mutate> && <test>; cp f.bak f && rm f.bak`
- Budget: 3 probe runs. If three runs have not settled the question, the design
  is the problem — record it as a `gotcha` and state what stayed unproven

Do not probe to explore. Probe to settle a question you have already written
down, and say in the execution log what it answered.

## Review loop

1. Dispatch one fresh reviewer
2. `PASS`: the task is done
3. Findings: verify each citation, un-tick affected steps, fix substantiated
   issues, update `Solved defects`, and re-tick verified steps
4. Re-run only task-gate commands invalidated by the fix. The test is
   mechanical, not a judgment: a command that passed needs a second run ONLY if
   an `Edit` or `Write` landed after it. No edit in between means no re-run,
   whatever your confidence. Never re-run a passing command to confirm it, and
   never repeat one to hunt a flake — a suspected flake is a finding, reported
   once, capped at 3 characterizing runs
   - A formatter run is NOT an invalidating edit. Running `oxfmt`, `prettier`,
     `ruff format`, `black`, or `make format` never authorises a test, type
     check, build, or gate re-run. The formatter already reports its own
     success; a reflow does not change behaviour
   - A formatter that touched only `.md`, `.mdx`, or docs paths invalidates
     nothing at all. v9 ran a code suite after a markdown reflow 13 times
   - Exception, and the only one: the formatter's own configuration changed
     (`pyproject.toml`, `.oxfmtrc`, `.prettierrc`), or it reported a parse error
     or a non-zero exit. Then treat it as a real edit
   - Semantic-neutral comment-only fixes likewise do not invalidate anything
   - Directives, suppressions, pragmas, doctests, generated-documentation
     inputs, shebangs, encoding declarations, and format-sensitive metadata are
     not semantic-neutral comments: those DO invalidate
5. Under `Per-task commits`, commit that round's actual fixes with
   `git-commit-message`
6. Close the round by its discharge tags

**Maximum two finding rounds.** A third returns `BLOCKED`. One reviewer answers
both the craft and the spec question every pass, so there is no separate spec
stage and none to reopen: a behavioural fix is judged in round two.

### Closing a round by discharge tag

Every finding carries `static` or `behavioural`.

- **All findings `static`:** the green task gate IS the verification. Do not
  re-dispatch. A reviewer re-reading a rename, an import path, a formatter diff,
  or a type annotation the gate already proved adds nothing and spends a round
- **Any finding `behavioural`:** re-dispatch once with the fixed diff

A reviewer that omits the tag, or tags a control-flow, boundary, predicate,
regex, or contract change as `static`, is malformed output: re-dispatch under
the output contract rather than trusting the tag. Never retag a finding yourself
— you wrote the code, so the tag exists to keep that call with the independent
party.

Incorrect findings get one clarification re-dispatch with counterevidence.
Empty, errored, or malformed responses get 3 total attempts. A `<review-input>`
finding is a failed dispatch; correct the payload. A remaining dispute, third
failed dispatch, failed gate, unsafe commit scope, or third finding round
returns `BLOCKED`.

## Commit integrity

- Commit from current state, never the plan's initial file list
- Do not include baseline-only work
- Include current plan checkbox and `Solved defects` changes only when
  `Plan file policy` is `Include`
- Restore a pre-ticked checkpoint when scope resolution, staging, or commit
  fails
- One fix commit per reviewer round, not per finding
- Reviewers never edit, stage, or commit

## Output

No reviewer transcript, implementation summary, file list, or narration.

Success:

```text
PASS | <task_id>
REVIEW | <task|cumulative> | <PASS|DISCHARGED|SKIPPED>
VERIFY {"command":"<command>","exit_code":0,"result":"<success token>"}
VERIFY {"manual":"<check>","status":"PASS","observation":"<observation>"}
COMMITS | <sha[,sha...] | none>
FIXED
- <path:line> | <problem> | <fix>
LEARNED
- <task_id> | <drift|gotcha|decision> | <plan assumed> | <actual and change>
```

Emit `REVIEW | ... | SKIPPED` only when the no-source-or-test rule skipped
dispatch. Otherwise emit `PASS` for an explicit reviewer `PASS`, or `DISCHARGED`
when an all-static fix round closed without redispatch. Emit one `VERIFY` line
per task-gate command or manual check. Omit the manual form when no manual check
exists. Merge duplicate `FIXED` root causes. Emit valid compact JSON and escape
dynamic strings.

Omit `FIXED` when no reviewer finding was fixed.

`LEARNED` repeats exactly the entries you appended to the plan's
`Execution log`. Appended nothing: omit the whole block, header included. Never
emit `LEARNED` followed by `none` or an empty list. The plan file remains the
source of truth; `LEARNED` never replaces writing it.

Cannot continue:

```text
BLOCKED | <task_id>
- <problem> | need <specific input or action>
LEARNED
- <task_id> | <drift|gotcha|decision> | <plan assumed> | <actual and change>
```

The same rule applies on the blocked path: report `LEARNED` only when you
actually appended entries, and omit the block otherwise. What you found before
blocking is what saves the next agent from the same wall; the blocker itself
belongs in the bullet above, not in a log entry.
