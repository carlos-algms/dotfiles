---
description: Create a conventional message but don't commit
---

You're only going to generate the conventional commit message, don't commit.
Follow the standard conventional commit message generation protocol.

If the selected file is `.git/COMMIT_EDITMSG`, I use the verbose commit command,
so all the information you need to create a good commit message is there, this
is usually a long file, so you can ignore spell and other linter issues.

Otherwise, follow these steps to deeply understand the changes:

1. Determine scope:
   - If there are staged files: ONLY use those files
   - If no staged files: use all changes in this branch compared to the default
     branch (usually `main` or `master`)
2. **CRITICAL**: Read the complete diffs (not just filenames) for ALL files in
   scope to understand what was introduced, modified, and removed
3. Analyze previous commits in the current branch (not on main) to understand
   the development progression
4. Identify the core intention and goals behind the changes, ignoring minor
   implementation details (new functions, validations, unit tests, etc.)

**Message format**:

- Bullet point list ONLY (no bold, no italics, no code blocks)
- Few words per line (3-7 words maximum)
- Focus on main features, goals, and branch intention
- Omit minor changes like "added validation", "introduced tests", "refactored X"
- Capture the "why" not the "what"

If the selected file is `.git/COMMIT_EDITMSG`, apply the message to the top of
the file, otherwise just send me the generated text as a normal message.
