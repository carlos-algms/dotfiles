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
10. Set `plan_base_ref` from the ledger's `Plan base:` line. When absent,
    capture `git rev-parse HEAD` and append `Plan base: <sha>`
11. Run the interface scan below
12. Track tasks in the harness todo or task-list tool when one exists

Reject missing fields instead of supplying defaults. Resolve a request that
conflicts with the saved plan before implementation.

`Plan state` means the plan file plus every additional plan state path. Apply
one `Plan file policy` to all of them.

## Owned paths

The active reviewer dispatcher writes one plain file containing exact
repo-relative paths, one per line.

- Seed task scope from the paths in its `**Files:**` and `**Changes:**` lines,
  each once
- A needed path outside the list is a claim. Resolve it per `## Path claims`
  before editing it
- Treat each listed path as wholly task-owned, including all its hunks
- Include listed untracked files
- Ignore every unlisted worktree path
- Never infer ownership from `git status`
- Reject duplicates, directories, and paths outside the repo. A listed path may
  be missing until its task creates it
- A listed path the task neither creates nor changes: remove it from the list
  and record one ledger `Ruling:`

Build review packages with:

```text
scripts/review-package BASE HEAD OUTFILE PATHS_FILE
```

Retain the printed `state: sha256:<digest>` with every `REVIEW` and `VERIFY`
line. Reuse evidence only while rebuilding the same scoped package produces the
same digest.

## Path claims

The inline executor or the SDD orchestrator resolves each claim:

1. Search the plan's `**Files:**` and `**Changes:**` lines for the path. Another
   task lists it: stop and report
2. Under `workspace_mode=shared` or `isolated`, request a grant from the root
   coordinator through the harness supervisor channel when one exists. Otherwise
   stop and return the claim below; the coordinator grants by appending the path
   and re-dispatches this executor. Denied: stop and report
3. Append the path to `task-<N>-paths.txt` unless the coordinator already did,
   and append one ledger `Ruling:`
4. Resume the task. Never re-seed the path list. Within one run, never re-run
   `task-start`; a re-dispatched executor may re-run it

Claim returned to the coordinator:

```text
BLOCKED | <task_id>
WORKSPACE | <absolute workspace path>
- path claim <path> | need coordinator grant
```

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
- `Plan base: <sha>`, once, at first start

The ledger is authoritative resume state. A checked task without a matching
completion line must pass its gate again.

Record only plan drift, non-obvious gotchas, and open decisions that affect
another task. Write nothing when execution follows the plan.

## Execution ownership

The caller supplies these values for milestone execution:

- `workspace_mode`: `shared`, `isolated`, or `sequential`
- `git_owner`: `coordinator` or `executor`
- `milestone_owner`: `coordinator` or `executor`
- `pr_owner`: `coordinator` or `executor`
- `plan_id`: the stable milestone plan ID, or `none`

`coordinator` means the root milestone coordinator. `plan-a-milestone`
`## Milestone execution` maps each `workspace_mode` to these values.

Direct execution defaults to `sequential` and `plan_id=none`, with the executor
owning Git, any milestone update, and any requested PR.

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

- `Checkpoint commits`: create mechanical state commits at written checkpoints.
  The plan is the user's standing approval for these commits and for coordinator
  squashes into the feature branch. Never ask per commit
- Creating a PR, or squashing the feature branch into the default branch, is a
  user gate. The main agent asks first; a subagent returns `PR | pending`
- `No commits`: never stage or commit
- Load `git-commit-message` at each commit for its message rules
- Derive commit paths from the current owned path list, never from `git status`
- The final state checkpoint commits every owned path still uncommitted, such as
  final-review fixes, plus plan state under `Include`. Nothing uncommitted:
  create no commit. Tick the checkpoint either way
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
3. Seed `<workspace>/task-<N>-paths.txt` unless it exists. Never re-seed it
4. Implement every step
5. Run the task gate once as the last implementation verification, after
   `## Verification selection`
