---
name: subagent-driven-development
description: >
  Subagent-per-task MODE of executing-plans. Requires executing-plans, which
  holds the shared rules; load that first if it is not already loaded.
---

# Subagent-driven development

Use only after `executing-plans` completes its start gates. Delegate each full
task cycle to one fresh implementer.

## Workflow

For each incomplete task:

1. Run `scripts/task-start PLAN_FILE N`
2. Seed `<workspace>/task-<N>-paths.txt` from the paths in the task's
   `**Edit <label>:**` and `**Changes:**` lines, each once
3. Dispatch one implementer with the payload below
4. On `PASS`, retain its exact `PACKAGE`, `REVIEW`, `VERIFY`, `LEARNED`, and
   `DISMISSED` lines
5. Under `Checkpoint commits` with `git_owner=coordinator`, stage only the
   task's owned path list, create its mechanical commit, and verify the commit
   contains no other path
6. Tick the task; tick its checkpoint only after its Git owner committed
7. Dispatch the next task
8. On `BLOCKED`, read its `need` field
   1. It names user input, credentials, access, or a missing or non-unique
      anchor: relay the blocker and stop
   2. Otherwise, below the top tier: dispatch a fresh implementer one tier up
      with the same `brief_path`, `review_paths_file`, and `task_base_ref`, plus
      `prior_report` and `escalated_from`. Never re-run `task-start`
   3. At the top tier: relay the blocker and stop

After all tasks, dispatch one fresh finalizer. Relay its result without
rerunning review or verification. After its `PASS`, relay every
`**Manual check (user):**` item to the user and wait for each result. Delete the
workspace only after final `PASS` and every manual check passed.

The implementer owns implementation, verification, review fixes, path-list
updates, task recording, and executor-owned checkpoint commits. The orchestrator
never edits implementation files, runs gates, reads review packages, or
interprets nested reviewer output.

## Model selection

Map each task's `Difficulty` to the current harness:

- `low`: cheapest reliable editing model
- `medium`: default coding model
- `high`: most capable available model

Use a reviewer one tier above the implementer, capped at the most capable model.
Name every dispatched model. Treat missing or invalid difficulty as `high` and
report it.

Escalate one tier per `BLOCKED`, up to the most capable model. The reviewer
stays one tier above the current implementer, capped. Name every escalated
model.

## Orchestrator state

Keep only:

- Task status and task ID
- Exact `PACKAGE`, `REVIEW`, `VERIFY`, `LEARNED`, and `DISMISSED` lines
- `plan_base_ref`, workspace path, and execution ownership values
- Implementer and finalizer handles while active

The ledger is authoritative resume state. Re-run a checked task's gate when its
completion line is missing.

Malformed or verbose subagent output gets one corrective redispatch. Stop on a
second invalid response.

## Implementer payload

Pass absolute paths and values. Never paste task, prompt, report, or package
contents.

```text
MUST read <skill_dir>/implementer-prompt.md and
<skill_dir>/review-loop.md before acting.

brief_path         = <path printed by task-start>
preamble_path      = <workspace>/preamble.md
task_id            = <task number>
working_dir        = <absolute repo or worktree path>
workspace_dir      = <absolute plan workspace path>
ledger_path        = <workspace>/progress.md
review_paths_file  = <workspace>/task-<N>-paths.txt
plan_base_ref      = <SHA captured by executing-plans>
task_base_ref      = <SHA printed by task-start>
commit_policy      = <Checkpoint commits | No commits>
git_owner          = <coordinator | executor>
prior_report       = <absolute report path of the BLOCKED attempt | none>
escalated_from     = <model of the BLOCKED attempt | none>
context            = <non-normative orientation only>
```

Put every requirement in the brief or shared preamble. `context` never carries
requirements or design decisions.

## Finalizer payload

```text
MUST read <skill_dir>/finalizer-prompt.md and
<skill_dir>/review-loop.md before acting.

plan_path            = <absolute plan path>
working_dir           = <absolute repo or worktree path>
workspace_dir         = <absolute plan workspace path>
ledger_path           = <workspace>/progress.md
plan_base_ref         = <SHA captured by executing-plans>
review_evidence       = <exact retained REVIEW lines | none>
verification_evidence = <exact retained VERIFY lines | none>
review_packages       = <task ids with absolute PACKAGE paths | none>
commit_policy         = <Checkpoint commits | No commits>
git_owner             = <coordinator | executor>
milestone_owner       = <coordinator | executor>
pr_owner              = <coordinator | executor>
plan_id               = <stable milestone plan ID | none>
```

The finalizer is the only subagent receiving `plan_path`.

## Scripts

Resolve relative to this file:

- `scripts/plan-workspace PLAN_FILE`
- `scripts/plan-preamble PLAN_FILE`
- `scripts/task-start PLAN_FILE N`
- `scripts/task-done LEDGER N BASE HEAD STATE EVIDENCE_FILE`
- `scripts/review-package BASE HEAD OUTFILE PATHS_FILE`

## Output handling

- Preserve every `PACKAGE`, `REVIEW`, and `VERIFY` line with its task ID
- Relay every `LEARNED`, `DISMISSED`, `STATE`, and `MILESTONE` line unchanged
- Do not report absent optional blocks
- Never synthesize evidence or grant Git or milestone ownership
- Create a requested PR only when `pr_owner=executor`; otherwise relay
  `PR | coordinator`

## Integration

- `review-loop.md`: shared review mechanics
- `reviewer-prompt.md`: read-only craft and requirements reviewer
- `finalizer-prompt.md`: complete-plan review, verification, and final state
- `create-pull-request`: required before a requested PR
