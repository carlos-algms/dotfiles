Apply dispatcher values: `plan_path`, `working_dir`, `workspace_dir`,
`ledger_path`, `plan_base_ref`, `review_evidence`, `verification_evidence`,
`review_packages`, `commit_policy`, `git_owner`, `milestone_owner`, `pr_owner`,
and `plan_id`.

Own complete-plan review, final verification, final executor-owned state, and a
requested PR when `pr_owner=executor`. Operate in `working_dir`.

Read the plan, its spec when present, repository instructions, the ledger, and
`review-loop.md`.

## Complete scope

Merge every `<workspace_dir>/task-*-paths.txt` into
`<workspace_dir>/final-paths.txt`. Preserve one repo-relative path per line and
remove duplicates. Never add a path from `git status`.

Write `<workspace_dir>/final-report.md` with delivered behavior, verification
evidence, and deviations.

Build the complete package:

```text
scripts/review-package PLAN_BASE HEAD FINAL_PACKAGE FINAL_PATHS
```

Use the printed digest as the final state identity.

## Final workflow

1. Locate the written final-verification checkpoint
2. Stop when it is missing
3. For each retained task package, require its state entries to match the same
   paths in the complete package
4. Reuse task evidence when matching task packages cover its semantic scope;
   combine matching packages when their union covers complete scope
   - Matching path state does not prove cross-task interaction coverage
5. Apply `review-loop.md` to uncovered behavior
6. Run only written final checks whose semantic scope remains uncovered
7. Rebuild the package after every fix and update evidence to its digest
8. Append final rulings to the ledger
9. Tick final verification
10. Under `Checkpoint commits`, execute the final state checkpoint when
    `git_owner=executor`
11. When `milestone_owner=executor`, validate the one matching milestone link,
    check its box, preserve every other entry, format the file, and verify the
    link
12. Create a requested PR only when the reviewed work is committed and
    `pr_owner=executor`
13. Return only the output contract

When `git_owner=coordinator`, leave owned implementation state for coordinator
integration. When `milestone_owner=coordinator`, return the verified `plan_id`;
never edit the milestone. When `pr_owner=coordinator`, return
`PR | coordinator`.

## Review dispatch

Use `reviewer-prompt.md` through `review-loop.md` with:

```text
requirements_path = <plan_path>
requirements_kind = plan
spec_path          = <plan Spec path | none>
report_path        = <workspace_dir>/final-report.md
package_path       = <complete package>
review_paths_file  = <workspace_dir>/final-paths.txt
state_digest       = <final package digest>
scope_mode         = complete
task_id            = all
checklist_path      = <requesting-code-review/code-reviewer.md>
```

## Plan state

Apply one `Plan file policy` to the plan and every additional plan state path.

- `Include`: add modified plan state to the final checkpoint when this executor
  owns Git
- `Exclude`: never stage or commit plan state; emit `STATE` when modified

The active milestone owner is the only writer of a milestone state file.

## Output

Success:

```text
PASS | final
PLAN | <plan_id | none>
PATHS | <absolute final paths file>
PACKAGE | <absolute final package path>
REVIEW | complete | <PASS|DISCHARGED|SKIPPED> | state=<sha256:digest>
VERIFY | state=<sha256:digest> | {"command":"<command>","exit_code":0,"result":"<token>"}
COMMITS | <sha[,sha...] | none | coordinator>
PR | <url | none | coordinator>
STATE | <comma-separated excluded modified plan-state paths>
FIXED
- <path:line> | <problem> | <fix>
DISMISSED
- <path:line> | <finding> | <counter-evidence>
LEARNED
- final: Ruling: <decision> - <why> - <cost if wrong>
```

Omit empty `STATE`, `FIXED`, `DISMISSED`, and `LEARNED` blocks.

Blocked:

```text
BLOCKED | final
- <problem> | need <specific input or action>
STATE | <comma-separated excluded modified plan-state paths>
LEARNED
- final: Ruling: <decision> - <why> - <cost if wrong>
```

Return no reviewer transcript, diff summary, implementation file list, or
narration.
