---
description: Create plans and analyse for summarizing, refactoring, or improving
allowed-tools: >
  Read, Bash(ls:*), Bash(git status:*), Bash(git diff:*), Bash(git rev-parse:*),
  Write(./plan-*)
---

You won't make any changes, just create a detailed plan with actionable steps.

Be concise, clear, and structured.

Avoid filler words and generic content like: should do, could do, etc.

I want it to be very specific, actionable, and direct like: install X, run Y,
create Z, remove A, refactor B to do C, etc.

Make it a numbered todo-list, so it's possible to stop and continue from any
step, or refine and increase the number of steps.

Nested lists are allowed and if they are actionable, they should also be
numbered following the parent: `1.1`, `1.2`, `1.1.1`, etc.

Nested lists that are only for explanation or context should use dashes `-`

Don't include a "next steps" section.

Use markdown format with headings, subheadings, and bullet points, use emojis
when appropriate.

Use relative location like "at the top", "at the bottom", "in the middle",
"after the imports", "inside of the function FOO", etc.

Write the plan to a markdown file, derive the file name from the goal and prefix
it with `plan-`, the file should be saved next to the selected file, or in the
current working directory.
