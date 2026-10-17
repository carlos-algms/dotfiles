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
   `**Files:**` and `**Changes:**` lines, each once. Never re-seed an existing
   file; it holds granted path claims
3. Dispatch one implementer with the payload below. Set `prior_report` to an
   existing `task-<N>-report.md`, else `none`
4. On `PASS`, retain its exact `PACKAGE`, `REVIEW`, `VERIFY`, `LEARNED`, and
   `DISMISSED` lines
5. Under `Checkpoint commits` with `git_owner=coordinator`, leave the checkpoint
   unticked. The root coordinator commits it after the finalizer's `PASS`
6. Tick the task; tick its checkpoint only after its Git owner committed
7. Dispatch the next task
8. On `BLOCKED`, read its `need` field
   1. It names `path claim <path>`: resolve it per `executing-plans`
      `## Path claims`, then dispatch a fresh implementer at the same tier with
      the same `brief_path`, `review_paths_file`, and `task_base_ref`, plus
      `prior_report`. On a stop, relay the blocker and stop
   2. It names user input, credentials, access, a plan-owned decision, or a
      missing file or symbol named in the brief: relay the blocker and stop
   3. Otherwise, below the top tier: dispatch a fresh implementer one tier up
      with the same `brief_path`, `review_paths_file`, and `task_base_ref`, plus
      `prior_report` and `escalated_from`. Never re-run `task-start`
   4. At the top tier: relay the blocker and stop

After all tasks, dispatch one fresh finalizer. Relay its result without
rerunning review or verification. With a root coordinator, it owns manual checks
and workspace deletion.

Without a root coordinator, when the plan has `**Manual check (user):**` items:

1. Dispatch the finalizer with `defer_state=true`
2. After its `PASS`, relay every manual check to the user and wait for each
   result
3. A failed check: stop, keep the workspace, and report
4. All passed: run finalizer steps 10-12 yourself, per `finalizer-prompt.md`
5. Delete the workspace

Without manual checks, use `defer_state=false` and delete the workspace after
the finalizer's `PASS`.

`coordinator` in `git_owner`, `milestone_owner`, and `pr_owner` means the root
milestone coordinator from `plan-a-milestone`, never this orchestrator.

The implementer owns implementation, verification, review fixes, path-list
updates, task recording, and executor-owned checkpoint commits. The orchestrator
never edits implementation files, runs gates, reads review packages, or
interprets nested reviewer output.

## Model selection

Map each task's `Difficulty` to the current harness:

- `low`: cheapest reliable editing model
- `medium`: default coding model
- `high`: most capable available model

Use a reviewer one tier above the implementer, capped at the most capable model,
passed as `reviewer_model`. The finalizer's reviewer uses the most capable
model. Name every dispatched model. Treat missing or invalid difficulty as
`high` and report it.

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
workspace_mode     = <shared | isolated | sequential>
reviewer_model     = <one tier above this implementer, capped>
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
review_packages       = <task ids with absolute PACKAGE paths | none>
commit_policy         = <Checkpoint commits | No commits>
git_owner             = <coordinator | executor>
milestone_owner       = <coordinator | executor>
pr_owner              = <coordinator | executor>
plan_id               = <stable milestone plan ID | none>
reviewer_model        = <most capable available model>
defer_state           = <true | false>
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
- On `PR | pending`, ask the user, then create the PR only after approval;
  otherwise relay `PR | coordinator`

## Integration

- `review-loop.md`: shared review mechanics
- `reviewer-prompt.md`: read-only craft and requirements reviewer
- `finalizer-prompt.md`: complete-plan review, verification, and final state
- `create-pull-request`: required before a requested PR
