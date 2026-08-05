---
name: verification-before-completion
description: >
  Use when about to claim work is complete, fixed, or passing, before
  committing, pushing, or creating PRs - requires running verification commands
  and confirming output before making any success claims; evidence before
  assertions always
---

# Verification before completion

## Iron law

```text
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

Evidence must come from this turn and cover the exact claim.

## Gate

Before a success claim, commit, push, or PR:

1. **Identify:** Name the claim and the command or inspection that proves it
2. **Run:** Execute the complete check now
3. **Read:** Inspect full output, exit code, and failure count
4. **Compare:** Confirm the evidence proves the claim
5. **Report:** State the result with its evidence

A skipped step means the gate failed.

## Evidence selection

- Use the narrowest check that proves the claim
- Use broader checks for shared behavior, build config, or user workflows
- Bug fix: reproduce the original symptom
- Regression test: verify red, green, red without the fix, then green restored
- Requirements: inspect each requirement; tests alone do not prove coverage
- Delegated task status: require the worker's raw command and result for
  coordination
- Designated finalizer: inspect the complete diff and run final verification.
  Exactly one agent runs it. The orchestrator relays its exact result and does
  not rerun the checks

| Claim            | Required evidence                           |
| ---------------- | ------------------------------------------- |
| Tests pass       | Test command, exit 0, zero failures         |
| Lint/types clean | Complete command, zero errors               |
| Build succeeds   | Build command, exit 0                       |
| Bug fixed        | Original reproduction now passes            |
| Requirements met | Requirement-by-requirement inspection       |
| Agent completed  | Finalizer diff inspection plus verification |

Include the command, exit code, and relevant result in the final report.

## Blocked verification

If the check cannot run:

- State the blocker
- Name what remains unverified
- Do not claim complete, fixed, passing, or ready

Confidence, prior runs, partial checks, and generic agent summaries are not
evidence. A designated finalizer's exact command, exit code, and relevant result
are evidence for a verbatim orchestrator relay; the orchestrator does not rerun
them.
