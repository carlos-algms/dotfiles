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

- **Green:** repo in a committable state - a paste-able command runs and emits
  an observable success token (exit 0, `PASS`, `0 errors`, compiled artifact).
  Not "looks done"
- **Bite-sized:** one step = one action, verifiable, reviewable, committable in
  isolation
- **Bootstrap stubs:** minimal types/signatures that make tests _run_ (not pass)
  - empty bodies, `NotImplementedError`, or wrong defaults
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

- [ ] **Step 1: Bootstrap stubs**

  Create `Result` type + `function()` stub raising `NotImplementedError`. Green:
  `python -c "import file"` exits 0 (imports resolve, tests run without
  crashing).

- [ ] **Step 2: Implement `function` with TDD**

  **Skills (load if not already loaded):** `<test-runner-skill>`,
  `<language-skill>`

  Inside this step (NOT separate ticked steps):
  1. Write tests for the base cases below
  2. Run - verify they fail on assertion mismatch (not Import/Module/Attribute
     error). If they crash, fix the bootstrap first
  3. Implement per signature + constraints
  4. Run - verify all pass

  Signature: `def function(input: str) -> Result`
  - Accept X, validate Y, return Z. Use `LibraryThing` for heavy lifting
  - Empty input returns `Result.empty()`

  Base cases:
  - `function("valid")` -> `Result(value="valid")`
  - `function("")` -> `Result.empty()`
  - `function(None)` raises `ValueError`

  Explore edge cases you find relevant (unicode, whitespace, large input).

  Green: `pytest exact/path/to/file.test.py -v` passes all cases.

- [ ] **Step 3: Optional commit checkpoint** (only if policy needs it)

  ```bash
  git add exact/path/to/file.py exact/path/to/file.test.py <this-plan-file>.md
  git commit -m "Add specific feature"
  ```

  Stage the plan file too, so its `- [x]` ticks commit with the task.

- [ ] **Final step (last task only): Run final verification**

  **Skills (load if not already loaded):** `verification-before-completion`

  Run the header's `Final verification` commands. Report results.
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

- Each step is one action: verifiable, reviewable, committable, ending green
- Every step ends with a `Green:` line = exact paste-able command + observable
  success token. No bare "compiles" / "tests pass" - name the command and what
  output proves it
- Red phases are activities INSIDE the green-producing step, never separate
  ticked steps
- GOOD: "Bootstrap stubs" (Green: `tsc --noEmit` -> `0 errors`)
- GOOD: "Implement <feature> with TDD" (Green: `pytest path -v` -> all pass)
- BAD: "Write the failing test" (leaves repo red, can't commit)
- BAD: "Run it, verify it fails" (red is interim, not a deliverable)
- TDD red must fail on assertion mismatch, not runtime/import/setup error. Crash
  -> fix bootstrap
- Describe intent + constraints, not full implementation. Agent writes the code

## Tracking

When executing from a plan file, flip `- [ ]` to `- [x]` immediately after
verifying each step. Do not batch at the end.

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

> **For agentic workers:** Execute task-by-task. Use `executing-plans` when
> working from a saved plan in a separate session. Steps use checkbox (`- [ ]`)
> syntax and must be marked complete immediately after each step is verified.
> Tick each checkbox the moment its step passes; never batch ticks at the end.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Commit policy:** [One commit per task | One commit at the end | No commits]

**Final verification:**

- [Commands the final reviewer runs after all tasks: full suite, type check,
  lint, build]

---
```

Skills are annotated per step, not in the header.

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

## Plan reviewer

After self-review, dispatch a plan-reviewer subagent once. Audits internal
quality only (contradictions, assumptions, ordering, granularity, reuse, blind
spots), NOT against an external spec. Categories live in
`plan-reviewer-prompt.md`.

Dispatch payload (do NOT load the template into your own context):

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
