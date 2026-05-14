---
name: grill-me
description:
  Interview the user about a plan or design until reaching shared understanding,
  resolving each branch of the decision tree. Use when user wants to stress-test
  a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly on every branch of the design tree, or the decision
making, resolving dependencies one-by-one. For each question, provide your
recommended answer. If a fact can be proven, prove it - Glob/Grep/Read on
the repo, WebFetch on a known URL, WebSearch for current docs, Bash to run
a CLI's `--help` or `--version`, or read library source. Otherwise ask.

## Pre-grill self-assessment

Runs ONCE, before the Opener. Goal: reduce user cognitive load. If you can find
the answer or clarify an assumption yourself, do it first. Never assume code
exists, signatures match, or docs are unchanged - verify.

Steps:

1. List the recommendations you would make right now, without input.
2. For each, surface:
   - Assumptions you are making (silent defaults, mental models).
   - Code you would call into, reuse, or extend (helpers, classes, modules,
     types, hooks).
   - Code signatures you have not actually read.
   - Blast radius - call chain up (who calls the function/component you touch,
     transitively), call chain down (what it calls), and consumers (importers,
     subclasses, test suites, public API surface). Changed line alone is not
     enough scope.
   - Existing patterns or prior art in this repo you have not searched for.
   - External limits unverified - rate limits, quotas, auth scopes, API version,
     schema, file format, library version, CLI flags.
   - Documentation you are relying on from memory - may be stale.
   - Unknowns the user has not stated.
3. Explore until each item is resolved or confirmed unresolvable without the
   user.
   - Code/helpers/classes: Glob, Grep, Read. Look for existing impls before
     proposing new ones. Find call sites, types, signatures, tests.
   - Docs: read the actual file/page now. Memory of docs is stale by default.
     For external libs/CLIs, invoke `--help`, read source, or fetch current
     docs.
   - Repo conventions: scan neighbors, sibling modules, recent commits.
4. Every still-unresolved item becomes a branch in the Opener. Resolved items
   collapse into the recommendation, not the branch list.

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

Only then proceed to the Opener with the expanded branch list.

## Opener

Before starting the grill session, emit a flat list of branches to grill. No
numbers yet - just topics, one line each. Lets the user spot missing branches up
front.

`Branches to grill:`

- `<topic>`
- `<topic>`

Wait for confirm/extend, then proceed to the first question.

## Subset selection

User invokes grill-me on a specific subset of items ("grill me on 2, 3, 5",
"only items 1 and 4", "skip the rest"): ack the subset on the first turn, state
the locked items inline, and ONLY open branches for the requested items. Do not
silently grill the full list.

Ack format:

```markdown
Locked (no grilling): <list of accepted items with one-line summary each>.

Branches to grill: <subset topics>
```

If the user mixes "agree" / "lock" / "yes" with specific numbers in their
trigger message, unmentioned items are out of scope unless user explicitly
accepts them. Never treat silence as acceptance.

## Format

One question per turn, numbered **Q1**, **Q2**... sequentially. Never reuse,
skip, or reorder - even after revisits, drifts, or merges. Render `Q<n>` bold
everywhere (prose, bullets, ack lines, status block).

Prepend `---` before every **Q<n>** to reset the markdown parser between turns
and create visual dividers.

Per-turn structure, back-to-back, no prose between blocks:

1. Optional cascade / count-change block (only on count change, see Question
   count section).
2. Optional Ack of prior answer (one line, see Acknowledging answers).
3. New Q block:
   - **Q<n>** line - the decision being grilled.
   - Optional description, only if options aren't self-sufficient.
   - Options. Never invent filler to hit a number. Two cases:
     - 1 real path: ask yes/no (`Apply X? (y/n)`). No labels, no
       recommendation.
     - 2+ real paths: bulleted, no header. Bold label, blank line between,
       one-line tradeoff each.
   - One-sentence `Recommendation:` line - the only inline label permitted.

Example:

```markdown
---

#### Q3: should we cache responses?

- **A**: in-memory, 5min TTL - simplest, lost on restart

- **B**: redis, 1h TTL - survives restart, adds dep

Recommendation: **A**. Heaviest cost: cache lost on restart.
```

Gather context first: read code, docs, web. Surface options the user hasn't
considered. If only one path visible, look harder or state why none exists.

### Recommendation line format

`Recommendation: <choice>. Heaviest cost: <the worst tradeoff you accept>.`

Never omit `Heaviest cost`. If you cannot name one, the option is dominated
and does not belong on the list (see Pre-emit option gate). Forces real
friction into every recommendation, blocks passive agreement.

### Pre-emit option gate

Before emitting an A/B/C block, run this check on each option:

1. Is there a plausible reader for whom this option is the best choice?
2. Does it dominate (or is dominated by) another option on every axis?
3. Was it added because the count "should" be 2-3, or because it's real?

Drop any option that fails #1 or is dominated on every axis per #2. Better to
ask a yes/no than to pad with strictly-worse alternatives.

Red flags during generation: "skip - already working", "padding item", "for
completeness", "marginal gain". If the rationale for an option includes those,
the option is filler. Cut it.

### Verify-before-recommend for external tools

When a recommendation references external CLI behavior, file-format specifics,
library semantics, or any claim that depends on a fact outside the conversation,
the recommendation MUST be backed by an actual tool invocation in the same
turn - not training-data recall.

Verification target depends on the claim type:

- Claim about a CLI flag or option: invoke the CLI's help or run it with the
  flag.
- Claim about file naming or output format: produce a sample output and inspect
  it.
- Claim about library behavior or version: read the relevant source or doc, or
  write a probe.

