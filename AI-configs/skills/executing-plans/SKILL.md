---
name: executing-plans
description: >
  Use when you have a written implementation plan to execute in a separate
  session with review checkpoints
---

# Executing plans

**Announce at start:** "I'm using the executing-plans skill to implement this
plan."

Load and validate the plan. Execute inline, or delegate complete task cycles to
`subagent-driven-development`.

## Start gates

1. Read `plan_path`. Missing, empty, or unspecified: stop and request a valid
   path
2. Validate `Execution mode` is exactly `Inline` or `Subagent-Driven`. Missing,
   invalid, or conflicting with the current request: stop, ask the user, and
   update the plan before implementation
3. Review the plan critically. Resolve blocking gaps with the user
4. Validate the plan's commit policy and commit checkboxes. Missing or
   inconsistent: stop, ask the user, and update the plan before implementation.
   `Plan file policy` defaults to `Include` when absent; reject other values
5. Capture `plan_base_ref = git rev-parse HEAD` and inventory every pre-existing
   staged, unstaged, deleted, or untracked change in a temporary
   `baseline_snapshot`. Its manifest records each repo-relative path, content or
   deletion state, file mode, and ownership: `baseline-only`, `task:<id>`, or
   `execution-state`. Store present files byte-for-byte beside the manifest. Use
   an owner-only temporary directory and classify the plan file as
   `execution-state`; an empty worktree gets an empty manifest. Stop when
   ownership is unclear
6. When commits are planned, or `No commits` is combined with a requested PR,
   stop before Task 1 if:
   - one path mixes plan-owned and baseline-only hunks
   - the index contains baseline-only changes
   - under `Per-task commits`, a staged change belongs to a later checkpoint
7. Create the harness task/todo list

`Commit-bound` means commits are planned or `No commits` is combined with a
requested PR. Its scope guards apply even when the executor cannot commit.

The plan's `Execution mode` is authoritative. `Inline` uses the workflow below.
For `Subagent-Driven`, complete the start gates, then load
`subagent-driven-development`; do not run the inline workflow below. Direct
invocation never supplies a default.

Skills load only on the annotated step that needs them.

The plan owns task actions and plan-level checkpoints. This skill supplies
mechanics for written checkpoints; it never inserts a plan-level review, final
verification, or commit checkpoint. Stop and return an incomplete plan for
correction instead of synthesizing missing plan-level work.

Exactly one agent runs final verification:

- `Inline`: this executor
- `Subagent-Driven`: the finalizer

Never both. A relayed finalizer result is the evidence; do not re-run its
checks.

## Snapshot lifecycle

The `baseline_snapshot` holds pre-execution copies of work the user never
committed. Delete it after `PASS` or when execution is abandoned; retain it
while a blocker remains resumable.

Owner:

- `Inline`: this executor
- `Subagent-Driven`: the orchestrator

## Plan ownership

- Inline: this executor owns all checkboxes and `Solved defects`
- Subagent mode: each task implementer owns its task plus completed tasks
  changed by its reviewer fixes; the finalizer owns final checkpoints and
  completed-task state changed by final-review fixes
- Never use concurrent writers
- Tick a step after its `Green:` passes; un-tick before a reviewer fix
- Tick a commit checkpoint immediately before staging; restore `[ ]` whenever
  scope resolution, staging, or commit fails
- Track task status in the harness todo list

## Commit ownership

- The plan owns cadence; agents never infer or override it
- `No commits`: no agent commits
- `Per-task commits`: inline executor or task implementer commits the initial
  task, one follow-up commit per task-review fix round, one combined
  final-review-fix commit after final verification, then final plan state
- `One commit at the end`: inline executor or finalizer commits after final
  review and verification
- At every commit, load `git-commit-message` and derive message and paths from
  current state; never rely on the plan's initial file list
- Include the plan's current `execution-state` changes only when
  `Plan file policy` is `Include`
- Reviewers never commit

## Inline per-task workflow

For each task:

1. Set the review range:
   - `Per-task commits`: `review_base_ref = git rev-parse HEAD`, scope `task`
   - `One commit at the end` or `No commits`: `review_base_ref = plan_base_ref`,
     scope `cumulative`
   - In commit-bound execution, stop before editing any planned or newly
     discovered target or reviewer-fix path with baseline-only changes
2. Mark the task in progress
3. Complete each step and tick it when its narrow `Green:` passes
4. Confirm the plan's task-ending full gate passed
5. For `Per-task commits`, execute and tick the initial task checkpoint
6. Dispatch a fresh spec reviewer
7. Resolve every blocking finding; commit each verified fix round under
   `Per-task commits`
8. Dispatch a fresh code-quality reviewer
9. Resolve every blocking finding with the same fix-commit loop
10. Mark the task complete

Never dispatch onto a red gate or move on with unadjudicated findings. Re-run
the full gate after every task-review fix.

## Inline review handling

- Accept only `PASS` or terse Critical/Important findings
- Empty, errored, or rate-limited output is a failed dispatch
- Narration, summaries, or malformed findings are a failed dispatch
- A `<review-input>` finding is a failed dispatch; correct the payload
- Allow 3 total attempts for a failed dispatch, then escalate
- For bot/PR reviews, load `replying-to-pr-review-threads`
- Fix all sibling call sites sharing the defect, not only the cited line
- Add validated fixes to `Solved defects` as
  `severity | path or symbol | invariant`
