---
name: writing-plans
description: >
  Use when you have a spec or requirements for a multi-step task, before
  touching code
---

# Writing plans

Write self-contained implementation plans for an agent with zero repo context.
Skilled engineer, but does not know this codebase or domain. Cover: files to
touch, what to build, how to test. Bite-sized tasks. DRY, YAGNI, TDD, optional
commit checkpoints.

**Announce at start:** "I'm using the writing-plans skill to create the
implementation plan."

## Terms

- **Green:** a paste-able command runs and emits an observable success token
  (exit 0, `PASS`, `0 errors`, compiled artifact). Not "looks done". At a task
  boundary it also means committable
- **Bite-sized:** one step = one action, verifiable in isolation. Committable is
  a property of the task, not of every step
- **Bootstrap stubs:** minimal types/signatures that make tests _run_ (not pass)
  - empty bodies, `NotImplementedError`, or wrong defaults
  - Default: write them as the first activity INSIDE the implementing step
  - A separate ticked bootstrap step is justified ONLY when the step creates a
    new file, module, or public symbol that a LATER task imports
- **Full gate:** the project's whole validation suite — format + lint + types +
  full test run — in ONE command where the project has one (`make validate`,
  `pnpm validate`). Slow. Runs once per task, not once per step. Prefer the
  project's single command over a hand-assembled chain; it is what CI runs and
  it cannot drift from it
- **Narrow gate:** the single test file or single check a step actually affects
- **Footprint:** the files, frameworks, runtimes, imports, and tooling a step
  touches - scanned to match skills

## Worked example (the shape every task follows)

Example is Python; the same shape applies to any language. Language-specific
rules (test-file naming, package manager) are in "Net-new constraints" below.

````markdown
### Task N: [Goal-oriented title - what it achieves, not files touched]

