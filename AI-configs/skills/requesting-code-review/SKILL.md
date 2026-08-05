---
name: requesting-code-review
description: >
  Use for ad-hoc code review: after a major feature, before merging to main, or
  when stuck. Executing a written plan instead? Use executing-plans, which owns
  the per-task review cycle.
---

# Requesting code review

Dispatch a fresh reviewer with pointers, not session history.

This skill covers AD-HOC review: work not driven by a plan file.

**Executing a plan? Stop and use `executing-plans`.**

Use ad-hoc review before merge, after a major unplanned feature, or when stuck.

## Dispatch

1. Run the project's full gate and confirm it passes. Do not dispatch on failure
2. Collect:

```bash
git rev-parse HEAD
git status --porcelain
```

- `BASE_REF` - commit before the complete review scope. Resolve it from the
  target branch or supplied starting commit; use current `HEAD` only for purely
  uncommitted work
- `CHANGED_FILES` - deduplicated, newline-delimited exact-path union of
  committed changes since `BASE_REF` and current staged, unstaged, deleted, and
  untracked changes. Use rename destinations. These are entry points, not a
  boundary

3. Dispatch a fresh generic subagent:

```text
MUST read instructions at <skill_dir>/code-reviewer.md FIRST.
Do not act until you have read it. Then apply:
  plan_or_requirements = <requirements or plan reference>
  base_ref             = <commit before the work>
  baseline_snapshot    = none
  changed_files        = <newline-delimited exact paths>
  solved_defects       = none
```

Resolve `<skill_dir>` to the directory containing this `SKILL.md`.

Ad-hoc review has no baseline snapshot and no task scope, so `baseline_snapshot`
is always `none` and `task_id` and `scope_mode` are omitted. The reviewer
reviews the full `changed_files` delta. Plan execution supplies those values
instead.

4. `PASS`: finish
5. Findings: fix them, re-run the full gate, and dispatch a fresh reviewer

Reject incorrect findings only with code or test counter-evidence. Use one
clarification round for ambiguity; escalate unresolved disputes. Keep reviewer
responses out of the parent context except for `PASS` or the short finding list.
Allow 3 total attempts for empty, errored, or malformed output. Limit findings
to 3 fix/re-review rounds; escalate before a fourth.
