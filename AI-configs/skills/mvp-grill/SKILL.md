---
name: mvp-grill
description: >
  Fast, MVP-focused grilling session for plans, prototypes, designs, or feature
  ideas. Use when the user wants to stress-test direction, clarify assumptions,
  reduce scope, or get challenged without a long decision-tree interview.
---

# MVP grill

Goal: reach the fastest valid path to a solution without hidden assumptions.

MVP means the smallest useful delivery for the current ask: code, docs, plan,
decision, command, design, purchase recommendation, or other artifact.

Bias toward visible progress over perfect protocol.

## Invariants

These rules override the rest of the flow.

1. Choose grill mode before the first blocker
2. Do not ask permission to read, search, fetch, inspect, or test
3. Before any user-facing question, at any time, resolve factual uncertainty by
   reading, searching, fetching, inspecting, or testing
4. Never ask whether to verify, inspect, read, test, assume, skip, or proceed
5. The human is a tie breaker, not a required step
6. If a standard, pattern, or reversible default decides, lock it
7. Ask at most one blocker per turn

## Mode gate

Choose mode after scope and before the first blocker.

1. If the user references a writable decision artifact, use target-file grill
2. If the target is source code, use patch-unit grill unless each answer maps to
   a small, valid edit
3. If no target file is referenced, use in-memory grill
4. If mode is ambiguous, ask once before the first blocker question
5. Mode choice authorizes only writes implied by that mode and target
6. Destructive, broad, or off-target writes still require confirmation

Modes:

- **Target-file grill**: each locked answer updates the target file immediately
- **In-memory grill**: final state stays in chat, no file edits during grill
- **Patch-unit grill**: collect decisions until the smallest coherent patch is
  clear, then ask before applying it

Target-file mode authorizes edits that apply locked answers to the target file.
Do not ask permission before those edits. Ask only for destructive, broad,
off-target, or unrelated writes.

## Uncertainty gate

Run this before every user-facing question, report, or recommendation.

1. Classify every uncertainty as fact, default, or blocker
2. Resolve facts through reading, searching, fetching, or inspecting
3. Lock defaults through standards, project patterns, or reversible choices
4. Ask only blockers that need human intent or preference
5. Emit only verified facts, locked defaults, or real blockers
6. Never turn exploration permission into a grill question
7. Verify before any question, at any time. Never offer the user a choice
   between "verify X" and "skip X". If verification is possible without
   destructive action, do it before drafting the question.

### Forbidden question shapes

These patterns are lazy. Never emit them:

1. "Want me to verify <X> before deciding, or <skip>?"
2. "Should I check <X> first, or assume <Y>?"
3. "Do you want me to read/inspect/test <X>?"
4. "Confirm <X> first, or proceed?"

If you catch yourself drafting any of these, stop. Do the verification. Then ask
a real blocker, or close with a locked default.

## 1. Establish scope

Infer scope from the prompt and repository before asking. Ask only when the goal
or artifact remains unknowable after inspection.

1. Identify the MVP outcome in one line
2. Identify the target artifact: code, docs, plan, command, config, or design
3. Capture explicit user constraints
4. Capture explicit non-goals
5. Ask one intake question only when scope remains unknowable

## 2. Explore authoritative sources

Know facts before recommending or asking. Exploration is agent work.

1. Read target files
2. Read immediate neighboring files
3. Read system-under-test source when tests are involved
4. Read signatures, types, schemas, config, and call sites
5. Read existing tests when behavior or coverage matters
6. Read existing docs and ADRs when present
7. Read current API, CLI, or library docs when external behavior matters
8. Web search or fetch when current external facts matter
9. Go upstream without asking when the issue may be an external bug, library
   limitation, undocumented behavior, or current behavior
10. Search GitHub issues and PRs when codebase research is inconclusive and
    upstream behavior affects the recommendation
11. Read nearby project patterns or prior code
12. Stop when more reading will not change the MVP path

Ask before exploration only when it requires destructive action, missing access,
paid calls, or scope expansion beyond the MVP.

## 3. Lock defaults

