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
- **Task gate:** the smallest non-dominated set of checks that proves one task's
  changed files and behavior are commit-safe
- **Full gate:** the project's whole validation suite. Run it no more than once
  per relevant implementation state and only when the diff or repo policy
  requires it. A one-task or last-task gate may own it when that result covers
  the complete implementation; final verification reuses it while that state
  remains unchanged
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

  2. **Run the task gate once**

     1. `[one formatter command listing every applicable task file]`
        - Omit when no changed file is covered by that tool
        - Expected: exit 0
     2. `[one linter command listing every applicable task file]`
        - Omit when no changed file is covered by that tool
        - Expected: exit 0
     3. `[affected test command]`
        - Omit when an unchanged valid result already covers the final task diff
        - Expected: exit 0

     Green: every applicable non-dominated check exits 0.
```

## Plan location

- Plan ALWAYS lives in a file. Subagents have no session memory; the file is the
  only source of truth
- Already in a plan file: preserve content outside the requested changes
- Not saved: default `docs/plans/YYYY-MM-DD-<feature-name>.md`. User may pick
  another path
- A caller-supplied plan path is authoritative and overrides the default
- User refuses to save to any file: STOP
- Saving does not commit the plan. Record whether execution commits the plan
  file; default to included unless the user explicitly excludes it
- `Additional plan state files` are optional tracker documents that execution
  updates with the plan, such as a milestone index
- Every additional state path must exist before execution starts
- When concurrent plans share an additional state file, name its exclusive owner
  or exact turn protocol in `Source requirements` and the written update
  checkpoint. Without that ownership gate, require sequential execution
- `Plan file policy` applies to the plan file and every additional plan state
  file as one policy

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

Before writing, resolve the commit policy from the request. When the request
does not specify one, use `Per-task commits`. Record
`Plan file policy: Include | Exclude`; default to `Include` unless requested.
Apply it to the plan file and all `Additional plan state files`. Record exact
repo-relative additional paths, or `none` when no other state file exists.
`Plan state` means the plan file plus every listed additional state file.

Record the choice in the header and encode it with commit checkboxes:

- `Per-task commits`: append one unchecked checkpoint to every task, the
  unchecked conditional final-review-fixes commit checkpoint after final
  verification, then a final-state commit checkpoint when the plan file is
  included
- `One commit at the end`: append one commit checkpoint after final verification
- `No commits`: write no commit checkpoints

Every plan ends with one self-contained final-verification checkpoint after all
tasks.

- Build a review-evidence map from completed task reviews before dispatching a
  final reviewer
- Reuse a task review when it covers the complete current implementation. This
  is normally true for a one-task plan and for the last cumulative task review
  when no implementation content or semantic input changed afterward
- Dispatch a final reviewer only for review scope not already covered
- Build an evidence map from completed task gates and reviewer-fix gates before
  adding final commands
- Add a final command only for applicable scope not already covered by valid
  evidence
- A commit, read-only review, checkbox update, or other bookkeeping does not
  invalidate evidence unless it changes implementation content or the check's
  semantic inputs
- For a one-task plan, list no final automated or manual checks when the task
  gate covers the complete implementation and the review-fix loop reruns every
  check invalidated by a fix
- Apply the same rule when the last task gate already covers the complete
  implementation: do not repeat it at final verification
- Do not copy task-gate commands into final verification as fallback commands
- Batch all files accepted by the same formatter, linter, or checker into one
  invocation
- Put final review coverage inside the checkpoint
- Require no unresolved final-review findings before final validation
- Run only checks invalidated by final-review fixes; prefer narrow checks and
  rerun a full gate only when narrower evidence cannot restore required coverage
- Reuse a valid task-gate or reviewer-fix result when it covers the current
  implementation state and semantic scope
- Run the project's full gate only when source, tests, build inputs, tool
  config, generated artifacts, repo policy, or uncovered cross-task integration
  makes it relevant
- When one full-gate command covers selected checks, omit every contained
  formatter, linter, type-check, build, and test command
- Do not run unit tests, type checks, or builds for documentation-only changes
  unless the repo explicitly makes those checks applicable
- Add an exact build command only when relevant and not already covered
- Add an exact documentation command only when relevant and not already covered
- Add each required manual check as an exact procedure
- Give each manual check one expected observation
- Remove every unused command or check placeholder
- Never point final validation commands or manual checks to another plan section

```markdown
- [ ] **Final verification checkpoint**

  1. **Close final review coverage**

     **Skills (load if not already loaded):** `requesting-code-review`

     Omit the skills line and dispatch step when reusable task-review evidence
     already covers the complete current implementation.

     1. Reuse a task-review result when it covers the complete current
        implementation
     2. Dispatch a fresh code-quality reviewer only when complete review
        coverage remains missing
     3. Resolve each substantiated finding
        1. Verify its cited evidence
        2. Apply the narrowest valid fix
        3. Update `Solved defects`
        4. Run only checks invalidated by the fix
           - Prefer affected narrow gates
           - Rerun a full gate only when narrower evidence cannot restore its
             required coverage
     4. Re-dispatch after a behavioral fix round
     5. Do not re-dispatch after an all-static fix round when its affected gates
        pass
     6. Require reusable review coverage, `PASS`, or fully discharged findings

  2. **Close uncovered automated evidence**

     1. Reuse every task-gate and reviewer-fix result that covers the current
        implementation state and semantic scope
     2. Run `[exact command for uncovered applicable scope]`
        - Omit this step when reusable evidence covers all applicable scope
        - Expected: exit 0

  3. **Close uncovered manual evidence**

     1. Reuse every valid task or reviewer-fix observation that covers the
        current implementation state
     2. Perform `[exact manual procedure for uncovered applicable behavior]`
        - Omit this step when reusable observations cover all applicable
          behavior
        - Expected: `[observable result]`

  Green:

  - Final code-quality review has no unresolved findings
  - Reused and newly collected evidence covers every applicable check for the
    current implementation state
