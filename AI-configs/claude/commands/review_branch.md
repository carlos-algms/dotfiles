---
allowed-tools: >
  Bash(ls:*), Bash(git diff:*), Read, Write(./review.md), Edit(./review.md),
  MultiEdit(./review.md), Bash(pnpm dlx prettier --write review.md)
description: Review the current branch compared to main or master
---

IMPORTANT: You MUST use the Task tool with the "code-reviewer" subagent_type for
performing the actual code review! Do NOT perform manual code reviews.

If I give you a specific file name, review only that file, otherwise You should
get the list of changed files, don't try to read the files or analyze diffs
yourself.

Use `origin/HEAD` as the target branch, provide it and the file name to the Task
tool.

When there are multiple files to review, launch multiple Task tool calls in
parallel (in a single message with multiple tool uses) to maximize performance.
Limited to 5 tasks at a time.

Hide the output of the git commands and file reads to avoid clutter.

## File Management

Use a single `review.md` file for both tracking and results.

- At the BOTTOM of the file, maintain a "## Files to Review" section with the
  complete list
- Use standard todo-list markdown format.
- Add status icons: "✓" for no suggestions, "󰟶" for files with suggestions.
- NEVER remove this section - always keep it at the bottom of the file
- Append review results above this section, one file at a time
- The very first header, should be "# Review [date] [time] [branch name]"

IMPORTANT: If the file already exists, check for unchecked items and continue
the review process only if there are any unchecked, otherwise ask the user if
they want to start fresh and empty the file, not remove it.

## Review Process

1. First, create `review.md` with the initial structure:
   - Review results will go at the top
   - "## Files to Review" section at the bottom with all files from git diff
   - Format: `- [ ] path/to/file.ext`
   - Do not review lock files, binary files, or images, immediately mark them
     checked without suggestions

2. For each file reviewed:
   - Append suggestions above the "Files to Review" section
   - Do not clean, or transform the suggestions you receive, just put them as
     your received from the Task tool
   - Mark the todo item as checked, and for files without suggestions add "✓" or
     "󰟶" if there are suggestions

     ```
     <example>
     - [x] 󰟶 path/to/file.ext
     - [x] ✓ path/to/another_file.ext
     </example>

     ```
