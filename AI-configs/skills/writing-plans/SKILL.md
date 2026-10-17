---
name: writing-plans
description: >
  Create a written implementation plan saved to a file. Use only when the user
  directly invokes the writing-plans skill or explicitly asks for a written
  plan. Do not use for in-memory plans, in-chat plans, internal task
  decomposition, native task lists, or ordinary multi-step implementation.
---

# Writing plans

Write a plan each task's implementer can execute after reading only that task
plus the shared header. Assume a capable mid-tier model that reads the repo. The
plan settles interfaces, behavior, cases, scope, and files. The implementer
discovers the code.

## Terms

- **Green:** a paste-able command emitting an observable success token (exit 0,
  `PASS`, `0 errors`, artifact). A manual-only check names an exact procedure
  and expected observation
- **Task:** one checkbox-tracked, committable unit with a shared file set
- **Step:** one numbered action nested under its task
- **Substep:** one numbered action nested under a step
- **Task gate:** the smallest non-dominated set of checks proving one task's
  changed files and behavior are commit-safe
- **Full gate:** the project's whole validation suite
- **Narrow gate:** the single test file or check a step affects
- **Dominated check:** a check fully covered by a later check when nothing
  consumes the earlier result
- **Footprint:** files, frameworks, runtimes, imports, and tooling a step
  touches
- **Touch point:** one change named by `path`, the symbol or region, and a
  one-clause intent

## Plan file, and the optional spec

Default to one file: `<name>-plan.md`. Most plans need nothing else.

A created spec file is a separate `<name>-spec.md` in the same folder, holding
acceptance criteria, out of scope, research findings, settled decisions, and ADR
links. The plan cites its requirements by stable ID or `path:line` and never
copies their prose.

Never create a bare `<name>.md` for either. User-supplied requirement documents
may use any filename.

**Never create a spec on your own judgment.** Propose it, name the gain a single
plan file cannot deliver, and wait for the user to agree. Write the plan alone
when they decline or do not answer.

The user may also ask for a spec directly at any time. Then write one without
proposing.

Propose a spec only for a gain the plan file cannot reproduce:

- Acceptance criteria too many to sit in the header without burying the tasks
- Research findings several tasks share, which would otherwise repeat
- Settled decisions with rationale that every implementer re-reads and no task
  acts on
- A document the user wants to review or circulate on its own

Do not propose one for: a short criteria list, a handful of tasks, a single
subsystem, or because the topic feels large. Those belong in the plan header.

When a spec exists, cite each source requirement by stable ID or `path:line`.
The spec is authoritative.

A user-supplied document already holding requirements is the spec regardless of
its filename. Cite it without copying it. Splitting it creates a new spec file,
so propose that split first.

When none exists, the header reads `**Spec:** none` and the plan carries its own
acceptance criteria in `Source requirements`.

## Plan location

- The plan ALWAYS lives in a file. Subagents have no session memory
- A caller-supplied path overrides the default
- Default: `docs/plans/YYYY-MM-DD-<feature-name>-plan.md`
- A spec, when the user agreed to one, sits beside the plan: same folder, same
  stem with `-plan` replaced by `-spec`
- Editing an existing plan: preserve content outside the requested change
- User refuses to save: STOP
- Saving does not commit. Record whether execution commits the plan file
- `Additional plan state files` are tracker documents execution updates, such as
  a milestone index. Each must exist before execution starts
- When concurrent plans share a state file, name its exclusive owner or exact
  turn protocol in `Source requirements` and the update checkpoint. Without that
  gate, require sequential execution
- `Plan file policy` covers the plan file and every additional state file

## Source requirements

- Capture `review_source_requirements` before drafting
- Preserve the user's original asks, acceptance criteria, every explicit must,
  every explicit never, and each source-spec path
- Keep the capture independent from the drafted plan. Never reconstruct it from
  the finished plan
- After context compaction with no capture available: stop and request it
- Without a spec, copy the captured requirements into the header
- With a spec, cite each captured requirement by stable ID or `path:line`

## Assumption gate

Verify facts that change the task split, an interface, or scope before drafting
tasks. Leave the rest to the implementer's discovery. Ask only about intent or
facts that discovery cannot resolve.

Run this before writing any task.

1. List the facts the plan depends on: a file or symbol to touch, a cross-task
   signature, a dependency's installed major version, a tool or config that
   decides a task gate
2. Mark each `verified` or `open`
3. Resolve every `open` fact discovery can reach. Never ask what you can read
4. Ask the user every `open` fact discovery cannot reach
5. Write a `**Constraint:**` only for what neither resolved

