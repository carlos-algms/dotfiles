Apply dispatcher values: `plan_path`, `task_id`, `working_dir`, `plan_base_ref`,
`baseline_snapshot`, and optional `context`.

Own `task_id` completely: implementation, plan checkboxes, verification,
reviewers, fixes, and commits. A reviewer fix may also update affected completed
tasks and their checkboxes. Never edit future task state or final checkpoints.
The plan is the only normative spec; `context` is orientation only. Operate in
`working_dir`.

## Workflow

1. Read the plan header, task, convention sources, commit policy, plan-file
   policy, `Execution log`, and available skills. A logged entry overrides
   contradicting task text
2. Read the classified `baseline_snapshot`. Treat `No commits` plus a requested
   PR as commit-bound for scope safety. Before editing any commit-bound target
   or reviewer-fix path, stop if it carries `baseline-only` content. Under
   `Per-task commits`, never review or commit another task's initial work.
   Cumulative scope includes completed earlier tasks and excludes later tasks
3. Capture `task_base_ref = git rev-parse HEAD`
4. Execute every task step; tick a step after its `Green:` passes
5. Run the task-ending full gate
6. Under `Per-task commits`, load `git-commit-message`, tick the task commit
   checkpoint immediately before staging, and commit the actual task diff
7. Run the spec-review loop
8. Run the code-quality-review loop
9. Confirm the full gate is still green and the task has no unresolved findings
10. Write the execution log (below) before returning
11. Return only the output contract below

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

- Spec: `spec-reviewer-prompt.md`
- Quality: `code-quality-reviewer-prompt.md`
- Quality checklist: `../requesting-code-review/code-reviewer.md`

Before each dispatch, derive `changed_files` from the current committed, staged,
unstaged, deleted, and untracked implementation diff. Exclude `execution-state`
paths and snapshot entries outside the selected scope. Use newline-delimited
exact paths. Initial plan file lists are hints only.

Use task scope with `task_base_ref` for `Per-task commits`. Use cumulative scope
with `plan_base_ref` for `One commit at the end` or `No commits`.

Dispatch spec review with:

```text
MUST read instructions at <skill_dir>/spec-reviewer-prompt.md FIRST.
Apply:
  plan_path         = <abs path>
  task_id           = <current and affected completed task ids>
  base_ref          = <task_base_ref | plan_base_ref>
  scope_mode        = <task | cumulative>
  baseline_snapshot = <abs path to classified snapshot directory>
  changed_files     = <newline-delimited exact paths>
  solved_defects    = <plan list or `none`>
```

Dispatch quality review with:

```text
MUST read instructions at <skill_dir>/code-quality-reviewer-prompt.md FIRST.
Apply:
  plan_or_requirements = <task or cumulative plan reference>
  task_id             = <current and affected completed task ids>
  scope_mode          = <task | cumulative>
  base_ref             = <task_base_ref | plan_base_ref>
  baseline_snapshot    = <abs path to classified snapshot directory>
  changed_files        = <newline-delimited exact paths>
  solved_defects       = <plan list or `none`>
  checklist_path       = <abs quality-checklist path>
```

## Review loop

For spec, then quality:

1. Dispatch a fresh reviewer
2. `PASS`: continue
3. Findings: verify each citation, un-tick affected steps, fix substantiated
   issues, update `Solved defects`, re-run the full gate, and re-tick verified
   steps
4. Under `Per-task commits`, commit that review round's actual fixes with
   `git-commit-message`
5. Re-dispatch until `PASS`; maximum 3 finding/fix rounds per stage

A quality fix changing behavior, scope, contracts, or verification reopens spec
review before quality continues.

Incorrect findings get one clarification re-dispatch with counterevidence.
Empty, errored, or malformed responses get 3 total attempts. A `<review-input>`
finding is a failed dispatch; correct the payload. A remaining dispute, third
failed dispatch, failed gate, unsafe commit scope, or fourth finding round
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
VERIFY {"command":"<command>","exit_code":0,"result":"<success token>"}
COMMITS | <sha[,sha...] | none>
FIXED
- <path:line> | <problem> | <fix>
LEARNED
- <task_id> | <drift|gotcha|decision> | <plan assumed> | <actual and change>
```

Emit one `VERIFY` line per full-gate command. Merge duplicate `FIXED` root
causes. Emit valid compact JSON and escape dynamic strings.

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
