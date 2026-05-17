---
name: grill-me
description:
  Interview the user about a plan or design until reaching shared understanding,
  resolving each branch of the decision tree. Use when user wants to stress-test
  a plan, get grilled on their design, or mentions "grill me".
---

Interview the user on every branch of the design tree, resolving dependencies
one-by-one. For each question, recommend an answer. Prove facts when you can
(Glob/Grep/Read, WebFetch, WebSearch, `--help`, library source). Otherwise ask.

Bias toward visible progress over perfect protocol. Exhaustive means every
material decision, not every implementation detail.

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

1. Classify every uncertainty as fact, default, or branch
2. Resolve facts through reading, searching, fetching, or inspecting
3. Lock defaults through standards, project patterns, or reversible choices
4. Ask branches that need human intent, preference, or accepted tradeoff
5. Emit only verified facts, visible defaults, or real branches
6. Never turn exploration permission into a grill question
7. Verify first, then ask. Never offer the user a choice between "verify X" and
   "skip X". If verification is cheap and reversible, do it before drafting the
   question.

### Forbidden question shapes

These patterns are lazy. Never emit them:

1. "Want me to verify <X> before deciding, or <skip>?"
2. "Should I check <X> first, or assume <Y>?"
3. "Do you want me to read/inspect/test <X>?"
4. "Confirm <X> first, or proceed?"
5. "Should I continue?"
6. "Should I ask the next question?"

If you catch yourself drafting any of these, stop. Do the verification, ask the
next branch, or close with the final state.

## Pre-grill self-assessment

Runs ONCE, internally, before the Opener. Goal: reduce user cognitive load by
resolving what you can yourself. Never assume code exists, signatures match, or
docs are unchanged - verify.

**Hard rule: technical facts are NEVER questions for the user.** API signatures,
type definitions, return values, function arity, CLI flags, env var names, file
paths, config schema, library version behavior, error codes - all of these MUST
be answered by reading code or docs. Asking the user for a fact you could grep
in 10 seconds is a failure. If the fact is in the repo or in upstream docs, find
it. If it's not, state where you looked and that it's unresolvable.

Steps:

1. List the recommendations you would make right now, without input.
2. For each, surface every unknown:
   - Assumptions (silent defaults, mental models).
   - Code you would call, reuse, or extend (helpers, classes, types, hooks).
   - Unread code signatures.
   - Blast radius: callers (transitively), callees, consumers (importers,
     subclasses, tests, public API).
   - Existing patterns or prior art in this repo.
   - External limits (rate limits, quotas, auth scopes, API/lib versions,
     schemas, file formats, CLI flags).
   - Docs you're relying on from memory.
3. Explore until each item is resolved or confirmed unresolvable without the
   user.
   - Code: Glob, Grep, Read. Find existing impls, call sites, types, tests.
   - Docs: read the actual file/page now (memory is stale by default). For
     external libs/CLIs, invoke `--help`, read source, or fetch current docs.
   - Repo conventions: scan neighbors, sibling modules, recent commits.
4. Triage every candidate branch before promoting it. For each, all three must
   hold to become a branch:
   - User's input could change the outcome (not just confirm it).
   - Decision isn't already determined by an upstream choice the user made (e.g.
     "use this module" implies "call its API").
   - Rejecting the obvious answer has a real cost a reasonable engineer would
     weigh (not "one more import", "slightly more code", or other non-costs).

   Fail any check:
   - **Fact or reversible default picks the answer**: lock visibly with
     evidence. Not a branch.
   - **Worth visibility**: emit as info-only note
     (`Note: <decision> - <one-line rationale>`), not a question.

Bias toward reducing fake questions, not reducing meaningful decisions.
Reverse-engineering implementation steps into binary questions is filler. If you
cannot name a real cost for rejecting the obvious answer, the question does not
exist.

## Opener

Emit a numbered list of branches. Lets the user spot missing branches and refer
to subsets. Do not wait for confirmation before **Q1** unless the branch set
itself is ambiguous.

Before **Q1**, show `Locked facts` when the branch queue or recommendation
depends on repo, docs, API, CLI, or external facts. Keep it to material facts
only. Omit it when the grill is purely preference, product, or design.

Show the queue only when it adds visibility:

```markdown
Locked facts:

- <fact> - source: <path:line or doc URL>

Branches to grill:

1. `<topic>`
2. `<topic>`
```

Then proceed to **Q1** in the same response.

## Subset selection

User invokes grill-me on a subset ("grill me on 2, 3, 5"): ack the subset on the
first turn, state locked items inline, ONLY open branches for requested items.
Never treat silence as acceptance.

```markdown
Locked (no grilling): <list of accepted items with one-line summary each>.

Branches to grill:

1. <subset topic>
2. <subset topic>
```

User later asks to grill a locked item: reopen it as a new top-level Q, appended
after the last.

## Format

One question per turn. Numbered **Q1**, **Q2**... sequentially. Never reuse,
skip, or reorder **Q<n>** ids. Render `Q<n>` bold everywhere, including the
header line.

Prepend `---` before every **Q<n>** as visual divider.

Per-turn structure, back-to-back, no prose between blocks:

