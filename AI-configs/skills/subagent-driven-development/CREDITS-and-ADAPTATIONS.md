# Credits and adaptations for subagent-driven-development

Original source:
<https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/subagent-driven-development/SKILL.md>

- Fork point: `f2cbfbe`, v5.1.0, 2026-05-04
- Last compared against upstream: `5bf4e78`, v6.4.1, 2026-09-19

## Adaptations

- Removed `superpowers` namespace references
- Delegated each complete task, review, and commit loop to its implementer
- Added terse implementer, reviewer, and finalizer result contracts.
  Upstream's reviewer returns strengths and an assessment paragraph; this
  fork returns one bullet per root cause and bans advisory findings
- Added a finalizer subagent for whole-plan review and final commit
- Replaced the code-quality reviewer prompt reference with
  `requesting-code-review`
- Removed the `test-driven-development` skill reference while keeping TDD
- Scoped the `HANDOFF` relay to the finalizer, the only subagent emitting it
- Barred the orchestrator from running final verification or the full gate
- Delegated snapshot lifecycle to the shared `executing-plans` rule
- Dispatch passes template PATHS, never template bodies. Upstream fills a
  154-line implementer template and a 207-line reviewer template in
  orchestrator context; this fork sends ~10 lines of pointers and values, so
  neither template ever enters the orchestrator
- Added the `static` / `behavioural` discharge tag. An all-static fix round
  closes on its green gate with no re-review, saving a round upstream always
  pays
- Added `context = NON-NORMATIVE orientation only`. Upstream's
  `[Scene-setting]` placeholder invites requirements into the dispatch
- Added `**Difficulty:**`-driven model selection with tiers, not model names,
  so one skill serves Claude, Codex, Cursor, and Pi
- Added one-tier escalation on `BLOCKED`: a fresh implementer one tier up
  continues from the blocked report, until the top tier. Blockers needing user
  input, access, or a fresh anchor stop at once
- Relayed `Manual check (user)` items to the user after the finalizer's `PASS`
- Added dismissal recording: a `static` finding may be dismissed only with
  counter-evidence, surfaced as a `DISMISSED` line; a `behavioural` finding
  can never be dismissed, only fixed or escalated
- Added milestone `READY` / `FINALIZE` / `FINALIZED` coordination

## Ported back from upstream (2026-09-23)

- Context isolation through files. The implementer receives a task brief and
  the shared preamble, never the plan; the reviewer receives brief, report,
  and review package, never the plan. Upstream solved this with scripts while
  this fork had rules telling agents what to read from one large file
- `scripts/plan-workspace` (upstream `sdd-workspace`), one git-ignored
  artifact directory per plan, with plan-path markers resolving basename
  collisions. Renamed `.superpowers/sdd/` to `.plans/`, matching the stripped
  namespace
- `scripts/review-package`, ported unchanged in behavior: commits, stat, and
  `git diff -U10` to a file the reviewer reads in one call
- `scripts/task-start` and `scripts/task-done`. `task-done` records the ledger
  line only on a passing test run, so a claimed completion cannot outrun its
  evidence. Fixed an upstream bug: a silently passing command left the ledger
  line unwritten under `set -e`
- `scripts/task-brief`, REWRITTEN not ported. Upstream matches
  `^#+[ \t]+Task[ \t]+N`; this fork's plans use `- [ ] **Task N:**` and its
  awk extracts zero lines from them. The rewrite also handles indented
  list-item fences and carries each task's trailing commit checkpoint
- `scripts/plan-preamble`, this fork only. Upstream inlines global
  constraints into the dispatch; extracting them to a file keeps them out of
  orchestrator context
- The progress ledger, replacing the plan header's `Execution log` and
  `Solved defects`
- `Ruling:` line format for every deviation, collected into the final report
- "Do not trust the report": a stated rationale never downgrades a finding's
  severity, and a brief-mandated defect is still a finding
- Reviewer test rules: never re-run the suite to confirm the report;
  illegible evidence is a gap to report, not grounds to regenerate it
- Workspace deleted after a clean final review

## Corrections

- Removed the reference to `verification-before-completion`, deleted from this
  repo in commit `7ee72fe`
