---
description: Create a conventional message but don't commit
---

You're only going to generate the conventional commit message, don't commit.
Follow the standard conventional commit message generation protocol.

If the selected file is `.git/COMMIT_EDITMSG`, I use the verbose commit command,
so all the information you need to create a good commit message is there, this
is usually a long file, so you can ignore spell and other linter issues.

Otherwise, follow these steps:

1. Check if there are staged files, if yes, ONLY use those files to create the
   commit message.
2. If there are no staged files, compare all changes in this branch with the
   default branch (usually `main` or `master`)

If the selected file is `.git/COMMIT_EDITMSG`, apply the message to the top of
the file, otherwise just send me the generated text as a normal message.
