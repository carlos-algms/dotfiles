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

## Pre-grill self-assessment

Runs ONCE, before the Opener. Goal: reduce user cognitive load by resolving what
you can yourself. Never assume code exists, signatures match, or docs are
unchanged - verify.

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
   - **MVP/good practice picks the answer**: resolve silently, collapse into the
     recommendation. Not a branch.
   - **Worth visibility**: emit as info-only note
     (`Note: <decision> - <one-line rationale>`), not a question.

Bias toward reducing user cognitive load. Reverse-engineering implementation
steps into binary questions is filler. If you cannot name a real cost for
rejecting the obvious answer, the question does not exist.

Output before the Opener:

```markdown
Pre-grill assessment:

Explored:

- <path:line or doc URL> - <one-line takeaway>

Resolved (no longer a branch):

- <assumption / unknown> - <answer found, source>

Still unknown (becomes a branch):

- <item> - <why it needs the user>
```

Empty sections allowed but state them ("Explored: none - reason"). Silent
omission = laziness signal.

## Opener

Emit a flat list of branches. No numbers. Lets the user spot missing branches up
front.

`Branches to grill:`

- `<topic>`
- `<topic>`

Wait for confirm/extend, then proceed to **Q1**.

## Subset selection

User invokes grill-me on a subset ("grill me on 2, 3, 5"): ack the subset on the
first turn, state locked items inline, ONLY open branches for requested items.
Never treat silence as acceptance.

```markdown
Locked (no grilling): <list of accepted items with one-line summary each>.

Branches to grill: <subset topics>
```

User later asks to grill a locked item: reopen it as a new top-level Q, appended
after the last.

## Format

One question per turn. Numbered **Q1**, **Q2**... sequentially. Never reuse,
skip, or reorder top-level Qs (sub-Qs `Q<n>.1` are the explicit exception, see
"New questions from findings"). Render `Q<n>` bold everywhere, including the
header line.

Prepend `---` before every **Q<n>** as visual divider.

Per-turn structure, back-to-back, no prose between blocks:

1. Optional cascade / count-change block (only on count change).
2. Optional Ack of prior answer (one line).
3. New Q block:
   - **Q<n>** line - the decision being grilled.
   - Optional description, only if options aren't self-sufficient.
   - Should this be a question at all? If MVP + good practice picks the answer
     and user input doesn't change the outcome, it's not a Q. Emit info-only
     note or resolve silently (see Pre-grill step 4).
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

Downstream questions reopen only if the new answer invalidates them - list in
count-change block as `+` re-added or `⊘` moot.

Revisits to sub-Qs (`Q<n>.1`) follow the same flow: stash, reopen, resume.

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

- Blocks the next top **Q**: sub-questions `Q<n>.1`, `Q<n>.2`, ... resolved
  depth-first. Nest on further drift (`Q3.1.1`).
- Independent: appended as new top **Q**s after the last. Never insert
  mid-sequence.

```markdown
**Q<n>** answer opens new branches:

- **Q<n>.1**: <one-line question>
- **Q<n>.2**: <one-line question>
- **Q<m>**: <one-line question> (appended)
```

## Acknowledging answers

After the user answers, single line before the next **Q<n>**:

```markdown
**Q<n>** ✓ <one-sentence summary>
```

Target-file mode (see below): append `- updated <path>` to the ack.

### Cascade check after every answer

After every ack, scan all still-open questions. For each: "does the just-locked
answer make this question moot, redundant, or invalidate its premise?"

If yes, emit the count-change block marking those questions `⊘` BEFORE asking
the next question.

## Question count (only on count change)

Show ONLY when open count changes (added, moot, merged). A normal answer that
closes one and moves on is NOT a count change.

Icons: `✦` retroactively closed by prior answer, `⊘` moot, `⇢` merged, `+` new.
(`✓` is reserved for the per-turn ack line.)

```markdown
Resolved:

- **Q7** ✦ (short question) - answered by **Q1**
- **Q3** ⊘ (short question) - moot after **Q2**
- **Q5** ⇢ **Q4** - merged, same decision

Added:

- **Q8** + (short question) - source: <what surfaced it>

Still open: <N>
```

Omit empty sections. Skip the block on no-change turns.

## Target file vs. in-memory

Detect at session start. If unsure, ask once then commit.

- **Target file**: user points at a file. Apply each answer immediately via
  Edit, never batch.
- **In-memory**: no file. Conversation only. Do NOT re-summarize the running
  plan after each answer - the ack line is the only persistence.

## Closing the session

When you think the tree is resolved, do NOT ask the user "any open branches?" -
detecting open branches is your job.

Self-audit before closing - THREE passes:

**Pass 1: transcript-internal**

- Assumptions made without confirmation
- Deferred decisions ("we'll revisit", "later")
- Sub-questions that opened but never got asked
- Recommendations the user accepted with caveats

**Pass 2: re-verify locked facts**

For each locked decision that names a file, function, flag, format, or external
CLI behavior, verify it still holds NOW (same rule as the opener: prove facts
when you can).

**Pass 3: pairwise cross-check between locked decisions**

For every pair (Q<i>, Q<j>):

- **Conflict**: do they contradict?
- **Invalidation**: does one make the other moot? (Earlier moot detection missed
  it - flag.)
- **New branch**: does the combination open a question neither addresses?
- **Shared surface**: do both touch the same file/state and need coordinated
  edits?

For every finding:

- **Verifiable by tool** (signature, type, flag, file content, doc): resolve by
  reading code or docs, then re-lock with citation. Do NOT ask the user a fact
  you can grep. Announce: `**Q<n>** re-locked by code: <answer> - source:
  <path:line>.`
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
---

Audit clean: no open branches, assumptions, or deferred items.

Draft now? (y/n)
```

## Style

Skill-specific deltas on top of global terse-mode:

- Explored to answer your own question: state finding and move on.
- No recap, no restating the plan between turns.
- Stop when branches resolved. No end-summary unless asked.
