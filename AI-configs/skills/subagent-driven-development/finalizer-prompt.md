Apply dispatcher values: `plan_path`, `working_dir`, `plan_base_ref`,
`baseline_snapshot`, `milestone_execution_mode`, and optional
`milestone_finalize_grant`.

Own the remaining written plan-level checkpoints. The orchestrator only relays
your result. Operate in `working_dir`.

The plan owns the final workflow. Execute its checkpoints in written order. Do
not add a review, verification, or commit step that the plan does not contain.

Resolve prompt paths relative to this file:

- Reviewer: `reviewer-prompt.md`
- Quality checklist: `../requesting-code-review/code-reviewer.md`

## Workflow

1. Read the complete plan
2. Read the commit policy
3. Read the plan-file policy and `Additional plan state files`
4. Read the convention sources
5. Read `Solved defects` and `Execution log`
6. Locate the remaining plan-level checkpoints
7. Stop when the plan lacks its final-verification checkpoint
8. Execute the written final-verification checkpoint:
   1. Derive the complete changed-path set from current repository state
   2. Exclude baseline-only paths from review scope
   3. Exclude `execution-state` paths from review scope
   4. Dispatch the written full-plan review
   5. On findings, verify each citation
   6. Stop before editing a baseline-only fix path in commit-bound execution
   7. Uncheck affected plan state
   8. Uncheck the conditional final-review-fixes commit checkpoint before the
      first fix under `Per-task commits`
   9. Fix each substantiated finding
   10. Update `Solved defects`
   11. Run only the affected narrow gates
   12. Re-tick verified task state
   13. Re-dispatch the review after a fix round containing any `behavioural`
       finding. After an all-`static` fix round, the green narrow gates are the
       verification: do not re-dispatch
   14. Require `PASS`
   15. Load `verification-before-completion`
   16. Run each written final automated check once
   17. Perform each written final manual check once
   18. Append final-review drift, gotchas, and decisions to `Execution log`
   19. Tick the final-verification checkpoint
9. Execute each remaining written commit checkpoint
10. When the plan requests a PR and the branch contains the reviewed committed
    work, load `create-pull-request` and complete it
11. Return only the output contract below

## Milestone handshake

When the written final-verification checkpoint contains the milestone `READY` ->
`FINALIZE` -> `FINALIZED` handshake:

- Resolve the stable plan ID from the written checkpoint
- Missing `milestone_execution_mode`: use `sequential`. Invalid value: return
  `BLOCKED`
- `milestone_execution_mode = sequential`: execute the written milestone update
  without handshake messages
- `milestone_execution_mode = coordinated` with no matching
  `milestone_finalize_grant`: complete all preceding review and validation
  actions, leave the final-verification checkpoint unticked, record the reviewed
  implementation paths and plan file with their hashes, modes, and deletion
  states in `baseline_snapshot/milestone-ready.json`, retain
  `baseline_snapshot`, and return only `READY <plan ID>`
- Redispatch with exact `FINALIZE <plan ID>`: require
  `baseline_snapshot/milestone-ready.json` and re-derive its recorded state.
  Resume at the milestone update without repeating unchanged work. When an
  implementation path or the plan file drifted, repeat affected review and
  validation before continuing; return `BLOCKED` on baseline-only or unsafe
  drift
- Mismatched grant: return `BLOCKED` without editing plan state
- Successful milestone update: emit `MILESTONE | FINALIZED <plan ID>` in the
  final result
- Never self-grant or reuse a turn for another plan

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

`Plan state` means the plan file plus every `Additional plan state files` path.
Apply the single `Plan file policy` to the complete set. Before editing an
additional state file, execute its written ownership gate. Return `BLOCKED`
without editing that file when the plan permits concurrent execution but names
no exclusive owner or turn protocol.

When `No commits` and the plan requests a PR, return `BLOCKED` after successful
verification while reviewed plan changes remain uncommitted. Record and hand off
the exact plan-owned paths, hashes, modes, and deletion states in the owner-only
`baseline_snapshot/pr-handoff.json`; include plan state only when its policy is
`Include`. Return that path. On redispatch, require the manifest, reject any
baseline-only branch delta or mismatch, then return `PASS` without repeating
review or verification when the branch matches the reviewed manifest exactly.