Defaults are decisions. Do not ask the user to confirm them.

1. Apply explicit user goal
2. Apply project mandate (AGENTS.md, CLAUDE.md, contributing guide, ADR). These
   are locked, never asked. Cite path
3. Apply existing project standard
4. Apply nearby implementation pattern
5. Apply industry default
6. Apply simplest reversible option
7. Lock obvious artifact boundaries
8. Park non-MVP branches

Parking means defer visibly, not hide. Surface material parking-lot items in the
close report.

Implementation artifacts are not decision logs.

1. Put discussion, diagnostics, rejected options, and transient rationale in
   chat or an explicit plan/report
2. Write only durable instructions into skill files, docs, code, or config
3. Add rationale inside artifacts only when requested or required by local
   format

State locked defaults with evidence every session, before the first blocker and
in the close report. Number locked items so the user can respond by number. The
user cannot see agent context, so visible state is part of the contract.

```markdown
Defaults locked:

1. <decision> - <source or rationale>
```

Use `<path:line>` for code when available. Use docs URLs for docs. Use
`project pattern` or `industry default` when no citation exists.

## 4. Gate questions

Questions are for steering and tie breaks only.

Facts are not blockers. If code, docs, CLI help, schema, tests, current web
docs, or upstream issues can answer it, inspect those sources before asking.
Only ask when the remaining uncertainty is intent, preference, scope, or
accepted tradeoff.

Ask only when all three checks pass:

1. The answer changes the MVP outcome
2. A wrong choice creates material rework, risk, or product mismatch
3. No project pattern, industry standard, or reversible default decides it

Do not ask about:

1. File names
2. Helper extraction
3. Import style
4. Naming with an obvious local convention
5. Library choice already settled by the project
6. Implementation details the agent can verify
7. Whether to inspect authoritative sources
8. Preferences that do not affect MVP behavior
9. A locked default restated as a confirmation question
10. Permission to read files, docs, web pages, issues, or PRs
11. Whether to continue, ask the next question, or apply the selected mode

Time cost is not a user question unless the user set a strict budget.

### Anti-examples

- Bad: "Should I inspect the API before deciding?"
- Good: inspect the API, then lock the fact:
  `API shape is <X> - source: <path:line>`
- Bad: "Want me to check existing tests first?"
- Good: read the tests, then ask only if behavior still depends on intent
- Bad: "Should I write this into the target file now?"
- Good: in target-file grill, apply the locked answer immediately
- Bad: "Should I ask the next blocker?"
- Good: ask the next blocker when one remains

## 5. Ask only blockers

Ask one question at a time. Recommend first. Ask for override second.

Before each question, maintain the open blocker queue internally. If blockers
were added, removed, or reprioritized since the last turn, show the state-change
block before the next question.

Do not show state-change blocks just to prove bookkeeping.

1. Use yes/no for one recommended path
2. Use lettered options for two or more peer paths
3. Drop options with no plausible MVP reason
4. Drop options that violate a locked default, project mandate, or invariant.
   Never add a forbidden path as a balance option. If only one path remains
   valid, lock it instead of asking
5. Include a tradeoff only when one exists

Tradeoff means a concrete cost: bug risk, visual or behavioral regression,
revert or undo cost, performance impact, lock-in, or data loss. A tradeoff is
not a restatement, summary, or explanation of the option. Omit the tradeoff line
when the option is self-explanatory or no real cost exists.

Anti-examples:

- Bad: "Tradeoff: 2 small tests" (restates option)
- Bad: "Tradeoff: adds a helper function" (restates option)
- Good: "Tradeoff: breaks existing callers of `foo()`, needs grep+update"
- Good: "Tradeoff: extra render on every keystroke"

Format:

```markdown
---

**Q<n>**: <blocking decision>? (<answer format>)

Recommendation: <answer>. Tradeoff: <real cost, omit if none>.
```

## 6. Handle answers

Each answer shrinks the decision set.

