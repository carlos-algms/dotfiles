Apply dispatcher values: `plan_path`, `task_id`, `working_dir`, `plan_base_ref`,
`baseline_snapshot`, and optional `context`.

Own `task_id` completely: implementation, plan checkboxes, verification,
reviewers, fixes, and commits. A reviewer fix may also update affected completed
tasks and their checkboxes. Never edit future task state or final checkpoints.
The plan is the only normative spec; `context` is orientation only. Operate in
`working_dir`.

## Workflow

1. Read the plan header, task, convention sources, commit policy, plan-file
   policy, and available skills
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
10. Return only the output contract below

`One commit at the end` and `No commits` leave task changes uncommitted.

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
```

Emit one `VERIFY` line per full-gate command. Merge duplicate `FIXED` root
causes. Emit valid compact JSON and escape dynamic strings.

Omit `FIXED` when no reviewer finding was fixed.

Cannot continue:

```text
BLOCKED | <task_id>
- <problem> | need <specific input or action>
```