The writer reads; the implementer runs. Read files, docs, type definitions, and
library source, and run read-only commands. Never run code, tests, builds, or
checks: the implementer's red and green runs do that once, at a lower cost.

Never read library internals. A runtime detail that changes only code inside a
task is the implementer's to discover.

Facts about runtime behavior and the plan's new code are predictions, not
verified facts. Write the prediction. When reading cannot settle it, add a
`**Constraint:**` naming the prediction and its fallback. A wrong prediction
fails in the implementer's red or green run, and escalation handles it.

### 1. Discover

Discover before asking. Never ask permission to investigate; read these and
report findings, not intentions.

- Read the target files, their neighbors, callers, and tests
- Read signatures, types, schemas, config, and lock files
- Read the governing `AGENTS.md`, `CLAUDE.md`, and contributing guide
- Read existing ADRs and project docs
- Run `--help`, `--version`, and read-only subcommands
- Fetch the current official docs when external behavior matters
- Search upstream issues and PRs when repo research is inconclusive and upstream
  behavior changes the plan

Stop discovering when more reading cannot change a task.

### 2. Ask

Discovery settles facts. It does not settle intent. Ask the user for what
remains.

Ask when:

- The answer is a preference, a priority, or an accepted tradeoff
- Two valid approaches lead to materially different plans
- Verifying needs a destructive action, missing access, a paid call, or
  credentials you do not have
- The requirement itself is ambiguous and a wrong reading wastes the plan

Never ask:

- Anything a file, a lock file, `--help`, or the official docs answers
- Permission to read, search, fetch, or probe
- A choice a project convention, a repo pattern, or an obvious default already
  settles
- A detail that does not change the plan

#### How to ask

Ask before drafting tasks.

1. Show the full numbered list of open questions first, so the user sees the
   scope
2. Ask them one at a time, in list order
3. Use the harness question tool when one exists; otherwise ask in chat. A
   subagent writer sends its questions and spec proposals to its dispatcher
   instead and waits for the answers
4. Give each question a recommended answer, so the user confirms rather than
   composes
5. Wait for the answer before the next question

Never batch several questions into one message. A batched answer loses detail
against the question it belongs to.

An answer that settles or removes a later question drops it. Say which, and
continue with the next.

An answer that raises a genuinely new blocker adds it to the list, asked after
the current one. Never let this run long; this is a planning gate, not an
interview.

A user who declines to answer, or a run that forbids questions, sends that fact
to step 3.

### 3. Constrain, last resort

Only a fact neither discovery nor the user settled becomes a `**Constraint:**`
in the task that depends on it, naming what was not verified, how the
implementer checks it in one step, and what to do when it proves false.

Never write an unresolved fact as plain instruction text. A constraint is the
exception, not a substitute for asking.

### Forbidden assertion shapes

Never write these. Each hides an unverified fact as instruction:

1. "Run `<cmd>`, which will <behavior you did not read>", unless it is a labeled
   prediction
2. "The template ships `<file>`" without having read it
3. "`<check>` catches `<error class>`" without reading the config that selects
   its files
4. "This should work if `<condition>`"
5. "Assuming `<X>` holds, ..."

Catching yourself drafting one: stop, read, then write the fact or a labeled
prediction.

### Report what stayed open

State every remaining unverified fact at handoff, each naming the task it
affects and why it stayed open: discovery could not reach it, or the user
declined to settle it. An unreported assumption is a defect the implementer
inherits blind.

## Scope check

- Spec covering multiple independent subsystems: split into one plan per
  subsystem
- Each plan produces working, testable software on its own

## Decomposition

- Map files to create or modify with their responsibilities before defining
  tasks
- One responsibility per file. Group files that change together
- Follow existing patterns. Split an unwieldy file only when modifying it
- Search the repo for existing components, helpers, hooks, and utilities first.
  Reuse is mandatory. Extend before creating
- Prefer existing code, then standard-library or native platform features, then
  installed dependencies
- Add an abstraction, dependency, configuration point, fallback, or extension
  hook only when a current requirement needs it
- Prefer the fewest files and the smallest root-cause diff satisfying the source
  requirements
- Do not prescribe unsolicited comments or documentation
- Cover behavior reachable through the supported UI, API, job, or ordinary
  operation
- Do not invent cases based on impossible states, internal tampering,
  unsupported misuse, or hypothetical hacking