```

Commit checkpoints contain no command, message, or fixed file list. The owner
derives all three from the actual diff at checkpoint time.

```markdown
- [ ] **Commit task N**

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
- [ ] **Conditional commit checkpoint: final-review fixes**

  **Default:** No final-review changes.

  **Skills (load if not already loaded):** `git-commit-message`

  1. Determine whether the final-verification checkpoint changed files
  2. When no final-review fixes exist, tick this checkpoint without committing
  3. When final-review fixes exist, resolve their verified change set from the
     current diff
  4. Include current plan-state changes when `Plan file policy` is `Include`
  5. Derive the paths from the resolved change set
  6. Derive the message from the resolved change set
  7. When `Plan file policy` is `Include`, tick this checkpoint before staging
  8. Commit the resolved change set
  9. When `Plan file policy` is `Exclude`, tick this checkpoint after the commit

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

Under `Per-task commits`, the task owner commits after its task gate, then
summons reviewers. Each task-review fix round gets one follow-up commit. Keep
final-review fixes uncommitted through re-review. Commit them once after final
verification passes. On the no-change path, tick after confirming no
final-review fixes exist. On the fix path with `Plan file policy: Include`, tick
immediately before staging and restore `[ ]` whenever scope resolution, staging,
or commit fails. With `Plan file policy: Exclude`, tick only after the commit
succeeds.

If `No commits` and a PR are both requested, record an external-commit handoff:
the executor stops before PR creation, supplies the exact reviewed plan-owned
change set, and verifies the resulting branch contains no baseline-only work.

## Execution mode

Before writing, resolve the execution mode from the request. When the request
does not specify one, use `Subagent-Driven`. Record the exact choice in the plan
header.

## Scope check

- Spec covers multiple independent subsystems: suggest splitting into separate
  plans, one per subsystem
