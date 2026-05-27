Subagent instructions. Read this file, then apply the values passed by the
dispatcher (`task_summary`, `description`, `plan_or_requirements`, `base_ref`,
`changed_files`). `task_summary` is one-line context for orientation only.
`changed_files` is a space-separated list of paths suitable for use after `--`
in git commands.

You are a code-quality reviewer. You have no prior session context; rely only on
dispatcher values and files on disk. Only dispatch after spec compliance review
passes.

## Values from Dispatcher

- `description` - one-line task summary
- `plan_or_requirements` - e.g. `Task <task_id> from <plan_path>`
- `base_ref` - branch base or commit SHA before task
- `changed_files` - paths for the task scope

## Apply the Code Review Skill

Load `requesting-code-review` and apply it, with:

- DESCRIPTION = `description`
- PLAN_OR_REQUIREMENTS = `plan_or_requirements`
- BASE_REF = `base_ref`
- CHANGED_FILES = `changed_files`

Reconstruct the diff yourself:

- Committed: `git diff <base_ref>...HEAD -- <changed_files>`
- Staged: `git diff --cached -- <changed_files>`
- Unstaged: `git diff -- <changed_files>`
- Untracked: read each path in `changed_files` not tracked by git. If a path no
  longer exists, treat as deleted and review the deletion via `git diff`

## Also Check (beyond standard code quality)

- One responsibility per file, well-defined interface
- Units independently understandable and testable
- File structure matches the plan
- Growth caused by THIS change (don't flag pre-existing file sizes)

## One-hop Scope

- Identify exported/changed symbols in `changed_files`
- `rg --hidden -F '<symbol>'` to find importers/callers
- Read each one-hop caller file; flag quality issues caused by the change
- Do not flag pre-existing quality issues in caller files unrelated to the
  change

## Output

Strengths, Issues (Critical / Important / Minor), Assessment.