- Include adversarial security cases only when explicitly required, when
  untrusted input crosses a real trust boundary, or when evidence shows a
  recognized exploit with credible impact here
- Never simplify away trust-boundary validation, data-loss prevention, or an
  explicitly requested security measure
- Do not bundle unrelated changes because they touch nearby code
- Merge tasks whose file sets overlap. One task per file set
- A task delivers one slice of working behavior plus its tests. Everything that
  behavior needs to run belongs in the task that uses it
- Never write a task whose only deliverable is a type, schema, constant, or stub
  a later task consumes. Merge it into its consumer
- Never write a task that only formats, commits, or ticks boxes. Fold formatting
  into the task that edits the file
- Split only where a reviewer could reject one task while approving its neighbor
- Past ~8 tasks: merge, or split into separate plans

## Task formatting

- One top-level checkbox per task: `- [ ] **Task N: ...**`
- One umbrella outcome per title. Never join outcomes with `and`
- One observable behavior in `Goal`
- Nest every step as a numbered list under its task
- One action per list item. Never join actions in a prose line
- Indent task content under the checkbox, step content under its number
- Use a paragraph only for non-action context that changes execution: an edge
  case, a constraint rationale, a caveat
- One idea per paragraph, placed under what it qualifies
- Label a paragraph `**Edge case:**`, `**Constraint:**`, or `**Why:**` when the
  relationship is not obvious
- Write one `**Files:**` list per task: every repo-relative path the task
  creates or edits by hand. Executors seed owned paths from it and
  `**Changes:**` lines
- Add `**Changes:**` under a step whose command creates, changes, or deletes
  files. List each path in only one of `**Files:**` and `**Changes:**`. List
  each file path, never a directory. Example: `pnpm add zod` changes
  `package.json` and `pnpm-lock.yaml`
- Add `**Implementer decides:**` to name local choices left open on purpose

## Markdown format

- Put a blank line between every two blocks: paragraph, label paragraph, list,
  fence, table
- Put a blank line between a list item's title line and its nested content
- Put a blank line between sibling task items and between sibling step items
- A leaf list of one-line items, such as file paths or substeps, stays tight
- Put a label paragraph between two adjacent lists. Prettier deletes the blank
  line between them. Under a task, `**Steps:**` precedes the step list
- Give each `**Label:**` its own paragraph. A single newline is not a line
  break; a prose-wrap formatter joins the two lines
- Indent nested content to its parent's content column: 2 spaces under `- [ ]`,
  3 under `1.`
- Declare a language on every fence
- After saving, run the target repo's Markdown formatter on the plan file. No
  repo formatter config: run
  `prettier --log-level error --prose-wrap always --embedded-language-formatting off --write <plan>`
- Always pass `--embedded-language-formatting off` to prettier. Otherwise it
  reformats code inside fences and breaks exact code

## Plan skeleton

```markdown
# [Feature Name] Implementation Plan

[Plan header fields]

---

## Shared preamble

- A named file or symbol is missing, a fix needs a plan-owned decision, or a
  needed path is outside your owned paths: stop and report, naming a path as
  `need path claim <path>`. Never decide it yourself
- [Repo rule every task follows]

## Tasks

- [ ] **Task 1: [Observable outcome]**

- [ ] **Commit task 1**

- [ ] **Final verification checkpoint**

- [ ] **Final state commit checkpoint**
```

- Use exactly these two H2 headings, in this order
- Keep the stop rule as the first preamble item, verbatim
- A milestone plan's coordinator completion action is the last step of the
  final-verification checkpoint
- Put every task, commit checkpoint, and the final-verification checkpoint under
  `## Tasks`

## Task template

````markdown
- [ ] **Task N: [Observable outcome]**

  **Goal:** [Current behavior. Target behavior. Observable result.]

  **Difficulty:** low | medium | high

  **Files:**

  - `src/parser.py`
  - `tests/test_parser.py`

  **Interfaces:**

  - Consumes: `normalize(text: str) -> str` from Task M
  - Produces: `parse(text: str | None) -> Result`

  **Implementer decides:** helper names, test names, and test layout

  **Steps:**

  1. **Write failing tests for `parse()`**

     **Skills (load if not already loaded):** `<language-skill>`

     1. Add `Result` and a `parse()` stub raising `NotImplementedError` to
        `src/parser.py`
     2. Add one test per `**Cases:**` item to `tests/test_parser.py`, following
        `tests/test_text.py`
     3. Run `pytest tests/test_parser.py`
        - Expected: the new tests fail on `NotImplementedError`, with no
          collection errors

     ```python
     @dataclass(frozen=True)
     class Result:
         value: str
     ```

     **Cases:**

     - Valid text returns `Result` holding the normalized text
     - `""` returns `Result(value="")`
     - `None` raises `ValueError("text is required")`

  2. **Implement `parse()`**

     1. Replace the `parse()` stub body in `src/parser.py`

     **Constraint:** normalize through `normalize()` at `src/text.py:8`.

  3. **Run the task gate once**

     1. `[one formatter command listing every applicable task file]`
     2. `[one linter command listing every applicable task file]`
     3. `[affected test command]`

     Green: every command exits 0.