- Each plan must produce working, testable software on its own

## Verification deduplication

- Classify each changed file before selecting commands: documentation, source,
  test, build/tool config, generated artifact, or other
- Map each command to the changed paths or behavior that justify it
- Omit a command when no changed path or repo rule makes it applicable
- Documentation-only changes do not justify unit tests, type checks, or builds
  by default
- A test-only change justifies the affected tests, not an unrelated full suite
- Build or tool-config changes justify only the checks whose behavior they can
  alter
- A comment-only source change does not justify tests, type checks, builds, or a
  full gate when comments have no executable role
- Treat directives, suppressions, pragmas, doctests, generated-documentation
  inputs, shebangs, encoding declarations, and format-sensitive metadata as
  executable rather than comment-only
- Never write a test, type check, build, or full gate as the check that follows
  a formatter step. A formatter run is not an invalidating edit: it reports its
  own success, and a reflow does not change behaviour. A formatter step's own
  `Green:` (exit 0, or `--check` clean) is the whole check it needs
- A formatter step touching only `.md`, `.mdx`, or docs paths gets no code check
  of any kind
- The one exception: when the step changes formatter configuration
  (`pyproject.toml`, `.oxfmtrc`, `.prettierrc`), treat it as a real edit and
  give it a real check
- Formatting or lint checks may still be applicable to comment-only and
  formatter-only changes
- List verification and formatting commands in execution order before writing
  them into tasks
- Batch all applicable files into one formatter/linter invocation when the tool
  accepts multiple paths; never emit one invocation per file
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
- Treat a post-write existence/read-back check as dominated when the write
  command already reports failure and a later formatter, parser, test, diff, or
  review consumes the file
- Treat a final command or manual check as dominated when a task gate or
  reviewer-fix gate covers the same current implementation state and semantic
  scope
- In a one-task plan, presume the task gate remains valid through commit and
  read-only review unless implementation content or semantic inputs change
- Do not preserve duplicate final commands as hypothetical fallback paths;
  reviewer fixes run invalidated checks inside their fix loop
- Keep a focused TDD red run when implementation depends on its expected failure
- Keep a focused green run mid-implementation only when the next action depends
  on it; do not repeat it as a pre-commit validation immediately before a
  containing suite
- Keep both commands when the broader command does not execute the narrow check
- Keep both commands when an intervening action consumes the narrow result
- Reuse valid evidence when it covers the exact current content and semantic
  scope
- Run a relevant full gate no more than once per implementation state; never
  rerun it after read-only review or bookkeeping, and rerun it after a fix only
  when narrower evidence cannot restore the required coverage

## Decomposition

- Map files to create/modify + their responsibilities before defining tasks
- One responsibility per file. Group files that change together
- Follow existing patterns. Don't restructure unilaterally. Split an unwieldy
  file only when modifying it
- Search the codebase for existing components/helpers/hooks/utilities first.
  Reuse mandatory. Extend before creating
- Apply YAGNI. Prefer the fewest files and the smallest root-cause diff that
  satisfies the source requirements
- Prefer existing code, then standard-library or native platform features, then
  installed dependencies. Add an abstraction, dependency, configuration point,
  fallback, or extension hook only when a current requirement needs it
- Do not prescribe unsolicited comments or documentation. Add a comment only
  when required by the request or repo rules, or when a non-obvious invariant
  cannot be expressed clearly in code
- Cover behavior realistically reachable through the supported UI, API, job, or
  ordinary system operation
- Do not invent paranoid cases based on impossible states, deliberate internal
  tampering, unsupported misuse, or hypothetical hacking mechanisms
- Include adversarial security cases only when explicitly required, when
  untrusted input crosses a real trust boundary, or when evidence shows a
  recognized industry exploit with credible impact in this application
- Never simplify away validation at a real trust boundary, data-loss prevention,
  or an explicitly requested security measure
