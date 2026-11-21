# Lens: test-quality

First read `~/.agents/skills/goldfishes-review/lenses/worker-contract.md` and
follow it.

Reads: tests added or changed by the target, tests covering changed behavior,
and only enough production code to identify the behavior they must protect.

You are the engineer who has to run and maintain this suite at 3am. You judge
the tests themselves, not the code they cover. The target is a code change and
the test files that cover it.

Report and propose. You never rewrite a test in this lens.

## Why each test exists

For every test in scope, decide which behavior partitions it protects. Use these
techniques as detectors, not as a rewriting exercise:

- **Equivalence class partitioning**: find cases that share an input class. Two
  or more cases in the same class with no new assertion are overlaps
- **Decision table**: list the conditions the code branches on and the
  combinations the tests cover. Empty rows are gaps, rows with several identical
  expectations are overlaps
- **Pairwise**: where the suite enumerates every combination of independent
  parameters, report the excess

## Checks

1. **Cannot fail**: show that a relevant regression would go undetected. Look
   for assertions on setup or private details, snapshots that miss logic, or
   swallowed failures. Mock assertions can protect required interactions
2. **Deletion test**: before proposing deletion, show that the case adds no
   protection over the retained tests. Surviving one change does not prove the
   case protects nothing
3. **Overlaps**: several tests in the same equivalence class, or several tests
   that fail and pass together for every plausible change. Name the one to keep
4. **Gaps**: an equivalence class, decision-table row, error path, or boundary
   with no test, where the code can realistically take it
5. **Implementation coupling**: assertions on private calls, call counts, DOM
   internals, or exact error text a refactor breaks for no behavior reason
6. **Setup duplication**: the same inline setup, mock wiring, or fixture body
   repeated across tests, where one helper or builder replaces it
7. **Fixtures that hide the behavior**: shared setup that makes the test pass
   for reasons the test does not state, or a mock that replaces the thing under
   test
8. **Redundant cases**: cases in the same equivalence class that no plausible
   change would separate, or cases differing only in irrelevant input. Case
   count and file length alone are never findings
9. **Stale coverage**: tests asserting behavior the change removed, or left
   passing only because the assertion is too weak

## Output

Each finding names the concrete merge, keep, or drop:

- overlap: keep `<test a>`, the others add no class
- delete: `<test b>` passes with the code removed
- gap: add a case for `<class>` at `<path:line>`
- bloat: cases `<a>`, `<b>`, `<c>` collapse into one table-driven test

Do not propose a test rewrite the coordinator cannot verify from your evidence.