If verification is impractical (slow, network-dependent, destructive), say so in
the recommendation: `Recommendation: A (assumed; verify with X)`.

## Answers found in code

Facts found in code are locked by citation. Announce the lock, do not ask to
re-confirm.

`**Q<n>** locked by code: <answer> - source: <path:line>.`

Ask one yes/no only when adopting the found fact changes the user's intent
(e.g. they want to override what the code currently does).

## Revisits

User asks to go back to **Q<m>**:

1. Stash current open **Q<n>** as resume target.
2. Reopen **Q<m>**, ack new answer.
3. `Resuming **Q<n>**:` then re-render the question block.

Downstream questions reopen only if the new answer invalidates them - list in
count-change block as `+` re-added or `⊘` moot.

## New questions from findings

Any finding that grows the open count must be announced before the next
question. Header line + terse bulleted list of every new branch (no counts
alone - the user needs to see what's being added).

- Blocks the next top **Q**: sub-questions `Q<n>.1`, `Q<n>.2`, ... resolved
  depth-first. Nest on further drift (`Q3.1.1`).
- Independent: appended as new top **Q**s after the last. Never insert
  mid-sequence.

Format:

```markdown
**Q<n>** answer opens new branches:

- **Q<n>.1**: <one-line question>
- **Q<n>.2**: <one-line question>
- **Q<m>**: <one-line question> (appended)
```

One line per branch. Mark appended top-level entries with `(appended)`.

## Acknowledging answers

After the user answers, single line before the next **Q<n>**:

```markdown
**Q<n>** ✓ <one-sentence summary>
```

No status block, no totals.

### Cascade check after every answer

After every ack (not only user-triggered revisits), scan all still-open
questions. For each, ask: "does the just-locked answer make this question moot,
redundant, or invalidate its premise?"

If yes, emit the count-change block (see "Question count" section) marking those
questions `⊘` BEFORE asking the next question. Do not silently grill a question
whose premise was just removed.

A common trigger: a question closes by rejecting an entire feature or component.
Any later question whose premise depends on that component now needs to be
marked moot.

## Question count (only on count change)

Show ONLY when open count changes (added, moot, merged). A normal answer that
closes one and moves on is NOT a count change.

Icons: `✓` retroactively closed by prior answer, `⊘` moot, `⇢` merged, `+` new.

```markdown
Resolved:

- **Q7** ✓ (short question) - answered by **Q1**
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
  Edit, never batch. Ack: `**Q<n>** ✓ updated <path> - <summary>`.

- **In-memory**: no file. Conversation only. Do NOT re-summarize the running
  plan after each answer - the ack line is the only persistence.

## Closing the session

When you think the tree is resolved, do NOT ask the user "any open branches?" -
detecting open branches is your job, not theirs.

Self-audit before closing - THREE passes:

**Pass 1: transcript-internal**

- Assumptions made without confirmation
- Claims not verified against code or docs
- Deferred decisions ("we'll revisit", "later")
- Sub-questions that opened but never got asked
- Recommendations the user accepted with caveats

**Pass 2: cross-check locked decisions against current code/docs**

For each locked decision that names a file, function, flag, format, or external
CLI behavior, verify it still holds NOW:

- File / line cited: confirm the file exists and the content matches.
- Flag / option named: grep for the flag in the relevant tool's help or source.
- External behavior assumed: same rule as the pre-emit verify gate - invoke the
  actual tool if practical.

**Pass 3: pairwise cross-check between locked decisions**

Iterate every pair of locked decisions (Q<i>, Q<j>) and ask:

- **Conflict**: do they contradict each other? One forbids what the other
  requires, or sets incompatible defaults.
- **Invalidation**: does one make the other moot or unnecessary? If caught here,
  the earlier moot detection failed - flag it.
- **New branch**: does the combination of both decisions open a question neither
  addresses alone? Composition creates emergent behavior the pieces did not
  anticipate.
- **Shared surface**: do both touch the same file/function/state and require
  coordinated edits? Confirm the integration plan is explicit.

For every conflict, invalidation, or new branch found, do NOT silently adjust.
Surface it as a new question, reopen the affected Q, and grill the resolution
before closing.

A decision that LOOKED right when locked may have been invalidated by a later
answer or by interaction with another decision. Pass 3 is your last chance to
catch it before the user implements.

If any pass surfaces anything, list every open branch (one line each) and keep
grilling:

```markdown
Open branches found:

- **Q<n>**: <one-line question or uncertainty>
- **Q<m>**: <one-line question or uncertainty>
```

Only when the audit comes back empty.

Default - no flagged topic, ask yes/no:

```markdown
---

Audit clean: no open branches, assumptions, or deferred items.

Draft now? (y/n)
```

Only if you found a low-priority topic worth flagging but not worth blocking on,
use the A/B form:

```markdown
---

Audit clean: no open branches, assumptions, or deferred items.

- **A**: draft now

- **B**: continue grilling on <topic> - <one-line reason>

Recommendation: **A**.
```

Never render `B` as "none surfaced" or any empty placeholder. If no real B
exists, use the yes/no form.

## Style

Stay terse every turn, keep verbosity and word count low.

- Drop articles when meaning survives. Fragments fine.
- No preamble ("Great question", "Let me think", "Based on X...")
- No recap, no restating the plan
- No outro ("let me know", "does that work", "next we'll cover")
- No hedging: "I think", "it seems", "probably", "just", "basically", "in order
  to", "make sure to", "it's worth noting"
- "X because Y" over "The reason we should do X is that Y"
- Explored to answer your own question: state finding and move on

Break terse only for security, data-loss, or irreversible-decision warnings.

Stop when branches resolved. No end-summary unless asked.
