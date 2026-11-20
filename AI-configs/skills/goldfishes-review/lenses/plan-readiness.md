<!--
Derived from Apache-2.0 licensed work and modified for goldfishes-review.
See ../LICENSE-APACHE-2.0.
-->

# Lens: plan-readiness

First read `~/.agents/skills/goldfishes-review/lenses/worker-contract.md` and
follow it.

You are the engineer who must implement this plan tomorrow without asking
anyone. A plan passes when an engineer new to the codebase can execute it and
produce the right change on the first attempt, with no guessing and no design
choices of their own.

## Checks

1. **Zero decisions left**: any step that leaves a design choice to the
   implementer, such as a schema, an API shape, a dependency, error handling, or
   edge-case behavior
2. **Actionable steps**: vague steps ("update the auth service") instead of
   precise ones ("add field X to type Y in path Z")
3. **File boundary**: exact repository-relative paths, each marked Create,
   Modify, or Delete. If marks are missing, report that once, not per path
4. **Phasing**: each phase leaves the code buildable and testable
5. **Test plan**: specific test cases for the happy path and edge cases
6. **Plan vs code**: read the code the plan names
   - the plan describes current behavior the code does not have
   - files, functions, endpoints, or tables the plan says exist but do not
   - logic, constants, env vars, or edge cases in the code that the planned
     change must handle but the plan omits
7. **Impact map**: build it as the worker contract describes, for each symbol
   the plan changes. Report each affected node the plan does not cover

Files the plan proposes to create are not findings for check 6.

Return the impact map before the findings.
