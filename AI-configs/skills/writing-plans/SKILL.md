---
name: writing-plans
description: >
  Create a written implementation plan saved to a file. Use only when the user
  directly invokes the writing-plans skill or explicitly asks for a written
  plan. Do not use for in-memory plans, in-chat plans, internal task
  decomposition, native task lists, or ordinary multi-step implementation.
---

# Writing plans

Write self-contained implementation plans for an agent with zero repo context.
Assume a skilled engineer who does not know the repo or domain. Name files,
behavior, constraints, and verification. Keep tasks bite-sized and apply DRY,
YAGNI, and TDD.

**Announce at start:** "I'm using the writing-plans skill to create the
implementation plan."

## Terms

- **Green:** a paste-able command emits an observable success token (exit 0,
  `PASS`, `0 errors`, artifact). Manual-only checks name an exact procedure and
  expected observation. Every task and checkpoint ends green
- **Task:** one checkbox-tracked, committable unit with a shared file set
- **Step:** one numbered action nested under its task. A later task-level check
  may verify it
- **Substep:** one numbered action nested under a step when that step needs an
  ordered breakdown
- **Bootstrap stubs:** minimal types/signatures that make tests _run_ (not pass)
  - Put empty bodies, `NotImplementedError`, or wrong defaults inside the
    implementation step
  - Use a separate step only when a later task imports the new symbol
- **Full gate:** the project's whole validation suite: format, lint, types, and
  full tests. Prefer its single CI command (`make validate`, `pnpm validate`);
  otherwise list the commands in execution order. Runs once per task and once
  after any task-reviewer fix
- **Narrow gate:** the single test file or single check a step actually affects
- **Dominated check:** an earlier check fully covered by a later check when
  nothing consumes the earlier result before the later check
- **Footprint:** the files, frameworks, runtimes, imports, and tooling a step
  touches - scanned to match skills

## Task formatting

- Write each task as one top-level checkbox item: `- [ ] **Task N: ...**`
- Give each task title one umbrella outcome
- Never join separate task outcomes with `and`
- Split tasks when no single outcome covers their steps and their file sets do
  not overlap
- State one observable behavior in `Goal`
- Nest every step under its task as a numbered list
- Nest ordered substeps under the step they implement
- Put one action or idea in each list item. Never join actions in a prose line
  or paragraph
- Indent all task content under the task checkbox. Indent all step content under
  its numbered item
- Use a paragraph only for non-action context that materially helps execution,
  such as an edge case, constraint rationale, caveat, or justification
- Keep each paragraph to one idea. Place it directly under the task, step, or
  substep it qualifies; do not use it to hide a sequence of actions
- Prefer a labeled paragraph such as `**Edge case:**`, `**Constraint:**`, or
  `**Why:**` when the relationship is not obvious
- Apply this structure to every plan section, including tasks, checkpoints,
  header fields, and handoff text

## Worked example (the shape every task follows)

Python here; use the same shape in any language.

```markdown
- [ ] **Task N: [Observable outcome]**

  **Goal:** [One new observable behavior]

  **Files:**

  - `exact/path/to/file.py`
    - Responsibility: validate input
    - Output: `Result`
    - Reuse: `LibraryThing` from `exact/path/to/lib.py`
  - `exact/path/to/file.test.py`
    - Base-case coverage for `function()`
    - Edge-case coverage for `function()`
  1. **Implement `function()` with TDD**

     **Skills (load if not already loaded):** `<test-runner-skill>`,
     `<language-skill>`

     1. Stub the final `Result` signature
     2. Stub the final `function()` signature with a wrong body
     3. Write tests for the base cases
     4. Run the narrow gate
        - Require assertion failures
        - Require no import errors
        - Require no runtime errors
     5. Implement the constraints

     **Signature:** `def function(input: str) -> Result`

     **Constraints:**

     - Accept X
     - Validate Y
     - Return Z
     - Use `LibraryThing` for heavy lifting
     - Return `Result.empty()` for empty input

     **Base cases:**

     - `function("valid")` -> `Result(value="valid")`
     - `function("")` -> `Result.empty()`
     - `function(None)` raises `ValueError`

     **Edge case:** Unicode normalization can change equality without changing
     the visible value.

  2. **Run the full gate**

     Green (task gate): every header `Full gate` command exits 0.
```

## Plan location

- Plan ALWAYS lives in a file. Subagents have no session memory; the file is the
  only source of truth
- Already in a plan file: preserve content outside the requested changes
- Not saved: default `docs/plans/YYYY-MM-DD-<feature-name>.md`. User may pick
  another path