6. Write `<workspace>/task-<N>-report.md` with built behavior and `VERIFY` lines
7. Build the scoped review package and add its digest to every `VERIFY` line
8. Apply `review-loop.md` unless every owned change is proven bookkeeping or
   canonical formatter-only output
9. Rebuild the package, retain its final digest, and update every `VERIFY` line
   to it
10. Under `Checkpoint commits`, execute the written checkpoint when this
    executor owns Git
11. Run record-only `scripts/task-done` with the ledger, refs, digest, and
    report
12. Tick the task; tick its checkpoint only after its Git owner committed

Never dispatch review on a red gate. Never rerun a passing gate without an
invalidating semantic edit.

## Verification selection

Apply before running a task gate or final check. Drop plan commands these rules
make inapplicable or dominated, and record one ledger `Ruling:` per dropped
command.

- Classify each changed file: documentation, source, test, build or tool config,
  generated artifact, other
- Documentation-only changes do not justify unit tests, type checks, or builds
- A test-only change justifies the affected tests, not an unrelated full suite
- Build or tool-config changes justify only the checks they can alter
- A comment-only source change justifies nothing when comments have no
  executable role
- Treat directives, suppressions, pragmas, doctests, generated-documentation
  inputs, shebangs, encoding declarations, and format-sensitive metadata as
  executable, not comment-only
- Never run a test, type check, build, or full gate only to confirm a formatter
  run. Its proof is exit 0 or a clean `--check`, unless the change touched
  formatter configuration
- Remove a command a later command covers plus more, unless an intervening
  action consumes its result
- Treat a result as consumed only when a later action depends on its output,
  pass state, fail state, or artifact
- Compare semantic scope, not command text
- Focused tests immediately followed by a containing suite: keep the suite
- One-file formatting followed by containing multi-file formatting: keep the
  containing one
- A post-write existence or read-back check is dominated when the write reports
  its own failure and a later formatter, parser, test, diff, or review consumes
  the file
- Keep a focused TDD red run when implementation depends on its failure
- Keep a focused green run mid-implementation only when the next action consumes
  it
- Run a relevant full gate at most once per implementation state

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
preamble_path      = <workspace preamble.md for task scope | none>
reviewer_model     = <one tier above the implementer, capped>
checklist_path      = <requesting-code-review/code-reviewer.md>
```

Inline execution uses one tier above this executor's model as `reviewer_model`.

The dispatcher may skip review only when every owned change is execution-state
bookkeeping, checkbox-only, or canonical formatter-only output. Configuration,
manifests, migrations, CI, build scripts, generated contracts, and instruction
files are behavior-bearing unless repository evidence proves otherwise.

## Finish

After all tasks complete:

1. Merge task path lists into `<workspace>/final-paths.txt`, one path per line,
   without duplicates, and build the complete package from it
2. Write `<workspace>/final-report.md` with delivered behavior, verification
   evidence, and deviations
3. Execute the written final-verification checkpoint
4. Reuse task evidence only when each task package's state entries match the
   same paths in the complete package; combine matching task packages when their
   union covers the complete scope
5. Review uncovered behavior through `review-loop.md`
6. Run only final checks whose semantic scope remains uncovered
7. Append final rulings and tick final verification
8. Without a root coordinator: relay every `**Manual check (user):**` item to
   the user and wait for each result. A failed check: stop, keep the workspace,
   skip steps 9-11, and report. With a root coordinator: leave manual checks to
   it
9. Execute the final state checkpoint under `Checkpoint commits` when this
   executor owns Git
10. Let the milestone owner update the milestone
11. Let the PR owner create a requested PR only from committed reviewed work,
    after the user gate in `## Commit ownership`
12. Delete the plan workspace when no root coordinator exists; otherwise leave
    it to the root coordinator
13. Report changed files, evidence, rulings, dismissals, remaining risks, and
    excluded modified plan state. When a root coordinator dispatched this
    executor, return the finalizer's `## Output` contract from
    `../subagent-driven-development/finalizer-prompt.md`

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
