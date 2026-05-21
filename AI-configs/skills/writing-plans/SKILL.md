---
name: writing-plans
description: >
  Use when you have a spec or requirements for a multi-step task, before
  touching code
---

# Writing plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context
for the codebase, toolset, and problem domain. Document everything they need to
know: which files to touch for each task, code, testing, docs they might need to
check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI.
TDD. Optional commit checkpoints.

Assume they are a skilled developer, but know almost nothing about our toolset
or problem domain.

**Announce at start:** "I'm using the writing-plans skill to create the
implementation plan."

## Plan location

Before writing the plan, choose where it lives.

- If already working in a plan file, ask before editing it to match this format.
  Preserve all original content unless the user explicitly approves removal.
- If not working in a plan file, ask whether the plan should stay in chat memory
  or be saved to `docs/plans/YYYY-MM-DD-<feature-name>.md`.
- Recommend `docs/plans/` for multi-session work. Recommend memory for short,
  disposable planning.

## Commit policy

Before writing the plan, ask how commits should be handled for the whole plan:

```markdown
How should commits be handled for this plan?

1. One commit per task
2. One commit at the end
3. No commits
```

Write the plan to match the selected policy. Do not make commits part of the
task structure unless the user selects a commit policy that needs them.

## Scope check

If the spec covers multiple independent subsystems, it should have been broken
into sub-project specs during brainstorming. If it wasn't, suggest breaking this
into separate plans — one per subsystem. Each plan should produce working,
testable software on its own.

## File structure

Before defining tasks, map out which files will be created or modified and what
each one is responsible for. This is where decomposition decisions get locked
in.

- Design units with clear boundaries and well-defined interfaces. Each file
  should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are
  more reliable when files are focused. Prefer smaller, focused files over large
  ones that do too much.
- Files that change together should live together. Split by responsibility, not
  by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large
  files, don't unilaterally restructure - but if a file you're modifying has
  grown unwieldy, including a split in the plan is reasonable.
- Before locking in new code, search the codebase for existing components,
  helpers, utilities, and shared features that do what you need. Reuse is
  mandatory - importing a shared `Button` beats creating one inline. Extend an
  existing helper before writing a new one. Only create new code when nothing
  reusable exists.

Prefer surgical edits to existing files. Apply single-responsibility: each
component/module/function does one thing. Don't bundle unrelated changes into a
task because they touch nearby code.

This structure informs the task decomposition. Each task should produce
self-contained changes that make sense independently.

## Bite-sized task granularity

**Each step is one action (2-5 minutes):**

- "Bootstrap stubs so tests can run" - step
- "Write the failing test" - step
- "Run it - verify it fails on the assertion, not on missing files/imports" -
  step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step

**TDD Red/Green done right:** Tests must fail because the assertion doesn't
match, never because of runtime errors, missing files, unresolved imports, or
undefined symbols. Before writing tests, create the minimum boilerplate needed
for the test to _run_: empty files, stub exports, type scaffolds. The red phase
proves the test checks the right thing. If the test crashes instead of failing
an assertion, the red phase is broken - fix the bootstrap first.

Implementation steps describe _what_ to build and _why_, not the literal code.
The executing agent is a skilled developer - give them constraints and intent,
let them write the code.

Commit is not a required task step. Include optional commit checkpoints only
when the user selects one commit per task or one commit at the end.

## Tracking

When executing from a plan file, update each checkbox from `- [ ]` to `- [x]`
immediately after completing and verifying that step. Do not batch checkbox
updates at the end.

## Plan document header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Execute task-by-task. Use `executing-plans` when
> working from a saved plan in a separate session. Steps use checkbox (`- [ ]`)
> syntax for tracking and must be marked complete immediately after each step is
> verified.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task structure

````markdown
### Task N: [Goal-oriented title - what this achieves, not what files it touches]