Restore a pre-ticked checkpoint whenever scope resolution, staging, or commit
fails. Never use implementation file lists as plan-state commit scope. Include
all modified plan state only when `Plan file policy` is `Include`.

## Execution log

Append your own final-review findings to the plan's `Execution log` before
ticking the final-verification checkpoint. Same contract as the implementers:

- One line per entry:
  `final | <drift|gotcha|decision> | <what the plan assumed> | <what is true and what changed>`
- Append only. Never rewrite or delete an implementer's entry
- Log only cross-task drift, gotchas, and decisions that final review surfaced
- Nothing qualifies: write nothing and omit `LEARNED`. Never write `none`,
  `no drift`, or any "nothing found" line. A clean final review is silent
- Never log narration or findings already in `Solved defects`

Mirror each appended entry as a `LEARNED` line in your output.

## Reviewer rules

- Reviewers return only `PASS` or short findings
- Reviewers never edit, stage, or commit
- One clarification re-dispatch for an incorrect finding
- Empty, errored, or malformed responses get 3 total attempts
- A `<review-input>` finding is a failed dispatch; correct the payload
- Every finding carries a `static` or `behavioural` discharge tag. Never retag
  one yourself
- Any unresolved dispute, third failed dispatch, failed gate, unsafe scope, or
  third finding round returns `BLOCKED`

Review dispatch:

```text
MUST read instructions at <skill_dir>/reviewer-prompt.md FIRST.
Do not act until you have read it. Then apply:
  plan_path         = <abs path>
  task_id           = all tasks
  scope_mode        = complete
  base_ref          = <plan_base_ref>
  baseline_snapshot = <abs path to classified snapshot directory>
  changed_files     = <newline-delimited exact paths>
  solved_defects    = <plan list or `none`>
  checklist_path    = <abs path to quality checklist>
```

One reviewer answers both the craft and the spec question every pass. There is
no separate spec stage to re-run. Re-dispatch the same payload with the fixed
diff, narrowing `task_id` and `changed_files` to the affected work.

`<skill_dir>` is this file's directory. Use absolute resolved paths.

## Output

Success:

```text
PASS | final
VERIFY {"command":"<command>","exit_code":0,"result":"<success token>"}
VERIFY {"manual":"<check>","status":"PASS","observation":"<observation>"}
COMMITS | <sha[,sha...] | none>
PR | <url | none>
STATE | <comma-separated excluded modified plan-state paths>
MILESTONE | FINALIZED <plan ID>
FIXED
- <path:line> | <problem> | <fix>
LEARNED
- final | <drift|gotcha|decision> | <plan assumed> | <actual and change>
```

Emit one `VERIFY` line per final-verification command or manual check. Merge
duplicate `FIXED` root causes. Emit valid compact JSON and escape dynamic
strings; omit the manual form when no manual check exists.

Omit `FIXED` when no reviewer finding was fixed.

Emit `STATE` only when `Plan file policy` is `Exclude` and plan-state files were
modified. List exact repo-relative paths. Omit the line otherwise.

Emit `MILESTONE` only after the written milestone update passes. Omit it for
plans without that update.

`LEARNED` repeats exactly the entries you appended to the plan's
`Execution log`. Appended nothing: omit the whole block, header included. Never
emit `LEARNED` followed by `none` or an empty list. Report only your own
entries, not the implementers'.

Cannot continue:

```text
BLOCKED | final
HANDOFF | <manifest path, external-commit blocker only>
STATE | <comma-separated excluded modified plan-state paths>
MILESTONE | FINALIZED <plan ID>
- <problem> | need <specific input or action>
LEARNED
- final | <drift|gotcha|decision> | <plan assumed> | <actual and change>
```

The same rule applies on the blocked path: report `LEARNED` only when you
actually appended entries, and omit the block otherwise.

Waiting for a root coordinator turn:

```text
READY <plan ID>
```

`READY` is a resumable pause, not `BLOCKED`. Emit nothing else on that path.

No reviewer transcript, implementation diff summary, implementation file list,
or narration. `STATE` is the only plan-state file list.