- Don't bundle unrelated changes because they touch nearby code
- Every task ends with the narrowest non-dominated `Green:` proof selected from
  its actual change impact
- Add an intermediate `Green:` only when a later action consumes its result
- Prefer a paste-able command and observable token
- Use an exact procedure only for manual-only checks
- Keep TDD red inside its implementation step. Require assertion failure; fix
  import/runtime setup before proceeding
- Run the task gate only as each task's last verification
- Never write an aggregate command (`make test`, `pnpm run test`, a pathless
  `pytest`) as a step's `Green:`. A step's `Green:` is the narrowest command
  that proves that step — one test file, one `-k` selector, one type check.
  Aggregates belong to the task gate, which runs once at the end
- Merge tasks whose file sets overlap
- One task per file set, not one task per concern
- A task delivers one slice of working behavior plus its tests. Everything that
  behavior needs to run — schema, storage, migration, table, helper, type —
  belongs in the task that uses it, not a preceding one
- Never write a task whose only deliverable is a type, a schema, a constant, or
  a stub that a later task consumes. Merge it into its consumer. Bookkeeping
  tasks (commit the plan, tick the boxes) are exempt: they deliver no behavior
  by design
- Every task dispatches a fresh implementer that reads this plan cold, so a task
  that ships nothing still costs a full plan read
- Past ~8 tasks: merge or split into separate plans
- Rationale capped at 2 lines per constraint. Cite `path:line` instead of
  restating the argument
- State repo rules once in the shared preamble
- Collapse families of near-identical base cases (same assertion, different
  input) unless they cover distinct code paths

## Execution log

The plan goes stale during execution. `Execution log` is the record that keeps a
fresh agent correct when the task text no longer matches the repo.

Log an entry when execution contradicts or outgrows the plan:

- `drift`: a plan fact turned out wrong (signature, path, return type, command,
  dependency, existing helper)
- `gotcha`: a non-obvious fact that cost time and would cost it again (required
  build order, flaky fixture, env var, tool quirk, hidden coupling)
- `decision`: a choice the plan left open, resolved during execution

Silence is the default. Most tasks log nothing. A task that went as planned
writes nothing at all: no entry, no placeholder, no `none`, no "no drift found".
An empty section already says it.

Do not log restated plan text, per-step narration, reviewer findings already in
`Solved defects`, or work that matched the plan.

Keep each entry to one line. Write what a fresh agent needs, not what happened.

- Wrong: `T2 | drift | had trouble with the parser and fixed it`
- Right:
  `T2 | drift | plan assumed parse() -> str | repo returns Result; 3 callers updated`

Correct the stale task text in place when the drift invalidates a later task's
instructions. The log records the change; the task text stays executable.

## Tracking

Executing from a plan file: flip a task's `- [ ]` to `- [x]` after all nested
steps pass, including its task gate. Flip the task back before a reviewer fix.
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
- Add `requesting-code-review` only to a final-review step that can dispatch a
  reviewer; omit it when reusable review evidence already supplies complete
  coverage
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
> 1. Read `Execution log` before the first task; it overrides stale plan text
> 2. Execute tasks in plan order
> 3. Load `executing-plans` when working from a saved plan
> 4. Append every drift, gotcha, and decision to `Execution log` before ticking
>    its task
> 5. Tick a task after all its nested steps pass
> 6. Un-tick a task when a reviewer sends it back
> 7. Track progress in the harness task list
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
> - `Execution log`: the current task owner appends; earlier entries are
>   append-only history

**Goal:** [One new observable behavior]

**Source requirements:**

1. `R1`: [Original user requirement]
2. `R2`: [Acceptance criterion]
3. `R3`: [Explicit must statement]
4. `R4`: [Explicit never statement]

**Execution mode:** [Subagent-Driven | Inline]

**Commit policy:** [Per-task commits | One commit at the end | No commits]

**Plan file policy:** [Include | Exclude]

**Additional plan state files:**

- none

**Solved defects:**