````

## Difficulty

Set `**Difficulty:**` on every task. The dispatcher maps it to a model.

Write every task so the default coding model can finish it. A bigger model is
the fallback for a stuck implementer, not the default.

- `low`: mechanical change with no new logic: a rename, a config value, a copy
  of an existing pattern
- `medium`: the default. New logic in one module or a few closely related files
- `high`: cross-module contract, an ambiguity the plan could not close, or a
  case the writer flagged as risky

Rate the implementation work, not the diff size.

## Interfaces

Add `**Interfaces:**` only when a task consumes or produces a cross-task
contract. An implementer sees only its own task.

- `Consumes`: exact signatures this task calls, each naming its producing task
- `Produces`: exact signatures later tasks call
- Names and types MUST match verbatim across the producing and consuming tasks

## Code detail

The plan settles decisions that cross a task boundary or are costly to reverse.
The implementer discovers the rest by reading the repo.

### Touch points

- Name each change as a touch point in the step that makes it
- Cite an existing symbol as `path:line` only when the implementer would
  otherwise search for it
- Never write anchors, `Replace`/`With` blocks, or function bodies
- Never copy a whole existing file into the plan

### Write as code

Only these:

- Signatures and types listed in `**Interfaces:**`
- Constants, user-visible strings, and error messages that tests or users
  observe
- Config fragments whose exact values matter
- Shell commands

Everything else is prose or a pointer to a repo pattern.

### Tests

- Point at one existing test file as the pattern
- List cases as bullets under `**Cases:**`: input and expected behavior
- Name the fixture or helper to reuse when one exists
- Stub every produced signature before the red run, so collection succeeds
- A red run states what must fail and that collection must succeed
- Behavior of new code that docs and source cannot settle: write a
  `**Constraint:**` with a one-step check and a fallback

### Docs

- User-facing text of 15 lines or fewer: give the exact text
- Longer: give the section and a list of every fact the text states

### Write as prose

- Behavior constraints with no literal form
- Ordering and invariants
- Why an alternative was rejected, only when an implementer would otherwise pick
  it
- A trap an implementer would otherwise fall into
- Anything negative: what not to reuse, what not to add

## Detail calibration

Every step states what to build, its constraints, and its cases without
dictating derivable implementation.

Never write:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling", "handle edge cases", "style nicely"
- "Write tests for the above" without the cases
- "Similar to Task N". Steps are read out of order
- "Build the component" and other vague instructions
- References to types, functions, or methods no task defines and the repo cannot
  import
- Comments, abstractions, defensive branches, or tests for speculative needs
- Code outside `### Write as code`
- A plan-owned choice left open: an interface, a case, a file, a scope boundary,
  or a user-visible value. Local choices may use "or" and "e.g."

### Length

Every task body is re-read cold by its implementer and its reviewer. Cut what no
agent acts on:

- Design rationale for a settled decision belongs in the spec, not the plan
- Repo rules, tool invocations, and conventions appear once in the shared
  preamble
- Never restate what a `path:line` citation shows
- Never justify absent work. A check you did not add needs no explanation

**Floor.** An implementer reaches `Green:` without asking about a plan-owned
decision. Never cut:

- Signatures, types, exact constants, named files
- Every constraint that changes behavior, and every case
- Anything a `## Detail calibration` ban would otherwise catch

Keep a line whose removal makes a task ambiguous.

## Shared preamble

State repo rules once, above the tasks, under `## Shared preamble`. Never repeat
them per task.

## Verification

- Map each command to the changed path or behavior justifying it
- Omit a command when no changed path or repo rule makes it applicable
- Batch every file a tool accepts into one invocation. Never one per file
- Run the task gate only as each task's last verification
- A task gate holds only commands. Put every manual check in the
  final-verification checkpoint
