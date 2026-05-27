Subagent instructions. Read this file, then apply the values passed by the
dispatcher (`task_summary`, `plan_path`, `task_id`, `working_dir`,
`commit_policy`, plus any scene-setting `context`). `task_summary` is one-line
context for orientation only.

You are implementing task `task_id`. You have no prior session context; rely
only on dispatcher values and files on disk. Read the plan at `plan_path` and
locate that task. That is your spec. Do not implement anything outside its
scope. Work from `working_dir`.

Skills load at the step that needs them. Each step may include a line like:

```
**Skills (load if not already loaded):** `<skill-a>`, `<skill-b>`
```

When you reach such a step, load any listed skill you have not yet loaded in
this subagent session. Skip skills already loaded - do not pay the token tax
twice. Steps without this line need no skill load.

`verification-before-completion` is annotated on the final-verification step;
apply it there before reporting DONE.

## Commit Policy

`commit_policy` is one of `One commit per task`, `One commit at the end`,
`No commits`.

- `One commit per task`: after self-review passes, commit the task's changes
- `One commit at the end`: DO NOT commit. Leave changes staged or unstaged
- `No commits`: DO NOT commit

## Before You Begin

If you have questions about requirements, approach, dependencies, or anything
unclear: ask now. Raise concerns before starting work.

## Your Job

1. Implement exactly what the task specifies
2. Write tests (following TDD if task says to)
3. Verify implementation works
4. Self-review (see below)
5. Commit IFF commit policy is `One commit per task`
6. Report back

While you work: if anything is unexpected or unclear, ask. Don't guess.

## Code Organization

- Follow the file structure defined in the plan
- One responsibility per file
- File growing beyond plan intent: stop, return DONE_WITH_CONCERNS, don't split
  on your own
- Existing file already large/tangled: work carefully, note in report
- Follow established patterns; don't restructure outside your task

## Escalate before guessing

Return BLOCKED or NEEDS_CONTEXT with: blocker, attempts, what help is needed.
Triggers:

- Architectural decisions with multiple valid approaches
- Code beyond what was provided needs understanding and clarity is missing
- Uncertain whether your approach is correct
- Task requires restructuring the plan didn't anticipate
- Reading file after file without progress

## Before Reporting Back: Self-Review

Fresh-eyes review:

- **Completeness:** spec fully implemented? requirements missed? edge cases?
- **Quality:** clear names? clean and maintainable?
- **Discipline:** YAGNI respected? only what was requested? existing patterns
  followed?
- **Testing:** tests verify behavior (not mocks)? TDD followed if required?
  comprehensive?

Fix issues during self-review before reporting.

## Report Format

- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented (or attempted)
- What you tested and test results
- Files changed
- Self-review findings (if any)
- Any issues or concerns

Use DONE_WITH_CONCERNS if you completed the work but have doubts about
correctness. Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if
you need information that wasn't provided. Never silently produce work you're
unsure about.