- none

**Execution log:**

---
```

- `Source requirements` is required
  - Record each original user ask
  - Record each acceptance criterion
  - Record each explicit must statement
  - Record each explicit never statement
- `Additional plan state files` is required
  - Use `none` as the only item when no additional state file exists
  - Otherwise list each exact repo-relative path once and omit `none`
  - List only paths that exist before execution starts
  - Do not list the plan file itself
  - Record every required edit to these files in `Source requirements`
  - For a path shared by concurrent plans, record an exclusive owner or exact
    turn protocol and require it before the edit
  - Treat the required update delta as `execution-state`, never implementation
    scope. Preserve unrelated pre-existing content as `baseline-only`
- `Solved defects` is required
  - Keep `none` until a reviewer finding is fixed
  - Replace `none` with unique regression-relevant entries
  - Format each entry as `severity | path or symbol | invariant`
- `Execution log` is required as a heading, empty
  - Write the heading with no body when drafting the plan
  - Execution owners append entries; the plan writer never pre-fills it
  - Never write `none`, `nothing found`, or any placeholder under it. An empty
    section already says nothing was found
  - Format each entry as
    `<task id> | <kind> | <what the plan assumed> | <what is true and what changed>`
  - `kind` is `drift`, `gotcha`, or `decision`

Skills are annotated per step, not in the header.

- Put every exact task-gate command directly in the task step that runs it
- Never point a task's verification step to the header or another plan section
- Put only exact commands for uncovered scope into the self-contained
  final-verification checkpoint; record evidence reuse without copying commands

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
- Comments, abstractions, defensive branches, or tests for speculative future
  needs and unreachable scenarios

Use verbatim content only for tricky config, signatures, and shell commands.
Describe test cases as inputs, outputs, and key assertions. Describe
implementation and layout as intent plus constraints.

### Length

Every task's body is re-read cold by its implementer and its reviewer, so plan
length is paid per task, not once. Cut what no agent acts on:

- Design rationale for a decision already settled belongs in the slice's own
  notes or an ADR, not in the plan body. Keep the decision, drop the argument
  for it
- Repo rules, tool invocations, and conventions appear once in the shared
  preamble, never restated per task
- Do not restate what a `path:line` citation already shows

**Floor — never cut into these.** An implementer must reach `Green:` without
asking a question or re-deriving a decision:

- Signatures, types, exact constants, and named files
- Every constraint that changes behavior, and every base and edge case
- Anything a `## Detail calibration` ban above would otherwise catch

If cutting a line would make a task ambiguous, keep the line. A short plan that
forces an implementer to guess costs a round trip and a drift entry; it does not
save time.

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
   4. `Execution log` heading is present and empty
2. **Ambiguity:** remove every "Detail calibration" red flag
3. **Type consistency:** signatures/names match across tasks (`clearLayers()` in
   Task 3 vs `clearFullLayers()` in Task 7 is a bug)
4. **Implementation leak:** replace derivable bodies/tests with signatures,
   constraints, and cases
5. **Reuse:** anything created that already exists -> import or extend instead
6. **Safety:** destructive operations match source requirements and target-repo
   rules; every named error mapping has a step that handles it
7. **Scope discipline:** remove unrequested comments, abstractions,
   dependencies, configuration, fallback paths, defensive branches, and tests
8. **Reachability:** every case is reachable through a supported flow or a real
   trust boundary; speculative tampering requires an explicit requirement or
   evidence of a recognized exploit with credible impact