- Never write an aggregate command (`make test`, `pnpm run test`, a pathless
  `pytest`) as a step's `Green:`. Aggregates belong to the task gate
- Executors drop inapplicable and dominated commands per `executing-plans`
  `## Verification selection`

## Commit policy

Ask whether execution may create mechanical commits. Record the answer as
`Checkpoint commits` or `No commits`. Record
`Plan file policy: Include | Exclude`, default `Include`, and apply it to the
plan file plus every `Additional plan state files` path.

Encode the policy with checkpoints:

- `Checkpoint commits`: one checkpoint per task and one final-state checkpoint
  after final verification
- `No commits`: no checkpoints

Write each checkpoint as a bare line. The executing skill owns the mechanics:

```markdown
- [ ] **Commit task N**
```

```markdown
- [ ] **Final state commit checkpoint**
```

Never write a commit command, message, or file list into a checkpoint. The owner
derives all three from the diff at checkpoint time.

`No commits` plus a requested PR is invalid. Resolve the conflict while writing
the plan.

## Final verification

Every plan ends with one final-verification checkpoint after all tasks.

- Build a review-evidence map from completed task reviews before dispatching a
  final reviewer
- Reuse a task review covering the complete current implementation. This holds
  for a one-task plan, and for the last cumulative task review when no
  implementation content or semantic input changed afterward
- Dispatch a final reviewer only for uncovered review scope
- Build an evidence map from task gates and reviewer-fix gates before adding
  final commands
- Add a final command only for applicable scope no valid evidence covers
- A commit, read-only review, or checkbox update does not invalidate evidence
- List no final checks when the task gates already cover the complete
  implementation
- Never copy task-gate commands into final verification as fallbacks
- Never point a final command at another plan section
- Add each manual check as an exact procedure with one expected observation,
  under a `**Manual check (user):**` label. Agents skip it; the executing skill
  relays it to the user after final verification
- Remove every unused placeholder

```markdown
- [ ] **Final verification checkpoint**

  1. **Close final review coverage**

     Omit the dispatch step when task-review evidence covers the complete
     current implementation. The executing skill owns review mechanics.

     1. Reuse a task-review result covering the complete implementation
     2. Dispatch a fresh reviewer only for missing coverage
     3. Resolve each substantiated finding
        1. Verify its cited evidence
        2. Apply the narrowest valid fix
        3. Run only checks the fix invalidated
     4. Re-dispatch after a behavioral fix round
     5. Do not re-dispatch after an all-static fix round whose gates pass

  2. **Close uncovered automated evidence**

     1. Reuse every task-gate and reviewer-fix result covering the current state
        and semantic scope
     2. Run `[exact command for uncovered scope]`
        - Omit when reusable evidence covers all applicable scope
        - Expected: exit 0

  Green:
  - Final review has no unresolved findings
  - Evidence covers every applicable check for the current state
```

## Execution mode

Resolve before writing. Default `Subagent-Driven`. Record the exact literal in
the header.

## Progress tracking

Tasks carry `- [ ]` checkboxes.

The execution ledger, not the box, is authoritative resume state. A `[x]` with
no matching ledger line means the ledger was lost: re-verify by running that
task's gate before skipping the task.

Record deviations as ledger `Ruling:` lines, never in the plan.

## Skills per step

- Skills load at the step needing them, not upfront
- Scan each step's footprint against skills listed in the current environment.
  Use exact names. Never invent or rename
- Signals: file extensions, frameworks, runtimes, test runners, specific
  imports, build and package managers, domain tooling
- Add `**Skills (load if not already loaded):**` only on a matching step
- Any step reading or replying to a bot review gets
  `replying-to-pr-review-threads`

## Review-related steps

Execution skills own implementation-review mechanics and PR creation. The plan
owns only the final-review step inside its final-verification checkpoint.
Preserve a PR request in `Source requirements`.

When the requested work itself reads external review output:

- Never narrow the reviewer template or replace defect review with conformance
- Read the full output and reconcile stated against observed finding counts
- Never treat a green status as proof review occurred

## Plan header

