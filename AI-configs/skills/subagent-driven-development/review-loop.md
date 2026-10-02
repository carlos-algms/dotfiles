# Review loop

Use this contract for inline, task, and final review.

## Inputs

- `requirements_path`: task brief or complete plan
- `requirements_kind`: `task` or `plan`
- `spec_path`: complete-plan spec path or `none`
- `report_path`: implementer or final report
- `package_path`: scoped review package
- `review_paths_file`: dispatcher-owned repo-relative paths, one per line
- `state_digest`: digest printed by `review-package`
- `scope_mode`: `task`, `cumulative`, or `complete`
- `task_id`: one task, several tasks, or `all`

Treat every listed path as wholly owned by the dispatched scope. Never add a
path inferred from `git status`. Include listed untracked files. Ignore every
unlisted path.

## Dispatch

Dispatch one fresh reviewer with `reviewer-prompt.md` and the inputs above plus
`checklist_path`. A plan reviewer reads `spec_path` as requirements input, not
implementation scope.

Accept only `PASS` or Critical and Important findings carrying `static` or
`behavioural`. Treat empty, errored, narrated, malformed, or untagged output as
a failed dispatch. Allow three dispatch attempts, then stop.

## Findings

1. Verify each citation
2. Fix each substantiated finding within the owned path list
3. Reject an off-scope fix instead of silently adding its path
4. Dismiss a `static` finding only with `path:line` counter-evidence
5. Never dismiss a `behavioural` finding; fix it or stop on the dispute
6. Re-run only verification invalidated by a semantic edit
7. Rebuild the review package after every fix
8. Re-dispatch after any `behavioural` fix
9. Close an all-`static` round when invalidated gates pass

Permit two finding rounds. A third finding round stops execution.

Formatter-only and semantic-neutral comment-only changes do not invalidate
behavioral evidence. Directives, suppressions, pragmas, doctests, generated
inputs, shebangs, encoding declarations, and format-sensitive metadata do.

## Evidence

Emit the package digest on every result:

```text
REVIEW | <scope_mode> | <PASS|DISCHARGED> | state=<state_digest>
VERIFY | state=<state_digest> | {"command":"<command>","exit_code":0,"result":"<token>"}
```

Evidence is reusable only while the digest for the same owned paths remains
unchanged.

Record each dismissal and each plan correction as one ledger `Ruling:` line.
Return no reviewer transcript.
