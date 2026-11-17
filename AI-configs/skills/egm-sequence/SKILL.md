---
name: egm-sequence
description: >-
  Routing map for the EGM (Elephant-Goldfish) skill set: which skill to run,
  in which order, which are mandatory and which optional. Load when starting
  or planning an EGM workflow, when unsure which egm-* skill comes next, when
  asked how to sequence design/review/documentation work with EGM, or when
  resuming an EGM flow after a pause. This skill routes; the individual
  egm-* skills execute.
---

# EGM Sequence — which skill, when

Elephant-Goldfish Model: design with full context (elephant), review with
fresh-context subagents (goldfish). This skill is the order-of-operations map.
It never executes review logic itself — it routes to the right `egm-*` skill
and stops. Invocation: `/egm-<skill>` in Claude Code, `/skill:egm-<skill>` in
Pi/Codex (Codex is fallback-only; see the port notes below).

## The main loop (new feature or design)

```text
egm-brainstorm  →  egm-draft  →  egm-review  →  egm-resolve
 (MANDATORY)      (MANDATORY)    (MANDATORY)    (MANDATORY if findings)
```

1.  **egm-brainstorm — MANDATORY, always first.**
    Input: a raw idea or half-formed concept. Interactive multi-turn
    clarification, then parallel Goldfish review of the hypothesis.
    Output: `concepts_brief.md`. Hard gates: no subagents until you confirm
    readiness; no handoff until you approve the brief.
2.  **egm-draft — MANDATORY, only after an approved brief.**
    Input: the approved `concepts_brief.md`. Builds the design doc section by
    section; you approve each section; architecture choices are presented as
    options and you decide.
    Output: `design_draft.md`. Never run without a brief: it is downstream of
    brainstorm by design.
3.  **egm-review — MANDATORY before implementation.**
    Input: `design_draft.md` (or an existing design doc). Runs the staged
    Goldfish Review Protocol (zoom out → comprehension → critique →
    implementation readiness). Output: `consolidated_review_report.md` plus
    per-stage reports. Disposable plans may defer the full review to a
    pre-merge audit instead — see Artifact lifecycle.
4.  **egm-resolve — MANDATORY when the report has findings.**
    Input: target doc + `FindingsList` from the review. Categorizes each
    finding (CONTEST / ESCALATE / ACCOMMODATE / DELEGATE), defends sound
    choices with evidence, applies approved repairs.
    Run it in the same (elephant) session that produced the document. No
    findings: skip — the review ending clean is the exit gate to
    implementation.
5.  **Implementation itself is outside EGM.** A clean review is the approval
    to build; EGM does not write code.

**Optional in the main loop:**

- **egm-review-loop — optional, replaces step 3 when iterating.** Use instead
  of a single `egm-review` pass when the doc is expected to change over
  multiple rounds (feature specs, contested designs). It re-resolves line
  ranges each iteration and re-dispatches reviewers until findings converge.
  `egm-review` and `egm-review-loop` are alternatives, not a pair.

## Alternative entry points (skip the main loop)

- **Review-only**: already have a design doc, README, or PR plan and no EGM
  history? Start directly at `egm-review`. Brainstorm/draft are for creating
  documents, not reviewing existing ones.
- **Code-only review (no doc)**: code exists but no brief, draft, or design
  doc. No `egm-*` skill covers it: `egm-review` needs a document and
  `egm-drift-report` needs a checked-in doc. Spawn persona subagents on the
  code directly, in parallel, each with a fresh context:
  - Use `egm-zoom-out` (simplicity, YAGNI, reuse), `egm-design` (risks,
    failure modes), and `egm-codebase-details` (accuracy against host APIs)
  - Skip `egm-comprehension`, `egm-structural`, and `egm-style`: they audit
    prose
  - Brief: the user's requirements, the changed file paths, and where host API
    docs and sibling code live. No hypotheses, conclusions, or fix ideas
  - Reviewers are read-only and return findings in their final message. No
    report files: without a doc there is nothing to anchor them to
  - The elephant verifies each finding against the code, dedupes across
    reviewers, then proposes fixes through the user's approval gate
- **Documenting an existing codebase**: start at `egm-bootstrap` (MANDATORY
  entry for this mode). It writes EGM-compliant contract READMEs across a
  directory tree ("peanuts" leaf contracts, "hay" rollups). Documentation
  only — no code generation, no commits. Brainstorm/draft do not apply.
- **Maintenance**: `egm-drift-report` (optional, run periodically or on
  demand). Compares checked-in design docs or contract READMEs against the
  current code and reports only discrepancies. `bootstrap` first if the docs
  do not exist yet.

