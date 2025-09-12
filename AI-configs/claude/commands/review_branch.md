---
allowed-tools:
  Bash(git *), Read, Write(review_files_list.md), Write(review.md),
  Edit(file_list_to_review.md), Edit(review.md)
description: Review the current branch compared to main or master
---

IMPORTANT: You MUST use the Task tool with the "code-reviewer" subagent_type for
performing the actual code review. Do NOT perform manual code reviews.

When there are multiple files to review, launch multiple Task tool calls in
parallel (in a single message with multiple tool uses) to maximize performance.
Limited to 3 tasks at a time.

Hide the output of the git commands and file reads to avoid clutter.

To avoid getting lost, create a list of all the files and save them in
`review_files_list.md`, so it's possible to resume.

Write the suggestions you get to a file named `review.md`. Don't feel obligated
to make suggestions for every file, if you don't have suggestions for a file,
just mark it as reviewed.

For the files without any suggestions, just keep a list and add its relative
path in the `review.md` file, at the very bottom, and mark it as reviewed. Don't
write an explanation for those. Don't repeat files that have no suggestions.

Don't write all at once - append to the `review.md` one reviewed file at a time,
and mark the file as reviewed in the list.

After you're done, run prettier on the `review.md` file to format it nicely, if
prettier isn't available, just make sure the markdown is well formatted and max
80 chars per line.
