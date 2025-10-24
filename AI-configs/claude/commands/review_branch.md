---
description: Review the current branch compared to main or master
allowed-tools: >
  Bash(ls:*), Bash(git diff:*), Bash(git log:*), Bash(git status:*), Read,
  Write(./review_result.md), Edit(./review_result.md),
  MultiEdit(./review_result.md), Bash(pnpm dlx prettier --write
  review_result.md)
---

IMPORTANT: For this task You MUST ask the "code-reviewer" subagent for
performing the actual code review! Do NOT perform code reviews yourself.

You'll be the orchestrator of the review process.

If I give you a specific file name, or a list of files, review only that,
otherwise You should get the list of changed files.

If you need to get the list of changed files, don't limit the output, get the
full list, even if it's long, I want a complete code review, unless I specify
otherwise.

If I don't give you a target branch, use `origin/HEAD` as the target branch,
provide it and the relative file path to the subagent, never use absolute paths,
always relative paths.

Hide the output of the git commands and file reads to avoid noise in the chat
history.

## Shared Context Preparation

To save some tokens, and read operations, before launching subagents, create a
shared context file to simplify the investigation work of the subagents.

This file must be named `review_context.md`.

Run a preliminary analysis to build the context with these steps:

- The type of the overall changes
- Check if package.json, tsconfig.json, or similar config files changed
- Package.json changes
  - Don't include dependencies, dev or peer, so the subagents aren't confused if
    they need to review them
- Common typescript type definitions, that will be needed by multiple files
  being reviewed, to save reads for the subagents
- Renamed symbols across files
- A minimal graph of which files import each other files, including non-changed
  files importing the changed files
- Don't include information about lock files, binary files, etc.

Be smart and identify what's is going to be needed by the subagents when they
are doing the code review, don't be limited to my list of step.

Write a very brief summary of the changes, and your analysis to the file.

Pass the file path to each subagent via the prompt: "Review context available
at: <actual relative file path>"

## File Management

Use 2 files:

- `review_result.md` for the review results you get from the subagents
- `review_files.md` for the list of files to review.

IMPORTANT: If the file already exists, check for unchecked items and continue
the review process only if there are any unchecked, otherwise ask the user if
they want to start fresh and empty the file, not remove it. Give the user an
yes/no prompt, with your default confirmation prompt, where they can press 1, 2,
or enter to confirm, yes should be the default pre-selected option.

### The review results file

- The very first header, should be  
  "# Code Review [date] [current time] [branch name]"
- If there are not suggestions for a file, don't add a section for it, so the
  file is smaller.

### The files list file

- It should be a clean list with the Markdown todo list format, like this:
  ```md
  - [ ] relative/path/to/file1.ext
  - [ ] relative/path/to/file2.ext
  ```
- Don't add anything else to the file.
- Don't limit the number of characters per line, as the file names can be long

## Review Process

1. First, create the files if they don't exist

2. Before launching subagents, filter out:
   - Lock files (package-lock.json, pnpm-lock.yaml, etc.)
   - Generated files (dist/, build/, .next/)
   - Files with only whitespace/formatting changes (check git diff
     --ignore-all-space)
   - Mark filtered files as reviewed with '✓' immediately

3. Do not review lock files, binary files, or images, immediately mark them as
   reviewed without suggestions

4. For each file reviewed:
   - Write to the files immediately, don't batch writes
   - Do not clean, or transform the responses you receive, just write to the
     file as your received from the subagent
   - **Ensure responses contain NO praise, positive comments, or benefits of the
     changes**
   - **Reviews should ONLY contain issues, problems, or suggestions for
     improvement**
   - Mark the todo item as checked
     ```md
     - [x] path/to/file.ext
     - [x] path/to/another_file.ext
     ```
