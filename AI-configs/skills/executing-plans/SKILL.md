---
name: executing-plans
description: >
  Use when you have a written implementation plan to execute in a separate
  session with review checkpoints
---

# Executing plans

Validate one saved plan, then execute it inline or delegate complete task cycles
to `subagent-driven-development`.

Resolve helper scripts and `review-loop.md` from
`../subagent-driven-development/`.

## Start gates

1. Require a readable `plan_path`
2. Read the plan's `Spec` path when it is not `none`
3. Require `Execution mode: Inline | Subagent-Driven`
4. Require `Commit policy: Checkpoint commits | No commits`
5. Require `Plan file policy: Include | Exclude`
6. Require `Additional plan state files` as the single item `none` or unique,
   existing, repo-relative paths that exclude the plan itself
7. Resolve the workspace with `scripts/plan-workspace PLAN_FILE`
8. Read its initialized `progress.md` and resume at the first task without a
   matching completion line
9. Extract the shared preamble with `scripts/plan-preamble PLAN_FILE`
10. Capture `plan_base_ref = git rev-parse HEAD`
11. Run the interface scan below
12. Create the harness task list

Reject missing fields instead of supplying defaults. Resolve a request that
conflicts with the saved plan before implementation.

`Plan state` means the plan file plus every additional plan state path. Apply
one `Plan file policy` to all of them.

## Owned paths

The active reviewer dispatcher writes one plain file containing exact
repo-relative paths, one per line.

- Seed task scope from the paths in its `**Edit <label>:**` and `**Changes:**`
  lines, each once
- Add a discovered path before editing it and record one ledger `Ruling:`
- Treat each listed path as wholly task-owned, including all its hunks
- Include listed untracked files
- Ignore every unlisted worktree path
- Never infer ownership from `git status`
- Reject duplicates, directories, missing paths, and paths outside the repo

Build review packages with:

```text
scripts/review-package BASE HEAD OUTFILE PATHS_FILE
```

Retain the printed `state: sha256:<digest>` with every `REVIEW` and `VERIFY`
line. Reuse evidence only while rebuilding the same scoped package produces the
same digest.

## Interface scan

Before Task 1, compare every present `Interfaces` block. Record one pre-flight
ledger row for each cross-task contract, including any ruling required to make
producer and consumer signatures match. Tasks without cross-task contracts need
no row.

## Ledger

`plan-workspace` creates `<workspace>/progress.md` with:

```text
# Plan ledger - plan: <repo-relative plan path>
```

Append only:

- `Task <N>: complete (...)`, written by `scripts/task-done`
- `Task <N>: Ruling: <decision> - <why> - <cost if wrong>`
- `final: Ruling: <decision> - <why> - <cost if wrong>`
- `Pre-flight: <contract check>`

The ledger is authoritative resume state. A checked task without a matching
completion line must pass its gate again.

Record only plan drift, non-obvious gotchas, and decisions the plan left open.
Write nothing when execution follows the plan.

## Execution ownership

The caller supplies these values for milestone execution:

- `workspace_mode`: `shared`, `isolated`, or `sequential`
- `git_owner`: `coordinator` or `executor`
- `milestone_owner`: `coordinator` or `executor`
- `pr_owner`: `coordinator` or `executor`

Direct execution defaults to `sequential` with the executor owning Git, any
milestone update, and any requested PR.

Shared parallel execution requires disjoint owned paths and command outputs.
Only the coordinator stages, commits, or integrates while shared workers run.

Isolated workers use `git_owner=executor` for mechanical checkpoint commits and
`pr_owner=coordinator`. The coordinator squashes each result into the active
feature branch serially, rebuilds the package from the same owned path list, and
requires the integrated digest to equal the worker's reviewed digest.
`No commits` disables isolated execution; use safe shared execution or run
sequentially.

The milestone owner validates the completed plan's link, checks its one box,
preserves every other entry, formats the file, and verifies the link after the
plan passes. Workers never edit a coordinator-owned milestone.

## Commit ownership

- `Checkpoint commits`: create mechanical state commits at written checkpoints
- `No commits`: never stage or commit
- Load `git-commit-message` at each commit
- Derive commit paths from the current owned path list, never from `git status`
- Include plan state only under `Plan file policy: Include`
- Reviewers never edit, stage, or commit
- A requested PR requires committed reviewed work

## Execution modes

For `Subagent-Driven`, load `subagent-driven-development` after all start gates
and never run the inline workflow.

For `Inline`, execute the workflow below.

Exactly one agent runs final verification:

- Inline: this executor
- Subagent-Driven: the finalizer

## Inline task workflow

For each task:

1. Run `scripts/task-start PLAN_FILE N`
2. Read the generated brief and shared preamble
3. Write `<workspace>/task-<N>-paths.txt`
4. Implement every step
5. Run the task gate once as the last implementation verification
6. Write `<workspace>/task-<N>-report.md` with built behavior and `VERIFY` lines
7. Build the scoped review package
8. Apply `review-loop.md` unless every owned change is proven bookkeeping or
   canonical formatter-only output
9. Rebuild the package and retain its final digest
10. Under `Checkpoint commits`, execute the written checkpoint when this
    executor owns Git
11. Run record-only `scripts/task-done` with the ledger, refs, digest, and
    report
12. Tick the task; tick its checkpoint only after its Git owner committed

Never dispatch review on a red gate. Never rerun a passing gate without an
invalidating semantic edit.

## Review dispatch

Use the contract in `review-loop.md`. Pass:

```text
requirements_path = <task brief or complete plan>
requirements_kind = <task | plan>
spec_path          = <complete-plan spec path | none>
report_path        = <task or final report>
package_path       = <scoped package>
review_paths_file  = <dispatcher-owned path list>
state_digest       = <digest printed by review-package>
scope_mode         = <task | cumulative | complete>
task_id            = <task number | all>
checklist_path      = <requesting-code-review/code-reviewer.md>
```

The dispatcher may skip review only when every owned change is execution-state
bookkeeping, checkbox-only, or canonical formatter-only output. Configuration,
manifests, migrations, CI, build scripts, generated contracts, and instruction
files are behavior-bearing unless repository evidence proves otherwise.

## Finish

After all tasks complete:

1. Build the complete owned path list from task path lists
2. Execute the written final-verification checkpoint
3. Reuse task evidence only when each task package's state entries match the
   same paths in the complete package; combine matching task packages when their
   union covers the complete scope
4. Review uncovered behavior through `review-loop.md`
5. Run only final checks whose semantic scope remains uncovered
6. Append final rulings and tick final verification
7. Execute the final state checkpoint under `Checkpoint commits`
8. After isolated integration, require the integrated package digest to match
   the worker's final reviewed digest
9. Let the milestone owner update the milestone
10. Let the PR owner create a requested PR only from committed reviewed work
11. Delete the plan workspace after `PASS`
12. Report changed files, evidence, rulings, dismissals, remaining risks, and
    excluded modified plan state

## Stop conditions

- Missing or conflicting plan fields
- Unsafe or ambiguous owned paths
- A red task gate
- Unresolved review findings
- Exhausted review or dispatch attempts
- Unsafe shared execution or integration
- A required reviewer, coordinator, Git owner, milestone owner, or PR owner is
  unavailable

Report the exact blocker and required action. Resume from the ledger after it is
resolved.