```markdown
# [Feature Name] Implementation Plan

**Spec:** [path to the spec file this plan implements | none]

**Goal:** [Current behavior, cited with `path:line`. The gap it leaves. Target
behavior. What a user or caller observes when the plan is done.]

**Out of scope:**

- [Adjacent behavior, file, or flow this plan must not change]

**Source requirements:**

1. `R1`: [Original user requirement]
2. `R2`: [Acceptance criterion]
3. `R3`: [Explicit must statement]
4. `R4`: [Explicit never statement]

**Architecture:** [2-3 sentences: the approach and its boundaries]

**Call chain:**

1. `Module.entry()` at `path/to/entry.lua:120`
2. `Other.step()` at `path/to/other.lua:45`
3. `Leaf.changed()` at `path/to/leaf.lua:212`

**Execution mode:** [Subagent-Driven | Inline]

**Commit policy:** [Checkpoint commits | No commits]

**Plan file policy:** [Include | Exclude]

**Additional plan state files:**

- none

---
```

- `Spec` is required as a field. Give the repo-relative path when a spec file
  exists, otherwise `none`
- `Goal` is required and holds 3-6 sentences: current behavior, gap, target
  behavior, observable result
- `Out of scope` is required. List adjacent behavior an implementer could change
  by mistake, or `none`
- `Call chain` is required when the change crosses files. Order it from the
  entry point to the changed leaf, one symbol at `path:line` per item
- `Source requirements` is required
  - Without a spec, record each original ask, acceptance criterion, explicit
    must, and explicit never
  - With a spec, cite each requirement by stable ID or `path:line`
- `Additional plan state files` is required
  - `none` as the only item when no additional file exists
  - Otherwise each exact repo-relative path once, and omit `none`
  - List only paths existing before execution starts
  - Never list the plan file itself
  - Record every required edit to these files in `Source requirements`
  - For a path shared by concurrent plans, record an exclusive owner or exact
    turn protocol
  - Treat the update delta as `execution-state`, never implementation scope
- Annotate skills per step, never in the header
- Put every exact task-gate command in the step that runs it
- Never point a task's verification at the header or another section

## Cross-cutting constraints

- Commit and test-file conventions come from the target repo. Never invent
  either
- Lock design decisions affecting test assertions (ARIA roles, landmarks,
  semantic HTML) in the plan. Leave styling open
- Hold the same constraint detail level across steps of the same type

## Self-review

After writing, check and fix inline:

1. **Coverage:** every captured source requirement is in the header, maps to a
   task, and each task maps to a gate. A spec, when present, owns criteria and
   rationale; otherwise `**Spec:**` reads `none`
2. **Plan-owned decisions:** every interface, case, file, scope boundary, and
   user-visible value is settled; `Produces` and `Consumes` match verbatim;
   every task has a `**Difficulty:**` literal and a `**Files:**` list
3. **Assumptions:** no forbidden assertion shape remains; every open fact was
   asked or is a `**Constraint:**` with a fallback
4. **Scope and reuse:** nothing unrequested or already in the repo; every case
   reachable through a supported flow or a real trust boundary; destructive
   operations match source requirements
5. **Tasks:** no overlapping `**Files:**` and `**Changes:**` sets; no
   deliverable-free task; no code outside `### Write as code`; each task ends
   with one gate; one final-verification checkpoint after all tasks
6. **Format:** header fields and checkpoints match the recorded policies; repo
   rules live in the shared preamble; the formatter ran

## Plan reviewer

After self-review, dispatch one subagent with `plan-reviewer-prompt.md`.

```text
1. Read <skill_dir>/plan-reviewer-prompt.md first
2. Do not continue until the read completes
3. Apply these values
   - skill_path = <abs path to this SKILL.md>
   - plan_path = <abs path>
   - spec_path = <abs path, or `none`>
   - repo_root = <abs path>
   - source_requirements = <review_source_requirements captured before drafting>
   - discovery_context = <facts the writer verified, each with its source>
```

- `<skill_dir>` is this file's directory
- Substitute absolute paths
- Pass `review_source_requirements` directly. Never derive it from the plan
- Pass the pointer and values. Never the template body

Flow:

1. The reviewer returns `PASS` or terse Critical and Important findings
2. Fix blocking issues inline
3. Re-review only after fixing a `Critical` finding. After fixing only
   `Important` findings, run self-review on the changed tasks instead
4. Cap at 2 dispatches. Blocking issues after the second: escalate

## Handoff

Write the resolved mode into the header, save the plan and its spec when one
exists, then report the plan path, the spec path or `none`, the recorded mode,
and every fact still open with the task it affects. Do not ask during handoff;
the assumption gate already asked.

A dispatched writer returns this report to its dispatcher and never executes the
plan.

- Both modes -> **REQUIRED SUB-SKILL:** `executing-plans`
- `executing-plans` loads `subagent-driven-development` only for
  `Subagent-Driven`
