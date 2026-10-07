# Credits and adaptations for writing-plans

Original source:
<https://github.com/obra/superpowers/blob/f2cbfbefebbfef77321e4c9abc9e949826bea9d7/skills/writing-plans/SKILL.md>

- Fork point: `f2cbfbe`, v5.1.0, 2026-05-04
- Last compared against upstream: `5bf4e78`, v6.4.1, 2026-09-19

Compare with `gh api repos/obra/superpowers/contents/skills/writing-plans/SKILL.md`
against the sync point above; update that line after each comparison.

## Adaptations

- Removed `superpowers` namespace references
- Removed isolated worktree skill requirement
- Changed default saved plan path from `docs/superpowers/plans/` to
  `docs/plans/`
- Added pre-plan commit policy prompt with per-task commits, one commit at the
  end, or no commits
- Added commit policy metadata and plan-owned commit checkpoints
- Added immediate checkbox ticking requirement
- Added single-writer task ownership for nested implementer review loops
- Moved the execution-mode prompt before writing so the header never saves an
  unresolved mode
- Added plan-reviewer checks for exact header literals, exact
  final-verification commands, and final verification duplicated outside its
  checkpoint
- Added verification deduplication: dominated checks, evidence reuse, and one
  invocation per tool
- Replaced the 49-line upstream reviewer prompt with a full audit contract
- Split every plan into a spec file and a plan file in one folder. Upstream
  links an optional external spec; this fork requires the pair and forbids
  spec prose in the plan
- Added `**Difficulty:**` per task (`low`/`medium`/`high`) driving model
  selection at dispatch, with no model map in the skill so it stays portable
  across harnesses
- Replaced every commit-checkpoint template body with a bare checkpoint line.
  The executing skill owns the mechanics; upstream repeats them per plan
- Moved progress state to the execution ledger. Checkboxes remain the
  implementer's explicit done-claim; the ledger is authoritative on resume
- Removed the `Solved defects` and `Execution log` header fields. Both live in
  the ledger
- Rewrote the skill body and reviewer prompt as imperative instructions with
  no narration or rationale
- Targeted a cheap, no-context implementer: verbatim-anchored edits, `Uses`
  signatures, full bodies up to 15 lines, one pattern test per test file, exact
  red and green expectations, a stop rule in the preamble, header `Goal` with
  `Out of scope` and `Call chain`, and an explicit Markdown layout with
  `## Tasks`
- Removed the per-task `Files` list. Executors derive owned paths from edit
  labels and `Changes` lines
- Limited planner verification to what exists. The plan's new code first runs
  in the implementer's red and green steps, so planning never pays for the
  implementation. Manual checks moved out of task gates to the user
- The writer reads and the implementer runs: no code, test, build, or check
  runs during planning; runtime behavior is a labeled prediction. The plan
  reviewer reads only, trusts the writer's `discovery_context`, and gets at
  most 2 dispatches
- The writer reads library internals only when public types and docs leave a
  design choice open. The reviewer never reads dependency source
- Re-review only after a `Critical` fix. `Important` fixes get self-review

## Ported back from upstream (2026-09-23)

- `**Interfaces:** Consumes / Produces` per task, so an implementer reading
  only its own task learns neighboring names and types
- Code blocks mandated for signatures, models, constants, regexes, and error
  messages; test cases as tables. Upstream requires code in every code step;
  this fork's `## Code detail` names what stays prose
- `**Spec:**` header field
- Task right-sizing: split only where a reviewer could reject one task while
  approving its neighbor
