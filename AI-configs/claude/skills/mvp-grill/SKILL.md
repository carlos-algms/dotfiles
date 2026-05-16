---
name: mvp-grill
description: >
  Fast, MVP-focused grilling session for plans, prototypes, designs, or feature
  ideas. Use when the user wants to stress-test direction, clarify assumptions,
  reduce scope, or get challenged without a long decision-tree interview.
---

# MVP grill

Goal: reach the fastest valid path to a solution without hidden assumptions.

## Invariants

These rules override the rest of the flow.

1. Do not edit files during the grill
2. Deliver the final report before any write action
3. Ask for confirmation with the real next action before writing
4. Do not ask permission to read, search, fetch, or inspect
5. The human is a tie breaker, not a required step
6. If a standard, pattern, or reversible default decides, lock it
7. Ask at most one blocker per turn

## Modal gate

Run this before every user-facing question, report, or recommendation.

1. Scan for `should`, `might`, `could`, and `maybe`
2. Treat each match as missing evidence or an unmade decision
3. Resolve it through reading, searching, fetching, or deciding
4. Emit only verified facts, locked defaults, or real blockers
5. Never turn exploration permission into a grill question

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
9. Search GitHub issues and PRs when upstream behavior matters
10. Read similar project patterns or prior code
11. Stop when more reading will not change the MVP path

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

Artifact boundary default:

1. Put analysis, diagnostics, tradeoffs, and decisions in chat, reports, plans
   or docs.
2. Keep implementation artifacts minimal and clean
3. Add rationale inside implementation artifacts only when requested or whe
   project convention requires it.

State locked defaults with evidence:

```markdown
Defaults locked:

- <decision> - <source or rationale>
```

Use `<path:line>` for code when available. Use docs URLs for docs. Use
`project pattern` or `industry default` when no citation exists.

## 4. Gate questions

Questions are for steering and tie breaks only.

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

Time cost is not a user question unless the user set a strict budget.

## 5. Ask only blockers

Ask one question at a time. Recommend first. Ask for override second.

1. Use yes/no for the recommended path
2. Use lettered options only for three or more viable paths
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
2. Remove questions made moot
3. Add a question only if the answer creates a new MVP blocker
4. Keep parking-lot items closed unless the user reopens them

Ack format:

```markdown
**Q<n>** locked: <decision>.
```

## 7. Close and request action

Close when the MVP path is clear, not when every possible branch is resolved. No
file edits before this report and the user's confirmation.

1. State the MVP goal
2. List locked defaults and decisions
3. List parking-lot items only when present
4. Give concrete verification
5. Name the real next action: patch, plan, edit, apply, draft, implement, test
   or similar.
6. Ask for confirmation before any file edit

Close with:

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

If one next action is recommended, ask yes/no. If three or more next actions are
viable, use lettered options and recommend one.