**Goal:** [One sentence: what works after this that didn't before]

**Files:**

1. `exact/path/to/file.py`
   - Create `function()` that validates input and returns `Result`
   - Re-use `LibraryThing` from `exact/path/to/lib.py`
2. `exact/path/to/file.test.py`
   - Covers `function()` base + edge cases

- [ ] **Step 1: Implement `function` with TDD**

  **Skills (load if not already loaded):** `<test-runner-skill>`,
  `<language-skill>`

  Inside this step (NOT separate ticked steps):
  1. Stub `Result` + `function()` with their FINAL signatures and a wrong body
     (returns `None`, returns a constant). Signature written once, so the
     implementation edits only the body
  2. Write tests for the base cases below
  3. Run - verify they fail on assertion mismatch (not Import/Module/Attribute
     error). If they crash, finish the stub
  4. Implement per signature + constraints
  5. Run - verify all pass

  Signature: `def function(input: str) -> Result`
  - Accept X, validate Y, return Z. Use `LibraryThing` for heavy lifting
  - Empty input returns `Result.empty()`

  Base cases:
  - `function("valid")` -> `Result(value="valid")`
  - `function("")` -> `Result.empty()`
  - `function(None)` raises `ValueError`

  Explore edge cases you find relevant (unicode, whitespace, large input).

  Green (narrow gate): `pytest exact/path/to/file.test.py -v` passes all cases.

- [ ] **Step 2: Full gate, then commit** (commit only if policy needs it)

  Run the header's `Full gate` once for the whole task - not in Step 1.
  Reviewers do not run it, so a red gate here must not be dispatched onward.

  Green: `[header Full gate command]` exits 0.

  ```bash
  git add exact/path/to/file.py exact/path/to/file.test.py <this-plan-file>.md
  git commit -m "Add specific feature"
  ```

  Stage the plan file too when the executing agent ticked before committing. In
  subagent mode ticks land after the implementer's commit — leave them for the
  next one, never amend.

- [ ] **Final step (last task only): Run final verification**

  **Skills (load if not already loaded):** `verification-before-completion`

  This REPLACES the last task's full gate - do not write both. Run the header's
  `Final verification` commands and report actual output:
  - `[header Full gate command]` -> exits 0
  - `[anything the Full gate does not cover: build, doc generation]`
  - `[any manual check headless tests cannot reach]`
````

## Plan location

- Plan ALWAYS lives in a file. Subagents have no session memory; file is the
  only source of truth
- Already in a plan file: ask before reformatting. Preserve original content
  unless user approves removal
- Not saved: default `docs/plans/YYYY-MM-DD-<feature-name>.md`. User may pick
  another path
- User refuses to save to any file: STOP. Do not proceed
- Plan file is not committed automatically. User decides

## Commit policy

Before writing, ask:

```markdown
How should commits be handled for this plan?

1. One commit per task
2. One commit at the end
3. No commits
```

Match the selected policy. Commit steps only when policy needs them (option 1 or
2).

## Scope check

- Spec covers multiple independent subsystems: suggest splitting into separate
  plans, one per subsystem
- Each plan must produce working, testable software on its own

## File structure (decomposition locks here)

- Map files to create/modify + their responsibilities before defining tasks
- One responsibility per file. Files that change together live together. Split
  by responsibility, not layer
- Follow existing patterns. Don't restructure unilaterally. Split an unwieldy
  file only when modifying it
- Search the codebase for existing components/helpers/hooks/utilities first.
  Reuse mandatory. Extend before creating
- Prefer surgical edits. Don't bundle unrelated changes because they touch
  nearby code

## Bite-sized task granularity

- Each step is one action, verifiable on its own. The TASK ends green and
  committable; individual steps need not
- Every step ends with a `Green:` line = exact paste-able command + observable
  success token. No bare "compiles" / "tests pass" - name the command and what
  output proves it
- Green uses the NARROWEST command that proves the step: the one test file, the
  one check. Never the full gate
- The full gate runs ONCE per task, as the task's last verification - before any
  review stage and before the commit
- The LAST task has no separate full gate. Its final-verification step is the
  gate, run once. Writing both means running the whole suite twice back to back
- Red phases are activities INSIDE the green-producing step, never separate
  ticked steps
- GOOD: "Implement <feature> with TDD" (Green: `pytest path -v` -> all pass)
- BAD: "Write the failing test" (red is interim, not a deliverable)
- BAD: "Run it, verify it fails" (same)
- BAD: a step whose Green is the full gate when only one test file changed
- BAD: a step whose only content re-checks something a previous task's Green
  already proved
- TDD red must fail on assertion mismatch, not runtime/import/setup error. Crash
  -> finish the stub inside the same step
- Describe intent + constraints, not full implementation. Agent writes the code

## Plan size budget

Every task costs a test cycle, a full gate, and a commit. Fewer, wider tasks
beat many narrow ones.

- Two tasks whose file sets overlap MUST merge. Re-editing a file in a later
  task pays the whole cycle twice
- One task per file set, not one task per concern
- Past ~8 tasks: merge overlapping file sets, or split into separate plans (see
  "Scope check")
- Rationale is capped at 2 lines per constraint. Cite `path:line` instead of
  restating the argument the reader can go read
- State a repo rule once, in the plan's shared preamble. Never repeat it
  per-task
- Collapse families of near-identical base cases (same assertion, different
  input) into one loop-driven case. Keep them separate only when each pins a
  distinct code path

## Tracking

When executing from a plan file, flip `- [ ]` to `- [x]` immediately after
verifying each step. Do not batch at the end. Flip back to `- [ ]` if a reviewer
sends that step back. `executing-plans` owns this; only the agent running it
writes to the plan file.

## Required skills (per step)

- Skills load at the step that needs them, not upfront (keeps them salient,
  avoids early token tax)
- Scan each step's footprint against skills listed in the current environment.
  Use exact names. Do not invent or rename
- Signals: file extensions touched; frameworks/runtimes named; test
  runners/config; specific imports; build/package managers; domain tooling (Git,
  Obsidian, Slack, Jira, CI, Neovim, browsers)
- Add `**Skills (load if not already loaded):**` line only on steps with a
  match. No match -> no line
- Final verification step always:
  `**Skills (load if not already loaded):** verification-before-completion`. Do
  not load it earlier unless another instruction requires it

## Plan document header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For the executing agent:** Execute task-by-task. Use `executing-plans` when
> working from a saved plan in a separate session. Steps use checkbox (`- [ ]`)
> syntax. Tick each box the moment its step passes; never batch ticks at the
> end. A reviewer sending a step back returns its box to `- [ ]` until the fix
> passes.
>
> **Only the agent running `executing-plans` ticks these boxes.** If you are an
> implementer subagent dispatched for one task, do not edit this file at all -
> the orchestrator ticks on your behalf. Report your results instead.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Commit policy:** [One commit per task | One commit at the end | No commits]

**Full gate:** [the project's single validation command if it has one, e.g.
`make validate`. Otherwise the exact chain covering format + lint + types + full
test run, e.g. `pnpm format && pnpm lint && pnpm typecheck && pnpm test`]

**Final verification:** [the full gate above, plus anything it does not cover -
build, doc generation, manual checks headless tests cannot reach]

---
```

Skills are annotated per step, not in the header.

State the gate commands here once. Task steps reference them ("run the full
gate") instead of repeating the command list per task.

## No ambiguity

Every step unambiguous on _what_ to build and _which_ constraints matter. But
unambiguous != copy-paste-ready code.

**Plan failures - never write:**

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling / validation / handle edge cases"
- "Write tests for the above" (without listing what to test)
- "Similar to Task N" (repeat it - steps get read out of order)
- Vague no-constraint instructions ("build the component", "style it nicely")
- References to types/functions/methods not defined in any task

**Fine - the engineer is skilled:**

- Signature + bullet constraints instead of full body
- "CSS Grid, sidebar fixed-width, content fills remaining" instead of full CSS
- "Nav component with aria label + h2 placeholder" instead of full JSX
- Describe what a config needs instead of the verbatim file

## Code detail calibration

- **Full code, verbatim:** tricky config (tsconfig/vitest quirks), type +
  function signatures, shell commands with expected output
- **Test lists, describe:** base cases with inputs/outputs, assertions that
  matter (roles, landmarks, states, text), instruct agent to add edge cases
- **Instructions, describe:** function/component bodies (agent derives from test
  list + signature), CSS layout intent not property values (reuse existing
  variables/tokens/helper classes), CRUD/wiring/glue
- When in doubt: signature + constraints + what to test

## Net-new constraints (not covered elsewhere)

- Commit messages: bare imperative subject, no `type(scope):` prefix. Branches
  squash-merge, so PR title carries conventional format, not commits
- Test files collocated beside source: `Foo.test.tsx` beside `Foo.tsx`, no
  `__tests__/` folders. Each component its own test file
- Destructive ops (`rmtree`, overwrite, move-onto-existing) need an exists-guard
  or a stated reason they can't collide. Never hard-destroy on a soft-delete
  path
- Design decisions affecting test assertions (ARIA roles, landmarks, semantic
  HTML) locked in the plan. Styling can stay open
- Same constraint-detail level across steps of the same type
- Package manager: detect from lock files or root `packageManager`. Use detected
  runner. Never default to `npm`/`npx`. Undetectable -> stop and ask

## Self-review (run yourself, not a subagent)

After writing, re-check and fix inline:

1. **Coverage:** each user requirement maps to a task. List gaps, add tasks
2. **Placeholder scan:** any "No ambiguity" red flag. Fix
3. **Type consistency:** signatures/names match across tasks (`clearLayers()` in
   Task 3 vs `clearFullLayers()` in Task 7 is a bug)
4. **Implementation leak:** any full body/test code derivable from constraints
   -> replace with signature + bullets / base-case list + "explore edge cases"
5. **Reuse:** anything created that already exists -> import or extend instead
6. **Destructive-op:** any delete/overwrite/move-onto/truncate on a path holding
   data -> exists-guard or fail closed. Every "raises X -> HTTP N" has a step
   catching X (uncaught -> 500)
7. **Verification redundancy:** any `Green:` that re-proves a previous step's
   `Green:` -> delete. Any full gate that is not the task's LAST verification ->
   narrow it. Any step that only verifies a previous task -> delete the step.
   More than one full gate in the same task -> delete all but the last
8. **Task overlap:** list each task's file set. Overlapping sets -> merge the
   tasks
9. **Repetition:** any repo rule, lint quirk, or convention stated in more than
   one task -> move to the shared preamble, delete the copies

## Plan reviewer

After self-review, dispatch a subagent once to review the plan. Audits internal
quality only (contradictions, assumptions, ordering, granularity, reuse,
redundant verification, over-specification, blind spots), NOT against an
external spec. Categories live in `plan-reviewer-prompt.md`.

Dispatch payload. Do NOT read or open `plan-reviewer-prompt.md` yourself — the
subagent reads it. Reading it into your own context defeats the offload:

```text
MUST read instructions at <skill_dir>/plan-reviewer-prompt.md FIRST. Do not
act until you have read it. Then apply:
  task_summary = <one-line summary of the plan under review>
  plan_path    = <abs path>
  repo_root    = <abs path>
```

`<skill_dir>` = directory of THIS SKILL.md. Substitute the real absolute path.
WRONG: pasting the template body. RIGHT: the literal
`MUST read instructions at ...` line. Subagent reads the template itself.

Flow:

1. Reviewer returns ✅/❌ with Critical/Important/Minor. Only Critical +
   Important block approval
2. Fix blocking issues inline
3. Re-review only if fixes could introduce new defects: changed architecture,
   direction, tasks, boundaries, ordering, file ownership, verification, or test
   expectations. Skip for surgical/wording/style fixes
4. Cap at 3 dispatches. Issues remain after 3rd -> escalate to user

**Model:** default cheap/fast (review is mostly pattern matching). Escalate only
when the first review came back thin or the plan is high-stakes/complex.

## Execution handoff

After saving, offer:

**"Plan complete and saved to `<plan_path>`. Two execution options:**

**1. Subagent-Driven** - fresh subagent per task, two-stage review per task,
fast iteration

**2. Inline Execution** - execute in this session using `executing-plans`,
two-stage review per task

**Which approach?"**

- Subagent-Driven -> **REQUIRED SUB-SKILL:** `subagent-driven-development`
- Inline -> **REQUIRED SUB-SKILL:** `executing-plans`