- User refuses to save to any file: STOP
- Saving does not commit the plan. Record whether execution commits the plan
  file; default to included unless the user explicitly excludes it

## Review source

- Capture `review_source_requirements` before drafting the plan
- Preserve the user's original asks
- Preserve the user's acceptance criteria
- Preserve every explicit must statement
- Preserve every explicit never statement
- Preserve each user-provided source-spec path
- Keep this capture independent from the drafted plan
- Do not reconstruct it from the finished plan
- After context compaction, stop and request the source again when the capture
  is unavailable
- Derive the header's `Source requirements` from this capture

## Commit policy

Before writing, resolve the commit policy from the request or ask the user to
choose: `Per-task commits`, `One commit at the end`, or `No commits`. Record
`Plan file policy: Include | Exclude`; default to `Include` unless requested.

Record the choice in the header and encode it with commit checkboxes:

- `Per-task commits`: append one unchecked checkpoint to every task, the
  pre-checked conditional final-review-fixes commit checkpoint after final
  verification, then a final-state commit checkpoint when the plan file is
  included
- `One commit at the end`: append one commit checkpoint after final verification
- `No commits`: write no commit checkpoints

Every plan ends with one self-contained final-verification checkpoint after all
tasks.

- Copy every exact full-gate command into the checkpoint
- Put the full-plan final review inside the checkpoint
- Require final-review `PASS` before final validation
- Run only affected narrow gates while resolving final-review findings
- Reuse a valid task full-gate result when it covers the unchanged final diff
- Run the copied full-gate command when final review changed relevant state
- Run the copied full-gate command when valid prior evidence is unavailable
- Add an exact build command only when the full gate does not build
- Add an exact documentation command only when the full gate does not generate
  required documentation
- Add each required manual check as an exact procedure
- Give each manual check one expected observation
- Remove every unused command or check placeholder
- Never point final validation commands or manual checks to another plan section

```markdown
- [ ] **Final verification checkpoint**

  **Skills (load if not already loaded):** `requesting-code-review`,
  `verification-before-completion`

  1. **Review the complete plan diff**

     1. Dispatch a fresh code-quality reviewer over the complete plan diff
     2. Resolve each substantiated finding
        1. Verify its cited evidence
        2. Uncheck the conditional final-review-fixes commit checkpoint before
           the first fix under `Per-task commits`
        3. Apply the narrowest valid fix
        4. Update `Solved defects`
        5. Run the affected narrow gates
        6. Re-run affected spec review when delivered behavior changed
     3. Re-dispatch code-quality review after each fix round
     4. Require `PASS`

  2. **Establish final automated evidence once**

     **Reuse:** Accept an existing result only when it covers the exact current
     diff.

     1. `[exact full-gate command]`
        - Run only when no reusable full-gate result exists
        - Expected: exit 0
     2. `[exact build command not covered by the full gate]`
        - Expected: exit 0
     3. `[exact documentation command not covered by the full gate]`
        - Expected: exit 0

  3. **Perform the final manual checks**

     1. `[exact manual procedure]`
        - Expected: `[observable result]`

  Green:

  - Final code-quality review returned `PASS`
  - Every listed command has a valid result for the exact final diff
  - Every listed manual procedure produced its expected observation
```

Commit checkpoints contain no command, message, or fixed file list. The owner
derives all three from the actual diff at checkpoint time.

```markdown
- [ ] **Initial commit checkpoint: Task N**

  **Skills (load if not already loaded):** `git-commit-message`

  1. Resolve the checkpoint's verified change set from the current diff
  2. Include current plan-state changes when `Plan file policy` is `Include`
  3. Derive the paths from the resolved change set
  4. Derive the message from the resolved change set
  5. Commit the resolved change set

  Green:

  - New commit contains the checkpoint's complete verified diff
  - No intended checkpoint changes remain uncommitted
```

For `One commit at the end`, place this immediately after the final-verification
checkpoint:

```markdown
- [ ] **Final commit checkpoint: whole plan**

  **Skills (load if not already loaded):** `git-commit-message`

  1. Resolve the complete reviewed change set from the current diff
  2. Include current plan-state changes when `Plan file policy` is `Include`
  3. Derive the paths from the resolved change set
  4. Derive the message from the resolved change set
  5. Commit the resolved change set

  Green:

  - New commit contains the complete reviewed plan diff
  - No intended plan changes remain uncommitted
```

For `Per-task commits`, place this immediately after the final-verification
checkpoint:

```markdown
- [x] **Conditional commit checkpoint: final-review fixes**

  **Default:** No final-review changes.

  **When the final-verification checkpoint changed files:**

  **Skills (load if not already loaded):** `git-commit-message`

  1. Resolve the verified final-review fix set from the current diff
  2. Include current plan-state changes when `Plan file policy` is `Include`
  3. Derive the paths from the resolved change set
  4. Derive the message from the resolved change set
  5. Tick this checkpoint
  6. Commit the resolved change set

  Green:

  - No-change path
    - No final-review changes exist
  - Fix path
    - One commit contains all verified final-review fixes
    - No intended checkpoint changes remain uncommitted
```

Under `Per-task commits`, when `Plan file policy` is `Include`, place this after
the conditional final-review-fixes commit checkpoint:

```markdown
- [ ] **Final state commit checkpoint**

  **Skills (load if not already loaded):** `git-commit-message`

  1. Resolve the final verified plan-state change set from the current diff
  2. Derive the paths from the resolved change set
  3. Derive the message from the resolved change set
  4. Commit the resolved change set

  Green:

  - Final plan state is committed
  - No intended checkpoint changes remain uncommitted
```

Under `Per-task commits`, the task owner commits after its full gate, then
summons reviewers. Each task-review fix round gets one follow-up commit. Keep
final-review fixes uncommitted through re-review. Commit them once after final
verification passes. Tick immediately before staging; restore `[ ]` whenever
scope resolution, staging, or commit fails.

If `No commits` and a PR are both requested, record an external-commit handoff:
the executor stops before PR creation, supplies the exact reviewed plan-owned
change set, and verifies the resulting branch contains no baseline-only work.

## Execution mode

Before writing, resolve the execution mode from the request or ask the user to
choose: `Subagent-Driven` or `Inline`. Do not infer a default. Record the exact
choice in the plan header. Missing or unresolved choice: stop before writing.

## Scope check

- Spec covers multiple independent subsystems: suggest splitting into separate
  plans, one per subsystem
- Each plan must produce working, testable software on its own

## Verification deduplication

- List verification and formatting commands in execution order before writing
  them into tasks
- Remove an earlier command when a later command covers the same scope plus more
- Remove an earlier command when nothing consumes its result before the broader
  command
- Treat a result as consumed only when a later action depends on its output,
  pass state, fail state, or produced artifact
- Compare semantic scope instead of command text
- Treat focused tests followed immediately by a containing test suite as one
  check
  - Keep the containing suite
  - Remove the focused green run
- Treat one-file formatting followed by containing multi-file formatting as one
  formatting action
  - Keep the containing formatting action
  - Remove the one-file action
- Keep a focused TDD red run when implementation depends on its expected failure
- Keep both commands when the broader command does not execute the narrow check
- Keep both commands when an intervening action consumes the narrow result
- Reuse a valid full-gate result when it covers the exact current diff
- Re-run the full gate only after relevant state changed or prior evidence is
  unavailable

## Decomposition

- Map files to create/modify + their responsibilities before defining tasks
- One responsibility per file. Group files that change together
- Follow existing patterns. Don't restructure unilaterally. Split an unwieldy
  file only when modifying it
- Search the codebase for existing components/helpers/hooks/utilities first.
  Reuse mandatory. Extend before creating
- Prefer surgical edits. Don't bundle unrelated changes because they touch
  nearby code
- Every task ends with the narrowest non-dominated `Green:` proof
- Add an intermediate `Green:` only when a later action consumes its result
- Prefer a paste-able command and observable token
- Use an exact procedure only for manual-only checks
- Keep TDD red inside its implementation step. Require assertion failure; fix
  import/runtime setup before proceeding
- Run the full gate only as each task's last verification
- Merge tasks whose file sets overlap
- One task per file set, not one task per concern
- Past ~8 tasks: merge or split into separate plans
- Rationale capped at 2 lines per constraint. Cite `path:line` instead of
  restating the argument
- State repo rules once in the shared preamble
- Collapse families of near-identical base cases (same assertion, different
  input) unless they cover distinct code paths

## Tracking

Executing from a plan file: flip a task's `- [ ]` to `- [x]` after all nested
steps pass, including its full gate. Flip the task back before a reviewer fix.
Inline execution owns all boxes; in subagent mode, the current task implementer
owns its task and completed tasks changed by its reviewer fixes; the finalizer
owns final boxes and completed tasks changed by final-review fixes. Tasks
execute sequentially, so the plan has one writer at a time.

Also track progress in the harness native task/todo list.

## Required skills (per step)

- Skills load at the step that needs them, not upfront
- Scan each step's footprint against skills listed in the current environment.
  Use exact names. Do not invent or rename
