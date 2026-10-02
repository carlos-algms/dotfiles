# Credits and adaptations for executing-plans

Original source:
<https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/executing-plans/SKILL.md>

- Fork point: `f2cbfbe`, v5.1.0, 2026-05-04
- Last compared against upstream: `5bf4e78`, v6.4.1, 2026-09-19

## Adaptations

- Removed `superpowers` namespace references
- Replaced the subagent redirect with an inline or subagent execution handoff.
  Upstream splits these into two skills; this one owns the shared start gates
  and hands off
- Added immediate checkbox ticking after verified steps
- Added plan-owned commit cadence with inline or delegated checkpoint
  ownership
- Added final whole-plan review with a reuse-first evidence gate
- Added a single-runner rule for final verification, owned per execution mode
- Added a shared baseline-snapshot lifecycle with per-mode cleanup ownership.
  Upstream has no equivalent: it never classifies pre-existing uncommitted
  work, so a plan executed over a dirty tree can commit work the user never
  intended
- Added mechanical invalidation: a passing command is stale only when an edit
  landed after it, and a formatter run is never an invalidating edit
- Added milestone finalization turns

## Ported back from upstream (2026-09-23)

- The progress ledger at `<workspace>/progress.md`, authoritative resume state
  that survives compaction. Checkboxes remain the explicit done-claim; a `[x]`
  with no ledger line means the ledger was lost and the task's gate is re-run
- `Ruling:` lines for every deviation, collected into the final report.
  Deviating without a ledgered ruling is a decision made in secret
- The per-task loop built on `task-start` and `task-done` rather than manual
  bookkeeping
- Reading the task brief every task, including remembered ones: what you
  remember is a summary, the brief has the exact values
- The pre-flight interface scan before Task 1, cross-checking each task's
  `Produces` against its consumers' `Consumes`
- Reading the plan's spec at start, with the spec as the binding authority
  when the plan conflicts with it
- Workspace deletion after a clean final review, with `git clean -fdx` named
  as the loss case recovered from `git log`

## Corrections

- Removed the reference to `verification-before-completion`, deleted from this
  repo in commit `7ee72fe`
