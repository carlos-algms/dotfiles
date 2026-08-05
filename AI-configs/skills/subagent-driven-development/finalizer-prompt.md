Apply dispatcher values: `plan_path`, `working_dir`, `plan_base_ref`, and
`baseline_snapshot`.

Own the remaining written plan-level checkpoints. The orchestrator only relays
your result. Operate in `working_dir`.

The plan owns the final workflow. Execute its checkpoints in written order. Do
not add a review, verification, or commit step that the plan does not contain.

Resolve prompt paths relative to this file:

- Spec: `spec-reviewer-prompt.md`
- Quality: `code-quality-reviewer-prompt.md`
- Quality checklist: `../requesting-code-review/code-reviewer.md`

## Workflow

1. Read the complete plan
2. Read the commit policy
3. Read the plan-file policy
4. Read the convention sources
5. Read `Solved defects`
6. Locate the remaining plan-level checkpoints
7. Stop when the plan lacks its final-verification checkpoint
8. Execute the written final-verification checkpoint:
   1. Derive the complete changed-path set from current repository state
   2. Exclude baseline-only paths from review scope
   3. Exclude `execution-state` paths from review scope
   4. Dispatch the written full-plan code-quality review
   5. On findings, verify each citation
   6. Stop before editing a baseline-only fix path in commit-bound execution
   7. Uncheck affected plan state
   8. Uncheck the conditional final-review-fixes commit checkpoint before the
      first fix under `Per-task commits`
   9. Fix each substantiated finding
   10. Update `Solved defects`
   11. Run only the affected narrow gates
   12. Re-tick verified task state
   13. Re-run affected spec review when delivered behavior changed
   14. Re-dispatch code-quality review after each fix round
   15. Require `PASS`
   16. Load `verification-before-completion`
   17. Run each written final automated check once
   18. Perform each written final manual check once
   19. Tick the final-verification checkpoint
9. Execute each remaining written commit checkpoint
10. When the plan requests a PR and the branch contains the reviewed committed
    work, load `create-pull-request` and complete it
11. Return only the output contract below

## Commit policy

- `Per-task commits`: leave the pre-checked final-fixes checkpoint unchanged
  when review passes without edits. Before the first final-review fix, uncheck
  it. After final verification, execute it once for the combined verified fix
  set. Execute the final-state commit checkpoint only when `Plan file policy` is
  `Include`
- `One commit at the end`: after all reviewers pass and final verification is
  green, tick the whole-plan checkpoint immediately before staging and commit
  the complete reviewed plan diff with `git-commit-message`
- `No commits`: do not stage or commit

When `No commits` and the plan requests a PR, return `BLOCKED` after successful
verification while reviewed plan changes remain uncommitted. Record and hand off
the exact plan-owned paths, hashes, modes, and deletion states in the owner-only
`baseline_snapshot/pr-handoff.json`; include plan state only when its policy is
`Include`. Return that path. On redispatch, require the manifest, reject any
baseline-only branch delta or mismatch, then return `PASS` without repeating
review or verification when the branch matches the reviewed manifest exactly.

Restore a pre-ticked checkpoint whenever scope resolution, staging, or commit
fails. Never use plan file lists as commit scope. Include current plan checkbox
and `Solved defects` changes only when `Plan file policy` is `Include`.

## Reviewer rules

- Reviewers return only `PASS` or short findings
- Reviewers never edit, stage, or commit
- One clarification re-dispatch for an incorrect finding
- Empty, errored, or malformed responses get 3 total attempts
- A `<review-input>` finding is a failed dispatch; correct the payload
- Any unresolved dispute, third failed dispatch, failed gate, unsafe scope, or
  fourth finding round returns `BLOCKED`

Quality dispatch:

```text
MUST read instructions at <skill_dir>/code-quality-reviewer-prompt.md FIRST.
Do not act until you have read it. Then apply:
  plan_or_requirements = complete plan at <plan_path>
  task_id             = all tasks
  scope_mode          = complete
  base_ref             = <plan_base_ref>
  baseline_snapshot    = <abs path to classified snapshot directory>
  changed_files        = <newline-delimited exact paths>
  solved_defects       = <plan list or `none`>
  checklist_path       = <abs path to quality checklist>
```

Affected spec re-review:

```text
MUST read instructions at <skill_dir>/spec-reviewer-prompt.md FIRST.
Do not act until you have read it. Then apply:
  plan_path         = <abs path>
  task_id           = <affected task IDs>
  base_ref          = <plan_base_ref>
  scope_mode        = task
  baseline_snapshot = <abs path to classified snapshot directory>
  changed_files     = <newline-delimited affected paths>
  solved_defects    = <plan list or `none`>
```

`<skill_dir>` is this file's directory. Use absolute resolved paths.

## Output

Success:

```text
PASS | final
VERIFY {"command":"<command>","exit_code":0,"result":"<success token>"}
VERIFY {"manual":"<check>","status":"PASS","observation":"<observation>"}
COMMITS | <sha[,sha...] | none>
PR | <url | none>
FIXED
- <path:line> | <problem> | <fix>
```

Emit one `VERIFY` line per final-verification command or manual check. Merge
duplicate `FIXED` root causes. Emit valid compact JSON and escape dynamic
strings; omit the manual form when no manual check exists.

Omit `FIXED` when no reviewer finding was fixed.

Cannot continue:

```text
BLOCKED | final
HANDOFF | <manifest path, external-commit blocker only>
- <problem> | need <specific input or action>
```

No reviewer transcript, diff summary, file list, or narration.