- Signals: file extensions touched; frameworks/runtimes named; test
  runners/config; specific imports; build/package managers; domain tooling (Git,
  Obsidian, Slack, Jira, CI, Neovim, browsers)
- Add `**Skills (load if not already loaded):**` line only on steps with a
  match. No match -> no line
- Final-verification checkpoint always:
  `**Skills (load if not already loaded):** requesting-code-review, verification-before-completion`
- Load `verification-before-completion` only after final review returns `PASS`
- Any step that reads or replies to a bot review always:
  `**Skills (load if not already loaded):** replying-to-pr-review-threads`

## Review-related steps

Execution skills own implementation-review mechanics and PR creation. The plan
owns the final-review step inside its final-verification checkpoint. In subagent
mode, the finalizer executes that written checkpoint. Preserve a PR request in
`Source requirements`; the final execution owner loads `create-pull-request`
after final verification.

If the requested work itself reads external review output:

- Never narrow the applicable reviewer template or replace defect review with
  plan conformance
- Read the full output, reconcile stated and observed finding counts, and do not
  treat a green status as proof that review occurred
- Annotate bot-review steps with `replying-to-pr-review-threads`; leave its
  mechanics to that skill

Fresh reviewers receive the header's **Solved defects** list. Execution owners
record each fixed finding once as `severity | path or symbol | invariant`.

## Plan document header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For the executing agent:**
>
> 1. Execute tasks in plan order
> 2. Load `executing-plans` when working from a saved plan
> 3. Tick a task after all its nested steps pass
> 4. Un-tick a task when a reviewer sends it back
> 5. Track progress in the harness task list
>
> **Plan ownership:**
>
> - One writer at a time
> - Inline execution: executing agent owns all plan state
> - Subagent execution: current task implementer owns its task state
> - Subagent execution: current task implementer owns completed-task state
>   changed by its reviewer fixes
> - Finalizer: owns final state
> - Finalizer: owns completed-task state changed by final review

**Goal:** [One new observable behavior]

**Source requirements:**

1. `R1`: [Original user requirement]
2. `R2`: [Acceptance criterion]
3. `R3`: [Explicit must statement]
4. `R4`: [Explicit never statement]

**Architecture:**

- [Primary approach]
- [Key boundary]
- [Required ownership rule]

**Tech Stack:**

- [Technology]
- [Library]

**Execution mode:** [Subagent-Driven | Inline]

**Commit policy:** [Per-task commits | One commit at the end | No commits]

**Plan file policy:** [Include | Exclude]

**Full gate:**

1. `[primary full-validation command]`
2. `[next required full-suite command]`
   - Omit when the primary command covers it

**Convention sources:**

- `[closest nested AGENTS.md]`
- `[closest nested CLAUDE.md]`
- `[.editorconfig]`
- `[relevant lint config]`
- `[relevant format config]`
- `[relevant type config]`

**Solved defects:**

- none

