---
name: git-commit-message
description: >
  Compose repository-compatible Git commit messages and exact commit commands
  from current repository state. Load on intent to commit, stage, compose a
  commit message, prepare a PR title, or edit `.git/COMMIT_EDITMSG`.
---

# Git commit messages

Caller mode: `commit` by default, `pr-title` when requested by
`create-pull-request`, or `draft` for message-only requests.

## Convention precedence

1. Current user request
2. Target repository `AGENTS.md`, `CLAUDE.md`, contribution docs, and tooling
3. First and subsequent commit defaults in this skill
4. Dominant style in recent relevant history

Always inspect branch history before composing a message. Repository rules
override this skill when they require a different format.

## Hard rules

- Never commit without an explicit user request
- Permission applies to one commit action; autonomous mode does not waive the
  gate
- Never rewrite history: no `git rebase`, `commit --amend`, `push --force`, or
  `--force-with-lease`
- Never use `git checkout`, `git revert`, or `git reset` to undo existing work
- Treat branch history as disposable because PRs squash-merge; push it as-is

## Current state is authoritative

- Derive the commit from the actual index and working tree at commit time
- Treat plans, task file lists, and earlier status snapshots as intent only
- Read full diffs; filenames and diff statistics are insufficient
- If the index contains changes, compose for the staged diff only
- If the index is empty, select paths from current changes and the requested
  scope
- If the staged set differs from the requested scope, stop the commit workflow
  until the set or requested scope is corrected
- Do not add unrelated staged or unstaged changes
- Recheck status and the staged diff immediately before committing
- Regenerate the message and commands when the commit set changed

## Branch position

Resolve the base branch and run `git rev-list --count <base>..HEAD` before each
commit:

- Count `0`: the next commit is the first commit; use the strict format below
- Count greater than `0`: use the subsequent commit format below
- On `main` or `master`: treat each commit as a first commit

Read recent target-branch subjects and all existing feature-branch commits. Use
them for context and to avoid repeating intent. Do not let later commits
override the first-commit format.

## First commit format

```markdown
type(scope): subject

- Explain why the change matters
- Describe the user-visible behavior
```

- Subject: imperative, lowercase after the colon, no more than 70 characters in
  total
- Body: optional bullet list only; no prose paragraphs, bold, italics, or code
  blocks
- Bullets: 3-7 words; capture the reason, not minor implementation details
- Body lines: no more than 72 characters
- Standard Markdown only: no em-dashes, curly quotes, or special characters
- Single-change commit: subject only

### Type

Infer the type from the diff. Ask when the type is unclear.

Common types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`,
`build`, `ci`, and `style`.

### Scope

Use this priority:

1. User-provided scope
2. Repository convention
3. Jira key matching `[A-Z]{3}-[0-9]+` from the branch name
4. Branch name, excluding `main` and `master`
5. Affected module or folder

Ask when no scope is available. Do not force a scope when repository rules ban
one.

## Subsequent commit format

- Bare imperative subject only
- No `type(scope):` prefix
- No body
- No more than 70 characters
- One change per commit

## GitHub references

Put issue and PR references in body bullets:

- Resolved issue: `Fixes #123`
- Superseded PR: `Closes #456`
- Non-closing link: `Related: #789`
- Cross-repository link: `org/repo#123`

Use closing keywords only when the commit resolves the referenced work.

## Composition

- Describe the coherent change represented by the commit
- Use issue-closing syntax only when the commit resolves that issue
- Include required sign-offs or trailers only when the target repository or user
  requires them
- Use branch history to avoid repeating intent already captured by earlier
  commits

In `pr-title` mode, compose the squash commit title for the complete branch
change. Apply the first-commit subject, type, and scope rules. Do not copy the
last commit blindly.

## Workflow

### Commit mode

1. Read target repository instructions and detected commit tooling
2. Resolve the base branch, count branch commits, and read commit history
3. Inspect `git status`, staged changes, unstaged changes, and untracked paths
4. Resolve the exact commit set from current state and requested scope
5. Read the full diff for that set
6. Compose the message for its branch position
7. Show the exact message and commands, then get approval
8. Recheck status and the staged diff after approval
9. Run the approved staging and commit commands with the message unchanged
10. Use `git commit -F-` with a quoted heredoc for multiline messages

Never emit placeholder paths or reuse a file list copied from a plan. Omit the
staging command when the intended commit set is already staged. Shell-quote
every actual path and message for the active shell.

### PR-title mode

1. Read the same target-repository convention sources
2. Resolve the PR base branch and current branch name
3. Read the complete branch diff and commit range against that base
4. Resolve type and scope from the complete branch change
5. Return only the squash commit title

Do not select index paths or generate staging or commit commands in this mode.

## Commit message file

When `.git/COMMIT_EDITMSG` is selected:

- Use the verbose diff already present in the file
- Ignore spell and lint findings in generated diff content
- Replace only the message section at the top
- Do not run `git commit`

## Draft mode

Return the message without running staging or commit commands.
