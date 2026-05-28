---
name: test-simplify
description: >
  Simplify and reduce tests while preserving coverage. Use when the user asks to
  simplify, deduplicate, reduce, or clean up test files using techniques such as
  equivalence class partitioning, decision tables, or pairwise testing.
---

# Test simplify

Use a separate code-simplifier subagent when available.

If the current agent runtime lacks named subagents, use the available generic
subagent mechanism and pass the constraints below verbatim.

## Dispatch

Pass file paths and these instructions to the subagent:

- Analyze each test case before editing
- Use decision tables for complex scenarios
- Use pairwise testing for parameter combinations when useful
- Use equivalence class partitioning to minimize cases while preserving coverage
- Remove redundant tests that do not add coverage
- Group similar tests to reduce duplication
- Keep tests validating existing behavior and requirements
- Choose the right technique for the scenario
- Do not force every technique into every test file
- Do not add comments explaining simplification rationale
- Do not add tables or verbose explanations to the test code
- Deliver clean test code, not an explanatory report

## Constraints

- Preserve behavior under test
- Preserve meaningful edge-case coverage
- Prefer fewer clearer tests over dense clever parameterization
- Do not execute simplification in current context when subagents are available
