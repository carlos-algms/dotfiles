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
2. On `PASS`, mark only the harness task complete and dispatch the next task
3. On `BLOCKED`, relay its short blocker list; stop
4. After all tasks, dispatch one fresh finalizer with `finalizer-prompt.md`
5. Relay the finalizer's `PASS` or `BLOCKED` result, including its optional
   `HANDOFF` line
6. Own the snapshot lifecycle defined in `executing-plans`

Do not receive or adjudicate nested reviewer output. The implementer owns its
task until both reviewers pass and its commit policy is satisfied.

## Orchestrator ownership

- Keep only task status, `plan_base_ref`, and `baseline_snapshot`
- Never edit implementation files, plan checkboxes, or `Solved defects`
- Never run task gates, reviewers, fix loops, staging, or commits
- Never run final verification or the full gate. The finalizer owns it; relay
  its result verbatim
- Never create the PR; the finalizer owns requested PR creation
- Never paste nested review output into orchestrator context
- Dispatch tasks sequentially; implementers share one worktree

## Model selection

- 1-2 files, complete spec, mechanical implementation → cheap/fast model
- Multi-file integration, debugging → standard model
- Architecture, design, broad codebase reasoning → most capable model

Use capable reviewers. Escalate for cross-module, destructive, public-contract,
migration, or auth work.

## Handling implementer status

- `PASS`: accept the terse verification/commit/PR summary
- Implementer `BLOCKED`: surface its bullets unchanged
- Finalizer `BLOCKED`: surface its bullets and its optional `HANDOFF` line
  unchanged. Only the finalizer emits `HANDOFF`, for the external-commit path
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
```

`<skill_dir>` is this file's directory. Pass pointers and values only.

## Red flags

- Dispatch multiple implementation subagents in parallel (conflicts)
- Put requirements in dispatch `context`
- Ask the orchestrator to run or interpret a review
- Return reviewer transcripts on success
- Edit task checkboxes on the implementer's behalf

## Integration

- **./code-quality-reviewer-prompt.md** - Code review template (wraps
  `requesting-code-review`)
- **./finalizer-prompt.md** - Full-plan review, verification, and final commit
- **verification-before-completion** - Verifies before claiming completion
- **create-pull-request** - Required before the finalizer opens a requested PR