**Goal:** [One sentence: what works after this task that didn't before]

**Files:**

1. `exact/path/to/file.py`
   - Create `function()` that validates input and returns `Result`
   - Re-use `LibraryThing` from `exact/path/to/lib.py`
   - Import `BaseError` from `exact/path/to/errors.py`
2. `exact/path/to/existing.py:123-145`
   - Add `function` to the public API exports
   - Needed so downstream modules can import it
3. `exact/path/to/file.test.py`
   - Covers `function()` base cases + edge cases

- [ ] **Step 1: Bootstrap stubs**

Create `exact/path/to/file.py` with:

- `Result` class/type (empty or minimal)
- `function()` stub that raises `NotImplementedError` or returns a wrong default

This ensures tests can import and run without crashes.

- [ ] **Step 2: Write failing tests for `function`**

Test file: `exact/path/to/file.test.py`

Base cases:

- `function("valid")` returns `Result(value="valid")`
- `function("")` returns `Result.empty()`
- `function(None)` raises `ValueError`

Explore and add edge cases you find relevant (unicode, whitespace, large input).

- [ ] **Step 3: Run tests, verify they fail on assertions**

Run: `pytest exact/path/to/file.test.py -v` Expected: FAIL - assertion mismatch
(stub returns wrong value). NOT import errors, `ModuleNotFoundError`, or
`AttributeError`. If tests crash instead of failing assertions, fix the
bootstrap first.

- [ ] **Step 4: Implement `function`**

Signature: `def function(input: str) -> Result`

- Accept X, validate Y, return Z
- Use `LibraryThing` for the heavy lifting
- Constraint: must handle empty input by returning `Result.empty()`

- [ ] **Step 5: Run tests, verify they pass**

Run: `pytest exact/path/to/file.test.py -v` Expected: PASS (all cases including
any edge cases you added)

- [ ] **Step 6: Optional commit checkpoint**

Remove this step if the selected commit policy is `One commit at the end` or
`No commits`.

```bash
git add exact/path/to/file.py exact/path/to/file.test.py
git commit -m "Add specific feature"
```
````

## No ambiguity

Every step must be unambiguous - the engineer should never have to guess _what_
to build or _which_ constraints matter. But unambiguous does not mean
copy-paste-ready code.

These are **plan failures** - never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without listing what to test)
- "Similar to Task N" (repeat the content - the engineer may read tasks out of
  order)
- Vague instructions with no constraints ("build the component", "style it
  nicely")
- References to types, functions, or methods not defined in any task

These are **fine** - the engineer is skilled, let them work:

- Signature + bullet constraints instead of full function body
- "CSS Grid layout, sidebar fixed-width, content fills remaining" instead of a
  complete CSS file
- "A nav component with proper aria label and an h2 placeholder" instead of full
  JSX with exact markup
- Describing what a config needs to contain instead of the verbatim file

## Code detail calibration

**Full code:**

- Config files that are tricky to get right (tsconfig quirks, vitest setup)
- Type signatures, interfaces, and function signatures
- Shell commands with expected output

**Test lists, not test code:**

- List base cases with inputs and expected outputs
- List assertions that matter (roles, landmarks, states, text)
- Instruct the agent to explore and add edge cases they find relevant
- The agent writes the actual test code, setup, and assertions

**Instructions, not code** (the agent can derive it from test list +
signatures + constraints):

- Component/function bodies
- CSS/styles: describe layout intent (e.g. "horizontal flex, input fills
  remaining space"), not property values. Before picking values, search for
  existing CSS variables, design tokens, and helper classes (`.card`,
  `.section`, etc.) and re-use them
- Straightforward CRUD, wiring, glue code

When in doubt: write the signature + constraints + what to test. If the agent
can derive the implementation from the test list, don't write it.

## Remember

- Exact file paths always
- Test lists with base cases + "explore edge cases"; signatures for
  implementations; instructions for bodies
- Exact commands with expected output
- DRY, YAGNI, TDD, optional commit checkpoints
- Commit messages: bare imperative subject, no Conventional Commits prefix
  (`type(scope):`). Branches are squash-merged, so PR title carries the
  conventional format, not individual commits
- Test files collocated next to source: `Foo.test.tsx` beside `Foo.tsx`, no
  `__tests__/` folders
- Each component gets its own test file; don't pile tests into a parent's file
- Stubs must satisfy the tests but the plan doesn't prescribe their content
- Design decisions that affect test assertions (ARIA roles, landmarks, semantic
  HTML choices) must be locked in the plan. Styling details can be left open
- Same level of constraint detail for all steps of the same type (don't be
  precise on one CSS step and vague on the next)
- Package manager: detect from lock files (`pnpm-lock.yaml`, `yarn.lock`,
  `package-lock.json`, `bun.lock`) or `packageManager` field in root
  `package.json`. Use the detected runner in all commands (`pnpm exec`, `yarn`,
  `npx`, `bunx`). Never default to `npm`/`npx`. If undetectable, stop and ask

## Self-review

After writing the complete plan, look at the spec with fresh eyes and check the
plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point
to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns
from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you
used in later tasks match what you defined in earlier tasks? A function called
`clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Implementation leak scan:** Does any step contain a full function/component
body or full test code that the agent could derive from the constraints? Replace
implementation bodies with signature + bullet instructions. Replace test code
with a base-case list + "explore edge cases" instruction.

**5. Reuse scan:** Does any task create something that already exists in the
codebase? Search for existing components, helpers, hooks, utilities, and shared
modules before locking in new code. If a reusable piece exists, the plan must
import it, not recreate it. If it needs a small extension, extend it.

If you find issues, fix them inline. No need to re-review - just fix and move
on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two
execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task,
review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans,
batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**

- **REQUIRED SUB-SKILL:** Use subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**

- **REQUIRED SUB-SKILL:** Use executing-plans
- Batch execution with checkpoints for review