- Never add rejected findings to that list

Adjudicate each finding:

1. Verify its `path:line` evidence
2. Fix substantiated findings
3. Reject incorrect findings with counter-evidence
4. Use one clarification round for genuine ambiguity
5. Escalate disputes that remain

Record rejected findings and counter-evidence in the final report. Every
returned finding blocks until fixed or rejected with counter-evidence. Always
re-dispatch the current review stage after a fix.

A code-quality fix that changes delivered behavior, scope, contracts, or
verification reopens spec review. Resolve spec, then resume code-quality review.
Limit each review/fix cycle to 3 finding rounds; a fourth requires user
escalation.

## Inline reviewer dispatch

**Preconditions before dispatching:**

- Task-scope dispatch: task full gate is green
- Cumulative task dispatch: current task full gate is green
- Complete-scope first dispatch: final task full gate is green
- Complete-scope re-dispatch after a final-review fix: affected narrow gates are
  green
- Complete-scope re-dispatch does not require another full gate
- `changed_files` is the deduplicated union of committed, staged, unstaged, and
  untracked implementation paths in scope. Exclude `execution-state` paths and
  paths whose current state still matches an excluded snapshot entry
- Rename entries use the destination path

Use absolute template paths. Pass pointers, never template contents or session
history. `changed_files` is a newline-delimited exact-path list, not a review
boundary. Pass `Solved defects` from the plan; use `none` when empty.

```text
MUST read instructions at <skill_dir>/spec-reviewer-prompt.md FIRST.
Do not act until you have read it. Then apply:
  plan_path      = <abs path>
  task_id        = <task number / heading>
  base_ref       = <review_base_ref>
  scope_mode     = <task | cumulative>
  baseline_snapshot = <abs path to classified snapshot directory>
  changed_files  = <newline-delimited exact paths>
  solved_defects = <current solved-defects list, or `none`>
```

```text
MUST read instructions at <skill_dir>/code-quality-reviewer-prompt.md
FIRST. Do not act until you have read it. Then apply:
  plan_or_requirements = <"Task <task_id> from <plan_path>" for task scope;
                          "Tasks completed through <task_id> from <plan_path>"
                          for cumulative scope>
  task_id             = <task number / heading>
  scope_mode          = <task | cumulative>
  base_ref             = <review_base_ref>
  baseline_snapshot    = <abs path to classified snapshot directory>
  changed_files        = <newline-delimited exact paths>
  solved_defects       = <current solved-defects list, or `none`>
  checklist_path       = <abs path to requesting-code-review/code-reviewer.md>
```

`<skill_dir>` is the resolved `subagent-driven-development` directory. Final
review uses `plan_base_ref`, `complete` scope, and all plan-changed
implementation files. If any base ref is unclear, ask.

## Inline finish

After all tasks complete and verified:

1. Execute each remaining plan-level checkpoint in written order
2. Do not synthesize a review, verification, or commit step missing from the
   plan
3. When the written final-verification checkpoint requests full-plan review:
   1. Use `plan_base_ref`, `complete` scope, and all plan-changed implementation
      files
   2. Dispatch the requested reviewer
   3. Recheck each fix path against `baseline_snapshot` before editing in
      commit-bound execution
   4. Uncheck the conditional final-review-fixes commit checkpoint before the
      first fix under `Per-task commits`
   5. Resolve findings with the adjudication and retry rules
   6. Run only affected narrow gates during the final-review fix loop
   7. Re-run affected spec review when delivered behavior changed
   8. Re-dispatch final code-quality review after each fix round
   9. Require `PASS`
4. When the written final-verification checkpoint reaches final validation:
   1. Load `verification-before-completion`
   2. Run each exact automated check once
   3. Perform each exact manual check once
   4. Tick the final-verification checkpoint
5. Do not run the full gate elsewhere in the final-review fix loop
6. Execute each remaining written commit checkpoint:
   - `One commit at the end`: commit the actual complete reviewed diff
   - `Per-task commits`: commit the combined final-review fix set when its
     conditional checkpoint is unchecked. Execute the final-state commit
     checkpoint only when `Plan file policy` is `Include`
   - `No commits`: no checkpoint
7. For `No commits` plus a requested PR:
   1. Record the exact plan-owned paths, content hashes, modes, and deletion
      states under `baseline_snapshot/pr-handoff.json`; include plan state only
      when `Plan file policy` is `Include`
   2. Hand off only that reviewed change set for an external commit
   3. Verify the resulting branch matches it and contains no baseline-only delta
   4. Stop on any mismatch
8. Report files, evidence, rejected findings, and remaining risks

When `Source requirements` request a PR, load `create-pull-request` after the
written final-verification and commit checkpoints pass.

## Stop conditions

- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- Verification repeatedly fails
- A required reviewer cannot be dispatched
- A review or dispatch exceeds its retry budget

Report the blocker. Return to the start gates after the plan changes materially.
