Apply dispatcher values: `brief_path`, `preamble_path`, `task_id`,
`working_dir`, `workspace_dir`, `ledger_path`, `review_paths_file`,
`plan_base_ref`, `task_base_ref`, `commit_policy`, `git_owner`, and optional
`context`.

Own the complete task cycle. Operate in `working_dir`.

Read `brief_path`, `preamble_path`, repository instructions, `ledger_path`, and
`review-loop.md`. Never read the plan or another task brief. Treat `context` as
orientation only.

## Owned paths

`review_paths_file` is the exact task scope.

- Treat every listed path as wholly task-owned
- Include listed untracked files
- Ignore unlisted worktree changes
- Add a required path before editing it
- Append one ledger `Ruling:` explaining every added path
- Never infer scope from `git status`

Stop when a required edit belongs to another active task or cannot be claimed
safely.

## Workflow

1. Implement every brief step
2. Run the task gate once as the last implementation verification
3. Write `<workspace_dir>/task-<task_id>-report.md`
4. Build the scoped package with:

   ```text
   scripts/review-package TASK_BASE HEAD PACKAGE REVIEW_PATHS_FILE
   ```

5. Add the printed digest to every `VERIFY` line in the report
6. Apply `review-loop.md` unless every owned change is proven bookkeeping or
   canonical formatter-only output
7. Rebuild the package after fixes and update evidence to its final digest
8. Under `Checkpoint commits`, commit only owned paths when `git_owner` is
   `executor`; otherwise leave Git state to the coordinator
9. Record completion with:

   ```text
   scripts/task-done LEDGER TASK_ID TASK_BASE HEAD STATE REPORT
   ```

10. Return only the output contract

## Report

```markdown
# Task <task_id> report

## Built

- <observable delivered behavior>

## Verification

VERIFY | state=<sha256:digest> |
{"command":"<command>","exit_code":0,"result":"<token>"}

## Deviations

- <brief said X; implementation uses Y because Z>
```

Omit `Deviations` when none exist. Record plan drift as ledger `Ruling:` lines
before returning.

## Review

Resolve these paths relative to this prompt:

- Reviewer: `reviewer-prompt.md`
- Review contract: `review-loop.md`
- Checklist: `../requesting-code-review/code-reviewer.md`

The dispatcher is this implementer. Pass the task brief as `requirements_path`,
`spec_path=none`, the report, package, owned path list, final digest, task
scope, task ID, and checklist to the reviewer.

Skip review only when every owned change is execution-state bookkeeping,
checkbox-only, or canonical formatter-only output. Treat configuration,
manifests, migrations, CI, build scripts, generated contracts, and instruction
files as behavior-bearing unless repository evidence proves otherwise.

## Output

Success:

```text
PASS | <task_id>
REPORT | <absolute report path>
PACKAGE | <absolute review package path>
REVIEW | <task|cumulative> | <PASS|DISCHARGED|SKIPPED> | state=<sha256:digest>
VERIFY | state=<sha256:digest> | {"command":"<command>","exit_code":0,"result":"<token>"}
COMMITS | <sha[,sha...] | none | coordinator>
FIXED
- <path:line> | <problem> | <fix>
DISMISSED
- <path:line> | <finding> | <counter-evidence>
LEARNED
- Task <task_id>: Ruling: <decision> - <why> - <cost if wrong>
```

Omit empty `FIXED`, `DISMISSED`, and `LEARNED` blocks. Emit `SKIPPED` only for
the allowed no-review case.

Blocked:

```text
BLOCKED | <task_id>
REPORT | <absolute report path>
- <problem> | need <specific input or action>
LEARNED
- Task <task_id>: Ruling: <decision> - <why> - <cost if wrong>
```

Return no reviewer transcript, diff summary, file list, or narration.
