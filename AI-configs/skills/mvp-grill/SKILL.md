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
2. Do not ask permission to read, search, fetch, or inspect
3. The human is a tie breaker, not a required step
4. If a standard, pattern, or reversible default decides, lock it
5. Ask at most one blocker per turn

## Mode gate

Choose mode after scope and before the first blocker.

1. If the user references a writable decision artifact, use target-file grill
2. If the target is source code, use patch-unit grill unless each answer maps to
   a small, valid edit
3. If no target file is referenced, use in-memory grill
4. If mode is ambiguous, ask once before **Q1**
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
7. Verify first, then ask. Never offer the user a choice between
   "verify X" and "skip X". If verification is cheap and reversible, do
   it before drafting the question.

### Forbidden question shapes

These patterns are lazy. Never emit them:

1. "Want me to verify <X> before deciding, or <skip>?"
2. "Should I check <X> first, or assume <Y>?"
3. "Do you want me to read/inspect/test <X>?"
4. "Confirm <X> first, or proceed?"

If you catch yourself drafting any of these, stop. Do the verification.
Then ask a real blocker, or close with a locked default.

## 1. Establish scope

Infer scope from the prompt and repository before asking. Ask only when the goal
or artifact remains unknowable after cheap inspection.

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
2. Apply existing project standard
3. Apply nearby implementation pattern
4. Apply industry default
5. Apply simplest reversible option
6. Lock obvious artifact boundaries
7. Park non-MVP branches

Parking means defer visibly, not hide. Surface material parking-lot items in the
close report.

Implementation artifacts are not decision logs.

1. Put discussion, diagnostics, rejected options, and transient rationale in
   chat or an explicit plan/report
2. Write only durable instructions into skill files, docs, code, or config
3. Add rationale inside artifacts only when requested or required by local
   format

State locked defaults with evidence every session, before the first blocker and
in the close report. The user cannot see agent context, so visible state is part
of the contract.

```markdown
Defaults locked:

- <decision> - <source or rationale>
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
- Good: inspect the API, then lock the fact: `API shape is <X> - source:
  <path:line>`
- Bad: "Want me to check existing tests first?"
- Good: read the tests, then ask only if behavior still depends on intent
- Bad: "Should I write this into the target file now?"
- Good: in target-file grill, apply the locked answer immediately
- Bad: "Should I ask the next blocker?"
- Good: ask the next blocker when one remains

## 5. Ask only blockers

Ask one question at a time. Recommend first. Ask for override second.

Before each question, maintain the open blocker queue internally. If blockers
were added, removed, or reprioritized since the last turn, show the
state-change block before the next question.

Do not show state-change blocks just to prove bookkeeping.

1. Use yes/no for one recommended path
2. Use lettered options for two or more peer paths
3. Drop options with no plausible MVP reason
4. Include the real tradeoff in one line

Format:

```markdown
---

**Q<n>**: <blocking decision>? (<answer format>)

Recommendation: <answer>. Tradeoff: <real cost>.
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
2. List locked defaults and decisions
3. List parking-lot items only when present
4. Give concrete verification
5. End with `Next`
6. Name the real next action from the ladder below
7. Apply Mode gate write rules to any `Next` write action

### Next action ladder

Pick the next action before asking.

1. If blockers are resolved, report the locked final state in chat
2. If implementation is requested and no patch exists, recommend applying the
   patch
3. If a target file was requested but target-file mode was not active,
   recommend writing that file
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

- <goal>
- <default or decision>

Parking lot:

- <deferred item>

Verify:

- <check>

Next:

- <context-specific call to action>
```

Omit empty sections.

If one next action is recommended, ask yes/no. If two or more next actions are
viable peer paths, use lettered options and recommend one.

Do not end silently after the report. `Next` is mandatory, even for small
sessions.
