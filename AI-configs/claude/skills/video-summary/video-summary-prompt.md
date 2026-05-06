You are summarizing a video. A report from a video-extraction pipeline will be
provided below. It lists frame paths, an optional thumbnail, channel and
metadata, chapters, and a transcript.

**Read every frame path and the thumbnail (if present) in parallel using the
Read tool.**

Before writing the summary, run these explicit checks against the transcript and
frames. Caveats can hide anywhere - intro hook, mid-demo aside, comparison
section, "but here's the thing" reversal, outro. Scan the whole transcript, not
just the end.

**Mental model:** a video is a sequence of _facts_ (concrete claims, demos,
reversals, asides). Authors group facts into _chapters_ for navigation. Chapters
tell you the topic; facts live inside them at their own moments.

- Chapters render as **ranges**:
  `[02:32-02:55] Git Worktrees for Parallel AI Coding` - the hyphen is the
  visual cue that this is a span, not a citation. Facts render as **single
  timestamps** in the transcript: `[02:34] AoE uses Git worktrees...`.
- Use the chapter list as a map of _where to look_ in the transcript, not as the
  source of timestamps. Chapter titles never appear inside your bullets, and
  chapter range timestamps never appear in your citations.
- When you cite a fact, the timestamp must be the **single-timestamp transcript
  line where that fact actually appears**. If a claim spans several transcript
  lines, cite the first one.

**Timestamp format is `MM:SS` or `HH:MM:SS` only.** The transcript reports raw
seconds (e.g. `[15.68]` means 15.68 seconds = `[00:15]`, `[133.04]` means 133.04
seconds = `[02:13]`). Convert before emitting. Never output decimal seconds in a
bullet.

**Key moments sizing:** one bullet per genuinely useful jump-point, single
timestamp each, not a range. Sizing is content-driven, not length-driven:

- A 30-second clip with one beat: 1-2 bullets is correct; padding to 5 is fluff.
- A 5-minute talking-head: usually 4-6.
- A 30-minute densely-packed tutorial with chapters and side-quests: 8-15 is
  fine. Stop when adding another bullet would dilute the average. Stop earlier
  if the video genuinely has fewer beats. Never invent moments to hit a count,
  never compress two distinct moments into one bullet to stay under one. Avoid
  restating chapter section headers as bullets - those are a section index, not
  a moment.

1. **Publisher relationship.** The report contains a `## Channel and metadata`
   section with channel name, categories, tags, and a truncated description.
   Read these as evidence alongside the transcript and frames.

   Decide between four classifications. Each requires concrete cited evidence:
   - **Owner/employee** - host states they built the product or work for the
     company that makes it. Signals: "we built X", "our team at X", description
     links go to the same company that makes the reviewed product. Quote
     required in your Verdict.
   - **Affiliated (paid)** - one of these is present in transcript, frames, or
     description:
     - "Sponsored by", "thanks to X for sponsoring", "brought to you by"
     - Promo code, discount, affiliate link with tracking
     - On-screen "paid partnership", "#ad", "#sponsored" Quote the signal
       verbatim in your Verdict.
   - **Channel-marketing** - the channel is owned by a commercial entity (its
     description points to the publisher's own paid products, separate from the
     product reviewed). The video covers a third-party tool as part of the
     channel's content strategy. The host is not paid by the reviewed product,
     but the channel itself is a marketing surface for the publisher's separate
     business. Cite the description links to the publisher's own product as
     evidence.
   - **Uncertain** - default when no signals are visible. State: "publisher
     relationship to product unclear from video; check the channel's recent
     uploads if it matters."
   - **Independent** - host explicitly disclaims commercial link ("not
     sponsored", "not affiliated", "I bought this myself"), or the channel is
     clearly a personal/independent reviewer (no commercial entity behind the
     channel name, no paid products in description).

   **Verification rule:** before classifying as Affiliated or Channel-marketing,
   you MUST be able to **quote** the specific signal verbatim from the
   transcript, description, or describe an on-screen element you observed in a
   frame. If you cannot quote it, downgrade the classification to Uncertain.

   **NOT signals of affiliation:**
   - Host plugging their own channel ("subscribe to my channel", "hit the
     bell"). Self-promotion is orthogonal to the product.
   - Channel name being a company name. By itself, that is Channel-marketing at
     most, not Affiliated with the product.
   - Marketing-style chapter titles ("Why developers are switching to X").
     Editorial framing, not affiliation evidence.
   - Enthusiastic walkthroughs of the product's strengths.
   - Host's own production polish, branding, or pacing choices.

   Cite your evidence in the Verdict. Quote signals verbatim. Do not use hedge
   language about "promotional feel" or "ecosystem partner" - those are
   projections, not observations.

2. **Title vs delivery.** Does the body literally deliver the claim in the
   title? Where does it stop short, and where does it overstate?
3. **Demonstrated vs described features.** List only features actually shown
   working on screen. Features only described in voiceover are weaker evidence -
   flag if the headline relies on them.
4. **Conditional claims and reversals.** Anywhere the host says "if you're doing
   X then Y", "honestly though", "but only when", "the catch is", "to be fair" -
   these are caveats. Capture them with timestamps even when they sit in the
   middle of demo material.
5. **Sponsor disclosures and affiliations.** Spoken, on-screen text, or
   description-implied (links, promo codes). Note presence or absence.
6. **Comparison fairness.** If the video compares tools or options, was each
   used in good faith, or strawmanned/feature-mismatched?
7. **Pacing and filler.** Assess whether the runtime is justified by content
   density. Watch for:
   - Repeated rephrasing of the same point multiple times throughout the video
   - Mid-video recaps that don't add new information
   - Disproportionate intro or outro relative to the body
   - Slow-paced demo segments, long silent zooms, repeated B-roll

   Distinguish from genuine deliberate pacing on dense technical material - some
   hosts naturally speak slowly, some concepts need breathing room. When in
   doubt, do not flag.

   Pick exactly one tag for the Pacing section:
   - **Tight** - no noticeable filler.
   - **Acceptable** - mostly content-driven, brief filler in intro/outro is
     normal.
   - **Padded** - clear repetition or filler segments. Cite specific timestamp
     ranges.
   - **Bloated** - large portions of runtime add no information. Cite timestamp
     ranges.

Then produce a summary in this exact shape:

```markdown
## TLDR

<one sentence, the answer the viewer came for>

## Verdict

<honest read vs the title; for comparisons, state the winner and why; flag
clickbait or buried caveats. Required: state the publisher relationship
classification from check 1 - one short clause is enough.>

## Summary

<2-4 sentences on what the video actually covers>

## Key moments

- [MM:SS] <fact or claim>
- [MM:SS] <fact or claim>
- [MM:SS] <fact or claim>

## Caveats

<render this section if any of checks 1-6 surfaced something real - sponsorship,
vendor-adjacent framing, "but actually" reversals scattered through the video,
conditional claims, undemonstrated features, unfair comparison. Skip the section
only if all six checks came back clean. Use the same bullet format as Key
moments: `- [MM:SS] <fact>`. Each caveat is one bullet with a leading single
timestamp. Quote the host when relevant.>

- [MM:SS] <caveat>
- [MM:SS] <caveat>

## Pacing

<one of: Tight, Acceptable, Padded, Bloated. Always render this section. For
Tight or Acceptable, one short clause is enough. For Padded or Bloated, follow
the tag with a short bullet list of cited timestamp ranges where filler
appears.>
```

End your response with one final line, exactly:

```
WORK_DIR: <absolute path of the work dir from the report>
```

Cite timestamps liberally - they are the actionable part. Do not skip reading
frames; they carry visual context the transcript misses.
