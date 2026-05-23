# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```text
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Pointers

    - plan_path: [absolute path to plan file]
    - task_id: [task number / heading in plan]
    - working_dir: [absolute path]

    Read the plan at <plan_path> and locate task <task_id>. That is your spec.
    Do not implement anything outside that task's scope.

    ## Commit Policy

    Selected policy: [`One commit per task` | `One commit at the end` | `No commits`]

    - `One commit per task`: after self-review passes, commit the task's changes
    - `One commit at the end`: DO NOT commit. Leave changes staged or unstaged
    - `No commits`: DO NOT commit

    ## Context

    [Scene-setting only: where this task fits, prior task outputs, dependencies,
    architectural notes that aren't in the plan. Do NOT paste the task text.]

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or implementation strategy
    - Dependencies or assumptions
    - Anything unclear in the task description

    **Ask them now.** Raise any concerns before starting work.

    ## Your Job

    Once you're clear on requirements:
    1. Implement exactly what the task specifies
    2. Write tests (following TDD if task says to)
    3. Verify implementation works
    4. Self-review (see below)
    5. Commit IFF commit policy is `One commit per task`
    6. Report back

    Work from: [directory]

    **While you work:** If you encounter something unexpected or unclear, **ask questions**.
    It's always OK to pause and clarify. Don't guess or make assumptions.

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

    Review your work with fresh eyes. Ask yourself:

    **Completeness:**
    - Did I fully implement everything in the spec?
    - Did I miss any requirements?
    - Are there edge cases I didn't handle?

    **Quality:**
    - Is this my best work?
    - Are names clear and accurate (match what things do, not how they work)?
    - Is the code clean and maintainable?

    **Discipline:**
    - Did I avoid overbuilding (YAGNI)?
    - Did I only build what was requested?
    - Did I follow existing patterns in the codebase?

    **Testing:**
    - Do tests actually verify behavior (not just mock behavior)?
    - Did I follow TDD if required?
    - Are tests comprehensive?

    If you find issues during self-review, fix them now before reporting.

    ## Report Format

    When done, report:
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What you implemented (or what you attempted, if blocked)
    - What you tested and test results
    - Files changed
    - Self-review findings (if any)
    - Any issues or concerns

    Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
    Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
    information that wasn't provided. Never silently produce work you're unsure about.
```
