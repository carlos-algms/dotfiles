---
name: subagent-driven-development
description: >
  Subagent-per-task MODE of executing-plans. Requires executing-plans, which
  holds the shared rules; load that first if it is not already loaded.
---

# Subagent-driven development

**Announce at start:** "I'm using subagent-driven development to execute this
plan."

**Requires `executing-plans`.** Load it first for plan validation, baseline
capture, and dirty-work ownership. This skill delegates each complete task cycle
to one implementer.

## Workflow

After the shared `executing-plans` start gates:

1. For each task, dispatch one fresh implementer with `implementer-prompt.md`
2. On `PASS`, mark only the harness task complete, retain its exact `REVIEW` and
   `VERIFY` lines grouped by task ID for final evidence reuse, carry its
   `LEARNED` lines into your final report, and dispatch the next task
3. On `BLOCKED`, relay its short blocker list and its `LEARNED` lines; stop
4. After all tasks, dispatch one fresh finalizer with `finalizer-prompt.md`
5. With `milestone_execution_mode = coordinated`, on `READY <plan ID>`, relay it
   to the root milestone execution coordinator and retain the finalizer plus
   `baseline_snapshot`
6. With `milestone_execution_mode = coordinated`, after the exact
   `FINALIZE <plan ID>` grant, re-dispatch the same finalizer with that grant
7. Relay the finalizer's `PASS` or `BLOCKED` result, including its optional
   `HANDOFF`, `STATE`, and `MILESTONE` lines. After a granted turn, a relayed
   `MILESTONE` returns `FINALIZED`; a relayed `BLOCKED` reports that the open
   turn failed and must not be reused
8. Own the snapshot lifecycle defined in `executing-plans`

Do not receive or adjudicate nested reviewer output. The implementer owns its
task until its reviewer passes and its commit policy is satisfied.

## Orchestrator ownership

- Keep only task status, exact implementer `REVIEW` and `VERIFY` lines grouped
  by task ID, `plan_base_ref`, `baseline_snapshot`, and the resolved
  `milestone_execution_mode`
- Never edit implementation files, plan checkboxes, `Solved defects`, or
  `Execution log`
- Never run task gates, reviewers, fix loops, staging, or commits
- Never run final verification or the full gate. The finalizer owns it; relay
  its result verbatim
- Never create the PR; the finalizer owns requested PR creation
- Never paste nested review output into orchestrator context
- Dispatch tasks sequentially; implementers share one worktree

## Handling implementer status

- `PASS`: accept the terse verification/commit/PR summary
- Preserve every valid `REVIEW` line with its task ID for the finalizer; never
  repeat review already covering the complete unchanged implementation
- Preserve every valid `VERIFY` line with its task ID for the finalizer; never
  summarize or discard reusable evidence
- `LEARNED` on either status: relay its lines unchanged in your report. The
  subagent already wrote them to the plan; never re-append them yourself
- No `LEARNED` block: say nothing about it. Never report "no learnings" or an
  empty section. Absence is the normal case
- Implementer `BLOCKED`: surface its bullets unchanged
- Finalizer `BLOCKED`: surface its bullets and its optional `HANDOFF` line
  unchanged. Only the finalizer emits `HANDOFF`, for the external-commit path
- Finalizer `STATE`: relay it unchanged. It lists modified plan-state files left
  uncommitted under `Plan file policy: Exclude`
- Finalizer `READY`: relay it unchanged and wait for the exact matching
  `FINALIZE` grant. It is a resumable pause, not `BLOCKED`
- Finalizer `MILESTONE`: relay it unchanged. It confirms the granted turn ended
  with `FINALIZED <plan ID>`
- Empty, malformed, or verbose output: re-dispatch once with the output contract
- A second invalid response: stop

## Dispatch payloads

Pass absolute template paths and values. Never paste template bodies or full
task text. Subagents read the task from `plan_path`.

**Implementer:**

```text
MUST read instructions at <skill_dir>/implementer-prompt.md FIRST. Do not
act until you have read it. Then apply:
  plan_path     = <abs path>
  task_id       = <task number / heading>
  working_dir   = <abs path>
  plan_base_ref = <SHA captured by executing-plans>
  baseline_snapshot = <abs path to classified snapshot directory>
  context       = <NON-NORMATIVE orientation only: where this task fits,
                   which prior tasks already landed. Nothing here may be a
                   requirement, constraint, or design decision>
```

Put every normative fact in the plan. `context` is orientation only.

**Finalizer:**

```text
MUST read instructions at <skill_dir>/finalizer-prompt.md FIRST. Do not
act until you have read it. Then apply:
  plan_path     = <abs path>
  working_dir   = <abs path>
  plan_base_ref = <SHA captured by executing-plans>
  baseline_snapshot = <abs path to classified snapshot directory>
  review_evidence = <successful task IDs with their exact REVIEW lines,
                     or `none`>
  verification_evidence = <successful task IDs with their exact VERIFY lines,
                           or `none`>
  milestone_execution_mode = <coordinated | sequential, resolved by
                              executing-plans; never self-resolve>
  milestone_finalize_grant = <exact FINALIZE line copied verbatim from the root
                              coordinator | none on first dispatch>
```

`<skill_dir>` is this file's directory. Pass pointers and values only.

## Red flags

- Dispatch multiple implementation subagents in parallel (conflicts)
- Put requirements in dispatch `context`
- Ask the orchestrator to run or interpret a review
- Return reviewer transcripts on success
- Edit task checkboxes on the implementer's behalf
- Drop a subagent's `LEARNED` lines from the report
- Treat a `LEARNED` block as narration and re-dispatch over it
- Treat a missing `LEARNED` block as malformed output
- Report an empty `Execution log` or an absent `LEARNED` block as a finding
- Drop a finalizer's `STATE` line from the report
- Treat `READY` as `BLOCKED` or delete its resumable finalizer
- Self-grant or alter a root coordinator's `FINALIZE` line
- Drop a finalizer's `MILESTONE` line from the report

## Integration

- **./reviewer-prompt.md** - Per-task craft + spec reviewer, dispatched by the
  implementer
- **./finalizer-prompt.md** - Full-plan review, verification, and final commit
- **verification-before-completion** - Verifies before claiming completion
- **create-pull-request** - Required before the finalizer opens a requested PR