---
```

- `Source requirements` is required
  - Record each original user ask
  - Record each acceptance criterion
  - Record each explicit must statement
  - Record each explicit never statement
- `Convention sources` is required
  - List the closest governing agent instruction file
  - List `.editorconfig` when discovered
  - List each relevant lint config
  - List each relevant format config
  - List each relevant type config
- `Solved defects` is required
  - Keep `none` until a reviewer finding is fixed
  - Replace `none` with unique regression-relevant entries
  - Format each entry as `severity | path or symbol | invariant`

Skills are annotated per step, not in the header.

- State the full-gate commands once in the header
- Let task steps reference the header's `Full gate`
- Copy the exact full-gate commands into the self-contained final-verification
  checkpoint

## Detail calibration

Every step states what to build, constraints, and tests without dictating
derivable implementation.

Never write:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling", "handle edge cases", "style nicely"
- "Write tests for the above" (without listing what to test)
- "Similar to Task N" (steps may be read out of order)
- Vague instructions such as "build the component"
- References to types/functions/methods not defined in any task

Use verbatim content only for tricky config, signatures, and shell commands.
Describe test cases as inputs, outputs, and key assertions. Describe
implementation and layout as intent plus constraints.

## Cross-cutting constraints

- Commit and test-file conventions come from the target repo. Do not invent
  either
- Design decisions affecting test assertions (ARIA roles, landmarks, semantic
  HTML) locked in the plan. Styling can stay open
- Same constraint-detail level across steps of the same type

## Self-review (run yourself, not a subagent)

After writing, re-check and fix inline:

1. **Coverage:**
   1. Every captured source requirement appears in the header
   2. Every header source requirement maps to a task
   3. Every task maps to verification
2. **Ambiguity:** remove every "Detail calibration" red flag
3. **Type consistency:** signatures/names match across tasks (`clearLayers()` in
   Task 3 vs `clearFullLayers()` in Task 7 is a bug)
4. **Implementation leak:** replace derivable bodies/tests with signatures,
   constraints, and cases
5. **Reuse:** anything created that already exists -> import or extend instead
6. **Safety:** destructive operations match source requirements and target-repo
   rules; every named error mapping has a step that handles it
7. **Verification:**
   1. Remove repeated `Green:` checks
   2. Remove standalone red phases
   3. Keep the full gate only as each task's last verification
   4. Require one plan-level final-verification checkpoint after all tasks
   5. Put full-plan final review inside the final-verification checkpoint
   6. Require final-review `PASS` before final validation
   7. Run final validation once after the final-review fix loop
   8. Require exact commands in the final-verification checkpoint
   9. Require exact manual procedures in the final-verification checkpoint
   10. Reject a separate plan-level final-review task
   11. Reject final validation commands that reference another plan section
8. **Task overlap:** list each task's file set. Overlapping sets -> merge the
   tasks
9. **Repetition:** move repeated repo rules and conventions to the preamble
10. **Commit cadence:** checkpoint count and placement match the header policy;
    the conditional final-review-fixes commit follows final verification;
    plan-state inclusion matches `Plan file policy`; no checkpoint freezes
    commands, messages, or paths
11. **Review duplication:** remove implementation-review steps owned by
    `executing-plans`. For requested external-review work, reject narrowed,
    conformance-only, truncated, or status-only review
12. **Readability:**
    1. Every task is a checkbox
    2. Every step is a nested numbered item
    3. Every action has its own list item
    4. Every idea has its own list item or justified paragraph
    5. Every paragraph is correctly indented
    6. Every paragraph adds necessary non-action context
13. **Duplicate work:**
    1. Build the ordered command sequence for every task
    2. Compare test scopes
    3. Compare formatting scopes
    4. Compare lint scopes
    5. Compare type-check scopes
    6. Compare build scopes
    7. Remove each dominated command
    8. Keep an earlier command only when a later action consumes its result

## Plan reviewer

After self-review, dispatch one subagent using `plan-reviewer-prompt.md`.

Dispatch payload. Do NOT read or open `plan-reviewer-prompt.md` yourself, the
subagent reads it; reading it into your own context defeats the offload:

```text
1. Read <skill_dir>/plan-reviewer-prompt.md first
2. Do not continue until the read completes
3. Apply these values
   - skill_path = <abs path to this SKILL.md>
   - plan_path = <abs path>
   - repo_root = <abs path>
   - source_requirements = <review_source_requirements captured before drafting>
```

- `<skill_dir>` is this file's directory
- Substitute absolute paths
- Pass `review_source_requirements` directly
- Do not derive reviewer input from the finished plan
- Pass the pointer and values
- Do not pass the template body

The reviewer audits the concrete plan for dominated work:

- Compare commands by semantic scope
- Check execution order
- Check whether an intervening action consumes the earlier result
- Report an earlier dominated command as at least Important
- Do not limit this audit to identical command text

Flow:

1. Reviewer returns `PASS` or terse Critical/Important findings
2. Fix blocking issues inline
3. Re-review only if fixes could introduce new defects: changed architecture,
   direction, tasks, boundaries, ordering, file ownership, verification, or test
   expectations. Skip for surgical/wording/style fixes
4. Cap at 3 dispatches. Blocking issues remain after the 3rd -> escalate

**Model:** use a capable reviewer for multi-task, cross-module, destructive,
public-contract, migration, or auth plans. A cheaper model is acceptable only
for a short, single-module plan; escalate a thin review.

## Execution mode prompt

Before writing, ask when the request does not already select a mode:

**"Before I write the plan, pick how it will execute.**

**Execution options:**

**1. Subagent-Driven**

- Each task implementer owns nested reviews
- Each task implementer owns its reviewer fixes
- Each task implementer owns its task commits
- Orchestrator receives terse outcomes

**2. Inline Execution**

- Execute in this session
- Use `executing-plans`
- Run two-stage review per task

**Which approach?"**

Write the selected mode into the plan header, then save the plan. Report the
plan path and recorded mode. Do not ask again during handoff.

- `Subagent-Driven` -> **REQUIRED SUB-SKILL:** `subagent-driven-development`
- `Inline` -> **REQUIRED SUB-SKILL:** `executing-plans`
