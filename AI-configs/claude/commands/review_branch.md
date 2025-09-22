---
allowed-tools: >
  Bash(ls:*), Bash(git diff:*), Bash(git log:*), Bash(git status:*), Read,
  Write(./review.md), Edit(./review.md), MultiEdit(./review.md), Bash(pnpm dlx
  prettier --write review.md)
description: Review the current branch compared to main or master
---

IMPORTANT: You MUST use the Task tool with the "code-reviewer" subagent_type for
performing the actual code review! Do NOT perform manual code reviews.

Don't try to read the files or analyze diffs yourself.

If the user give you a specific file name, or a list of files, review only that,
otherwise You should get the list of changed files.

If the user doesn't give you a target branch, use `origin/HEAD` as the target
branch, provide it and the relative file name to the Task tool, never use full
paths.

When there are multiple files to review, launch multiple Task tool calls in
parallel (in a single message with multiple tool uses) to maximize performance.
Limited to 2 tasks at a time. Don't create batches if you can, as soon as one
reviewer finishes, launch a new one until all files are reviewed to finish as
fast as possible.

Hide the output of the git commands and file reads to avoid clutter.

## File Management

Use 2 files `review_result.md` for the review results you get from the Task
tool, and `review_files.md` for the list of files to review.

IMPORTANT: If the file already exists, check for unchecked items and continue
the review process only if there are any unchecked, otherwise ask the user if
they want to start fresh and empty the file, not remove it. Give the user an
yes/no prompt, with your default confirmation prompt, where they can press 1, 2,
or enter to confirm, yes should be the default pre-selected option.

### For the review results file

- The very first header, should be  
  "# Code Review [date] [current time] [branch name]"
- If there are not suggestions for a file, don't add a section for it, to the
  file is smaller.
- Respect indentation and limit to 80 characters per line

### The file list file

- It should be a clean list with the Markdown todo list format, like this:
  ```
  - [ ] relative/path/to/file1.ext
  - [ ] relative/path/to/file2.ext
  ```
  Don't add anything else to the file.
- Don't limit the number of characters per line, as the file names can be long

## Review Process

1. First, create the files if they don't exist

2. Do not review lock files, binary files, or images, immediately mark them as
   reviewed without suggestions

3. For each file reviewed:
   - Write to the files immediately, don't batch writes
   - Do not clean, or transform the responses you receive, just write to the
     file as your received from the Task tool
   - Mark the todo item as checked, and for files without suggestions add "✓" or
     "󰟶" if there are suggestions

     ```
     - [x] 󰟶 path/to/file.ext
     - [x] ✓ path/to/another_file.ext
     ```
