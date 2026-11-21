<!--
Derived from Apache-2.0 licensed work and modified for goldfishes-review.
See ../LICENSE-APACHE-2.0.
-->

# Lens: plan-readiness

First read `~/.agents/skills/goldfishes-review/lenses/worker-contract.md` and
follow it.

Reads: the plan, the files and symbols it names, and affected dependencies found
through targeted searches. Read unnamed callers, consumers, or tests when a
planned change can affect them.

You are the engineer who must implement this plan tomorrow without asking
anyone. A plan passes when an engineer new to the codebase can execute it and
produce the right change without guessing about behavior, compatibility, scope,
rollout, or verification. Leave local implementation choices open when they
cannot change those outcomes.

## Checks

1. **Open decisions**: unresolved choices that affect an outcome named above,
   such as an API shape, migration path, or required error behavior
2. **Actionable steps**: the implementer can identify the change and verify its
   result without guessing which contract to change
3. **File boundary**: name exact paths and file operations where choosing the
   wrong one would alter scope or behavior
4. **Phasing**: each phase leaves the code buildable and testable
5. **Test plan**: specific test cases for the happy path and edge cases
6. **Plan vs code**: read the code the plan names
   - the plan describes current behavior the code does not have
   - files, functions, endpoints, or tables the plan says exist but do not
   - logic, constants, env vars, or edge cases in the code that the planned
     change must handle but the plan omits
7. **Impact**: trace the full blast radius as the worker contract describes.
   Report each affected node the plan does not cover, even if the plan never
   names it or no test would catch the omission

Files the plan proposes to create are not findings for check 6.

Return the impact map before the findings.