1. Lock the answered decision
2. Re-scan every open blocker
3. Remove questions made moot, redundant, or invalid by the answer
4. Add a question only if the answer creates a new MVP blocker
5. Keep parking-lot items closed unless the user reopens them
6. In target-file grill, apply the durable part of the answer immediately
7. Show visible state changes before the next question
8. Do not duplicate successful edit tool output in chat

Ack format:

```markdown
**Q<n>** locked: <decision>.
```

Use the same ack in target-file grill. Do not include paths in per-question
acks. Tool output carries edit visibility.

State-change format:

```markdown
Updated blockers:

- Removed: <question> - <why>
- Added: <question> - <why>
- Still open: <count>
```

Omit the state-change block when the answer only locks the current question.
Show it only when the open blocker set changed.

Bad state-change block:

```markdown
Updated blockers:

- Still open: 3
```

Good: omit the block when no blocker was added, removed, or reprioritized.

## 7. Close and request action

Close when the MVP path is clear, not when every possible branch is resolved.

Required close content:

1. State the MVP goal
2. List locked defaults and decisions as numbered items
3. List parking-lot items only when present
4. Emit a step-by-step plan as a numbered list with sub-lists. Any agent must be
   able to execute it with no prior context
5. Give concrete verification
6. End with `Next`
7. Name the real next action from the ladder below
8. Apply Mode gate write rules to any `Next` write action

### Plan format

The plan is a numbered list. Each step is one action. Sub-steps are a nested
numbered list under their parent. Each step or sub-step ends with
`-> verify: <check>` when verifiable.

Reference: see Karpathy goal-driven execution rules in user CLAUDE.md.

```markdown
Plan:

1. <step> -> verify: <check>
   1. <sub-step> -> verify: <check>
   2. <sub-step> -> verify: <check>
2. <step> -> verify: <check>
```

### TDD mandatory when tests exist

If the project contains tests (any test runner, fixture dir, or test file
pattern detected during exploration), TDD red/green is mandatory in the plan.
Not optional. Not "if time permits".

Required structure when TDD applies:

1. Bootstrap step: create stubs, imports, fixtures, types so the test can run
   without runtime, compile, import, or reference errors -> verify: test file
   loads, target symbol resolves
2. Red step: write the assertion, run the test, confirm it fails for the right
   reason -> verify: failure reason is value/behavior mismatch, not
   `ReferenceError`, `TypeError`, `ModuleNotFound`, syntax error, missing file,
   "element not found", null ref before assertion, or compile error
3. Green step: minimum code to pass -> verify: target test passes
4. Regression step: run full suite -> verify: no regressions

Wrong-reason failures are not red. If the red step fails for a bootstrap reason,
the plan loops back to step 1 before proceeding to green. Never patch the
assertion to dodge a wrong-reason failure.

No test infra detected: state that explicitly in the plan and ask before adding
it. Do not silently skip TDD by claiming "no tests".

### Next action ladder

Pick the next action before asking.

1. If blockers are resolved, report the locked final state in chat
2. If implementation is requested and no patch exists, recommend applying the
   patch
3. If a target file was requested but target-file mode was not active, recommend
   writing that file
4. If edits exist and validation has not run, recommend the most relevant check
5. If validation is done, recommend diff review
6. Recommend staging, committing, pushing, or PR creation only when the user
   asked for that git action or explicitly signaled shipping
7. Use options only when two or more peer next actions are equally valid

Never ask "what should I do next" when the prompt, repo state, or workflow
implies a default.

Default close shape:

```markdown
MVP locked:

1. <goal>
2. <default or decision>

Parking lot:

1. <deferred item the user may pick by number>

Plan:

1. <step> -> verify: <check>
   1. <sub-step> -> verify: <check>
2. <step> -> verify: <check>

Verify:

- <check>

Next:

- <context-specific call to action>
```

Omit empty sections except `Plan`. `Plan` is mandatory.

Use numbered lists for `MVP locked`, `Defaults locked`, `Plan`, and selectable
`Parking lot` items. Keep blocker choice options lettered.

If one next action is recommended, ask yes/no. If two or more next actions are
viable peer paths, use lettered options and recommend one.

Do not end silently after the report. `Next` is mandatory, even for small
sessions.
