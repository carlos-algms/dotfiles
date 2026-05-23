# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (general-purpose):
  Use template at requesting-code-review/code-reviewer.md

  DESCRIPTION: [one-line task summary]
  PLAN_OR_REQUIREMENTS: Task <task_id> from <plan_path>
  BASE_REF: [branch base or commit SHA before task]
  CHANGED_FILES: [paths from `git status --porcelain` for this task]

  Reviewer reconstructs the diff itself:
    - Committed: `git diff <BASE_REF>...HEAD -- <CHANGED_FILES>`
    - Staged:    `git diff --cached -- <CHANGED_FILES>`
    - Unstaged:  `git diff -- <CHANGED_FILES>`
    - Untracked: read each path in <CHANGED_FILES> not tracked by git
```

**Also check (beyond standard code quality):**

- One responsibility per file, well-defined interface
- Units independently understandable and testable
- File structure matches the plan
- Growth caused by THIS change (don't flag pre-existing file sizes)

**One-hop scope:**

- Identify exported/changed symbols in `<CHANGED_FILES>`
- `rg --hidden -F '<symbol>'` to find importers/callers
- Read each one-hop caller file; flag quality issues caused by the change
- Do not flag pre-existing quality issues in caller files unrelated to the
  change

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor),
Assessment