9. **Verification:**
   1. Remove repeated `Green:` checks
   2. Remove standalone red phases
   3. Require exact impact-appropriate commands in each task's last verification
      step
   4. Require one plan-level final-verification checkpoint after all tasks
   5. Put final review coverage inside the final-verification checkpoint
   6. Reuse a one-task or final cumulative task review when it covers the
      unchanged complete implementation
   7. Dispatch final review only for uncovered review scope
   8. Require no unresolved final-review findings before final validation
   9. Establish complete final evidence once after the final-review fix loop,
      reusing valid task and reviewer-fix evidence
   10. Require every newly listed final command to be exact
   11. Require every newly listed final manual procedure to be exact
   12. Reject a separate plan-level final-review task
   13. Reject verification commands that reference another plan section
   14. Reject checks unrelated to the changed file categories or behavior
   15. Combine per-file formatter/linter invocations by tool
   16. Reject post-write existence/read-back checks already proved downstream
   17. Reject a narrow green check immediately followed by a containing suite
       when no intervening action consumes it
   18. Reject a full gate before final verification unless a one-task or
       last-task gate covers the complete implementation and final verification
       reuses it
   19. Reject final commands or manual checks already covered by still-valid
       task-gate or reviewer-fix evidence
   20. Require a zero-command final-validation path for one-task plans whose
       task gate covers the complete implementation
10. **Task overlap:** list each task's file set. Overlapping sets -> merge the
    tasks
11. **Repetition:** move repeated repo rules and conventions to the preamble
12. **Commit cadence:** checkpoint count and placement match the header policy;
    the conditional final-review-fixes commit follows final verification; all
    plan-state inclusion matches `Plan file policy`; no checkpoint freezes
    commands, messages, or paths; every additional state-file edit maps to a
    source requirement
13. **Review duplication:** remove implementation-review steps owned by
    `executing-plans`. For requested external-review work, reject narrowed,
    conformance-only, truncated, or status-only review
14. **Readability:**
    1. Every task is a checkbox
    2. Every step is a nested numbered item
    3. Every action has its own list item
    4. Every idea has its own list item or justified paragraph
    5. Every paragraph is correctly indented
    6. Every paragraph adds necessary non-action context
15. **Duplicate work:**
    1. Build the ordered command sequence for every task
    2. Compare test scopes
    3. Compare formatting scopes
    4. Compare lint scopes
    5. Compare type-check scopes
    6. Compare build scopes
    7. Remove each dominated command
    8. Keep an earlier command only when a later action consumes its result
    9. Group applicable paths into one invocation per tool
    10. Confirm every remaining command is justified by the change impact
    11. Compare task and reviewer-fix evidence with final-validation scope
    12. Remove final fallback copies of already-covered commands and procedures
    13. Remove tests, type checks, builds, and full gates invalidated only by
        semantic-neutral comments or canonical formatter output

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
- Check every command against the file categories and behavior it validates
- Reject per-file invocations when one invocation can cover the same files
- Reject existence/read-back checks already proved by a downstream consumer
- Reject tests, type checks, and builds unrelated to the planned diff
- Reject a full gate before final verification unless a one-task or last-task
  gate covers the complete implementation and final verification reuses it
- Reject checks separately repeated immediately before a full-gate command that
  contains them
- Reject final commands and procedures already covered by valid task or
  reviewer-fix evidence, especially in one-task plans
- Reject final review dispatch already covered by a valid one-task or cumulative
  task review
- Report an earlier dominated command as at least Important
- Do not limit this audit to identical command text

Flow:

1. Reviewer returns `PASS` or terse Critical/Important findings
2. Fix blocking issues inline
3. Re-review only if fixes could introduce new defects: changed architecture,
   direction, tasks, boundaries, ordering, file ownership, verification, or test
   expectations. Skip for surgical/wording/style fixes
4. Cap at 3 dispatches. Blocking issues remain after the 3rd -> escalate

**Review depth:** a dispatched review must be a good review. Escalate a thin one
rather than accepting it.

## Execution mode handoff

Write the resolved mode into the plan header, then save the plan. Report the
plan path and recorded mode. Do not ask during handoff.

- `Subagent-Driven` -> **REQUIRED SUB-SKILL:** `subagent-driven-development`
- `Inline` -> **REQUIRED SUB-SKILL:** `executing-plans`
