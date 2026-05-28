---
name: review-branch
description: >
  Review current branch changes against a target branch. Use when the user asks
  to review a branch, review changed files, compare current work to main, origin
  HEAD, or master, or run a file-by-file code review with aggregated markdown
  results.
---

# Review branch

Act as orchestrator.

Delegate actual code review to `code-reviewer` subagents when available.

If named subagents are unavailable, use the generic subagent mechanism and pass
the code-reviewer constraints from local agent definitions when present.

## Input handling

- If user provides files, review only those files
- Otherwise, review full changed-file list
- Default target branch: `origin/HEAD`
- Pass relative file paths to subagents
- Process git diff and log internally
- Do not include raw git output in chat responses

## Files

Use three repo-root files:

| File                | Purpose                      |
| ------------------- | ---------------------------- |
| `review_context.md` | Shared context for subagents |
| `review_files.md`   | Todo list of files to review |
| `review_result.md`  | Aggregated review results    |

If `review_files.md` exists with unchecked items, continue from it.

Otherwise ask whether to start fresh.

## Shared context

Before launching subagents, create `review_context.md` with:

- Type of overall changes
- Brief summary of branch purpose
- Config file changes excluding dependencies
- Common changed types or interfaces as file paths only
- Renamed symbols across files
- Import graph for changed files, including unchanged importers
- Additional context subagents need

Exclude images, lock files, binary files, and generated files.

Tell each subagent:

```text
Review context available at: review_context.md
```

## Review file list

Format `review_files.md` exactly:

```markdown
- [ ] relative/path/to/file1.ext
- [ ] relative/path/to/file2.ext
```

No extra content.

## Review result

Format `review_result.md`:

- First heading: `# Code Review [date] [time] [branch name]`
- Include sections only for files with suggestions

## Review process

1. Create missing review files
2. Mark filtered files checked immediately
3. Launch subagent per file
4. Write each response to `review_result.md` immediately
5. Do not transform subagent responses
6. Mark reviewed file checked

Filter out:

- Lock files
- Generated files
- Binary files
- Images
- Files with only whitespace changes

## Subagent execution

- Run subagents in foreground
- To review multiple files concurrently, send multiple subagent calls in one
  response when runtime supports parallel subagents
- Wait for all results before continuing

## Response requirements

- No praise
- No positive comments
- No benefits section
- Only issues, problems, or suggestions for improvement
