---
description: Review the current branch compared to main or master
---

Act as the orchestrator. Delegate actual code reviews to the "code-reviewer"
subagent via the Task tool.

## Input Handling

- If I provide specific files, review only those
- Otherwise, get the full list of changed files (no output limits)
- Default target branch: `origin/HEAD`
- Always pass relative file paths to subagents

Process git diff/log internally; do not include raw output in responses.

## File Management

Three files are used:

| File                | Purpose                      |
| ------------------- | ---------------------------- |
| `review_context.md` | Shared context for subagents |
| `review_files.md`   | Todo list of files to review |
| `review_result.md`  | Aggregated review results    |

If `review_files.md` exists with unchecked items, continue from where it left
off. Otherwise, prompt the user to start fresh (yes = default).

## Shared Context Preparation

Before launching subagents, create `review_context.md` with:

- Type of overall changes
- Brief summary of changes and the intended purpose of the branch
- Config file changes (package.json, tsconfig.json, etc.) excluding dependencies
- Common types, and interfaces, added or removed, and where to find them
- Renamed symbols across files
- Import graph: which files import changed files (including unchanged importers)

Exclude: images, lock files, binary files, generated files.

Include any additional context subagents will need. Pass the path to each
subagent: "Review context available at: review_context.md"

## Review Files List

Format for `review_files.md`:

```md
- [ ] relative/path/to/file1.ext
- [ ] relative/path/to/file2.ext
```

No additional content. No line length limits.

## Review Results

Format for `review_result.md`:

- First header: `# Code Review [date] [time] [branch name]`
- Only include sections for files with suggestions

## Review Process

1. Create files if they do not exist

2. Filter out before review (mark as checked immediately):
   - Lock files (package-lock.json, pnpm-lock.yaml, etc.)
   - Generated files (dist/, build/, .next/)
   - Binary files, images
   - Files with only whitespace changes (`git diff --ignore-all-space`)

3. For each file:
   - Launch subagent with target branch and relative file path
   - Write received response to `review_result.md` immediately (no batching)
   - Do not transform or clean subagent responses
   - Mark item as checked: `- [x] path/to/file.ext`

4. Response requirements:
   - NO praise, positive comments, or benefits
   - ONLY issues, problems, or suggestions for improvement