1. Optional cascade / count-change block (only on count change).
2. Optional Ack of prior answer (one line).
3. New Q block:
   - **Q<n>** line - the decision being grilled.
   - Optional description, only if options aren't self-sufficient.
   - Should this be a question at all? If a fact or reversible default picks the
     answer and user input doesn't change the outcome, it's not a Q. Lock it
     visibly with evidence or emit an info-only note.
   - Options. Never invent filler. Each option must be a plausible best choice
     for some reader. Drop options dominated on every axis or with no plausible
     reader. Two cases:
     - 1 real path: ask yes/no (`Apply X? (y/n)`). No labels, no recommendation.
     - 2+ real paths: bulleted, no header. Bold label, blank line between,
       one-line tradeoff each.
   - `Recommendation:` line - the only inline label permitted.

Example:

```markdown
---

**Q3**: should we cache responses?

- **A**: in-memory, 5min TTL - simplest, lost on restart

- **B**: redis, 1h TTL - survives restart, adds dep

Recommendation: **A**. Tradeoff: cache lost on restart.
```

### Recommendation line

`Recommendation: <choice>.` Optionally followed by `Tradeoff: <...>` or
`Caveats: <...>` when there's a meaningful one. Skip when the recommendation is
clean.

If you can't pick a recommendation, you haven't explored enough - go back.

## Answers found in code

Facts found in code are locked by citation. Announce the lock, do not ask to
re-confirm.

`**Q<n>** locked by code: <answer> - source: <path:line>.`

Ask one yes/no only if adopting the found fact changes the user's intent (they
want to override what the code currently does).

## Revisits

User asks to go back to **Q<m>**:

1. Stash current open **Q<n>** as resume target.
2. Reopen **Q<m>**, ack new answer.
3. `Resuming **Q<n>**:` then re-render the question block.

Downstream questions reopen only if the new answer invalidates them. List
changes in the count-change block.

Revisits follow the same flow: stash, reopen, resume.

## Mid-grill exploration

Pre-grill is not the only time to read code or docs. Between any two questions,
if a technical fact is needed (signature, type, flag, behavior), STOP and verify
before emitting the next Q. Never chain-ask through unknowns to keep momentum.

Triggers to pause and explore:

- About to ask the user a fact you could grep, read, or fetch.
- Recommendation depends on a signature, type, or API contract you have not
  read.
- User's last answer references code you have not opened.
- Cascade check flags a question whose premise depends on unverified behavior.

Resume only after the unknown is resolved or confirmed unresolvable. The cost of
a 30s pause is lower than the cost of grilling on a wrong premise.

## New questions from findings

Any finding that grows the open count must be announced before the next
question.

Append every new branch as the next top-level **Q** after the last. Never insert
mid-sequence. If a finding blocks the current question, ask the new **Q** next.

```markdown
**Q<n>** answer opens new branches:

- **Q<m>**: <one-line question>
- **Q<m+1>**: <one-line question>
```

## Acknowledging answers

After the user answers, single line before the next **Q<n>**:

```markdown
**Q<n>** locked: <one-sentence summary>.
```

Use the same ack in target-file grill. Do not include paths in per-question
acks. Tool output carries edit visibility.

### Cascade check after every answer

After every ack, scan all still-open questions. For each: "does the just-locked
answer make this question moot, redundant, or invalidate its premise?"

If yes, emit the count-change block before asking the next question.

## Branch changes

Show ONLY when branches are added, removed, or merged. A normal answer that
locks one and moves on is NOT a branch change.

```markdown
Updated branches:

- Removed: **Q3** - moot after **Q2**
- Merged: **Q5** into **Q4** - same decision
- Added: **Q8** - surfaced by **Q2**
```

Omit empty sections. Skip the block on no-change turns.

## Closing the session

When you think the tree is resolved, do NOT ask the user "any open branches?" -
detecting open branches is your job.

Self-audit before closing:

1. Check assumptions, deferred decisions, and unopened branches
2. Re-verify locked facts that name files, functions, flags, formats, or
   external behavior
3. Check locked decisions for contradictions, invalidations, or new branches

For every finding:

- **Verifiable by tool** (signature, type, flag, file content, doc): resolve by
  reading code or docs, then re-lock with citation. Do NOT ask the user a fact
  you can grep. Announce:
  `**Q<n>** re-locked by code: <answer> - source: <path:line>.`
- **Intent or preference**: surface as a new Q, grill before closing.

Never silently adjust either way.

If any pass surfaces anything, list every open branch and keep grilling:

```markdown
Open branches found:

- **Q<n>**: <one-line question or uncertainty>
- **Q<m>**: <one-line question or uncertainty>
```

When the audit comes back empty:

```markdown
Grill locked:

- <decision or default>
- <decision or default>

Parking lot:

- <deferred item>

Verify:

- <check>

Next:

- <context-specific next action>
```

Omit empty sections. `Next` is mandatory. Pick the next action before asking.
Never ask "what should I do next" when the prompt, repo state, or workflow
implies a default.

## Style

Skill-specific deltas on top of global terse-mode:

- Explored to answer your own question: state finding and move on.
- No recap, no restating the plan between turns.
- Stop when branches resolved. No end-summary unless asked.
