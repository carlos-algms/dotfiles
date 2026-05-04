---
name: grill-me
description:
  Interview the user relentlessly about a plan or design until reaching shared
  understanding, resolving each branch of the decision tree. Use when user wants
  to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me on every branch of the design tree, or the decision making,
resolving dependencies one-by-one. If a question is answerable from the
codebase, explore instead of asking.

## Opener

Before starting the grill session, emit a flat list of branches to grill. No
numbers yet - just topics, one line each. Lets the user spot missing branches up
front.

`Branches to grill:`

- `<topic>`
- `<topic>`

Wait for confirm/extend, then proceed to the first question.

## Format

One question per turn, numbered **Q1**, **Q2**... sequentially. Never reuse,
skip, or reorder - even after revisits, drifts, or merges. Render `Q<n>` bold
everywhere (prose, bullets, ack lines, status block).

Prepend `---` before every **Q<n>** to reset the markdown parser between turns
and create visual dividers.

Max 4 blocks per turn, back-to-back, no section labels or bold prefixes:

1. **Q<n>** line - the decision being grilled
2. Optional description, only if options aren't self-sufficient
3. Options. Never invent filler to hit a number. Two cases:
   - 1 real path: ask yes/no (`Apply X? (y/n)`). No labels, no recommendation.
   - 2+ real paths: bulleted, no header. Bold label, blank line between,
     one-line tradeoff each.

   ```markdown
   ---

   #### Q3: should we cache responses?

   - **A**: in-memory, 5min TTL - simplest, lost on restart

   - **B**: redis, 1h TTL - survives restart, adds dep

   Recommendation: **A**, restart loss is acceptable for this path.
   ```

4. One-sentence `Recommendation:` line - the only inline label permitted

Gather context first: read code, docs, web. Surface options the user hasn't
considered. If only one path visible, look harder or state why none exists.

## Answers found in code

Code resolves the question: do NOT lock silently. Ask one yes/no first.

`**Q<n>** found: <answer> - source: <path:line>. Confirm? (y/n)`

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

Self-audit the transcript before closing:

- Assumptions made without confirmation
- Claims not verified against code or docs
- Deferred decisions ("we'll revisit", "later")
- Sub-questions that opened but never got asked
- Recommendations the user accepted with caveats

If anything surfaces, list every open branch (one line each) and keep grilling:

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