## When NOT to run EGM at all

Small, clear bug fixes. Reviews are token-heavy; the overhead exceeds the
value when there are no real design decisions. If unsure whether a task has
design decisions, that uncertainty is itself the signal to brainstorm.

## Entering implementation

Implementation starts when the review ends clean — Stage 9
(Implementation Readiness) passed and you approved it. If findings existed,
run `egm-resolve` (and re-review changed sections, or use `egm-review-loop`
for the whole cycle) first.

How to enter:

1. Stay in the same (elephant) session that drafted and reviewed the design
   — it holds the reasoning behind every resolved trade-off
2. Tell the agent plainly: "implement per `design_draft.md`". No EGM skill
   implements; none of them write code. The spec is the contract, the
   consolidated review report records what was contested and settled
3. Post-code checks depend on the artifact mode (see Artifact lifecycle):
   durable mode → `egm-drift-report` (review judges the design, drift judges
   the code); disposable mode → `egm-review` on the plan file as a pre-merge
   audit — no committed doc means drift is unavailable

## Artifacts you will see, in order of appearance

| File | Produced by | Meaning |
| --- | --- | --- |
| `concepts_brief.md` | egm-brainstorm | agreed problem + requirements |
| `design_draft.md` | egm-draft | the specification under construction |
| `zoom_out_report.md` | egm-review | stage 5 findings |
| `comprehension_report.md` | egm-review | stage 6 paraphrase test |
| `intermediate_zoom_out_report.md` | egm-review | stage 8 findings |
| `consolidated_review_report.md` | egm-review | final report |
| `{YYYY-MM-DD}_DRIFT_REPORT.md` | egm-drift-report | doc-vs-code deltas |

Artifacts go to the working directory, or to `EGM artifact directory: <path>`
if an instructions file declares it.

## Artifact lifecycle

Artifact names are constant (`design_draft.md`, `concepts_brief.md`,
`consolidated_review_report.md`), so the next EGM run in the same directory
overwrites them. EGM assumes one flow per working directory at a time.
Everything lands in the working directory root, or in
`EGM artifact directory: <path>` if an instructions file declares it — use a
per-run or per-feature path when flows may overlap.

Two valid modes; ask the user which applies when it affects what you do with
artifacts:

- **Durable mode**: commit `design_draft.md` (direct it into the repo via
  `EGM artifact directory`, e.g. `docs/designs`). It is the long-lived
  contract; `egm-drift-report` only works against checked-in docs. The brief
  and per-stage reports stay disposable; `consolidated_review_report.md`
  documents what was contested and settled — put relevant findings in the PR
  description rather than committing the file
- **Disposable mode**: every artifact is ephemeral. Brainstorm → refine →
  implement → (optional pre-merge `egm-review`) → merge → dispose. Constant
  names are then a feature: predictable paths for the next run. Never dispose
  while findings are unresolved, and accept the consequence: no committed doc
  means no `egm-drift-report` and no design record for future agents — the
  code and PR description carry it alone

In both modes, never commit per-stage reports or drift snapshots "for
completeness".

## Resuming after a pause

Find the newest artifact to know where you are:

- `concepts_brief.md` approved, no `design_draft.md` → resume at `egm-draft`
- `design_draft.md` approved, no review report → resume at `egm-review`
- review report with unresolved findings → resume at `egm-resolve`
- drifted docs in a mature repo → `egm-drift-report`

Never restart with `egm-brainstorm` if an approved brief already exists; feed
the existing artifact to the next stage instead.

## Non-negotiable rules (inherited by every egm-* skill)

- Goldfish reviewers need fresh contexts. A review executed in the main
  conversation is not a Goldfish review — if the harness cannot spawn
  subagents, the skill must stop, not fake it.
- Artifacts are written to files, never dumped into chat.
- Approval gates are human checkpoints; pausing to save progress is always an
  option at every gate.

## Port-specific notes (this vendored layout)

- Skills: `AI-configs/skills/egm-*/`; personas: `~/.agents/agents/egm-*.md`;
  standards: `AI-configs/google-elephant-goldfish/resources/document_standards/`
- Claude Code: skills keep `disable-model-invocation: true` (the `Skill` tool
  refuses them) — invoke via `/egm-<skill>`; run chained subskills by reading
  their `SKILL.md` and following in-thread
- Codex: skills discovered, but no named agent types — spawn generic subagents
  instructed to read the persona file first
- This skill (`egm-sequence`) is local-authored, not vendored; upstream
  updates never touch it
