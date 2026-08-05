---
name: create-pull-request
description: >
  Compose and create GitHub pull requests with `gh` using the target
  repository's title, template, base-branch, and draft conventions. Load on
  explicit user intent to open, create, draft, or compose a pull request.
---

# GitHub pull requests

## Hard rules

- Never create a PR without an explicit user request
- A finished branch, plan, task, or job is not permission to create a PR
- Permission applies to one PR action; autonomous mode does not waive the gate
- Never include co-authors, AI attribution, or generated-by footers
- Never rewrite history before a PR: no `git rebase`, `commit --amend`,
  `push --force`, or `--force-with-lease`; push the branch as-is

## Repository conventions

1. Read target repository instructions and contribution docs
2. Use the repository PR template when present
3. Load `git-commit-message` in `pr-title` mode to compose the title
4. Detect the default base branch from the remote unless the user chose one

`git-commit-message` owns title format and scope inference. This skill adds no
merge-model convention.

## Source of truth

- Build PR content from the complete branch diff and commit range against the
  resolved base
- Treat the last commit, plans, and initial file lists as incomplete summaries
- Detect uncommitted changes; they are not part of the PR
- Detect unpushed commits and whether the branch has an upstream
- Refresh branch, base, remote, diff, and push state before generating commands

## Content

- Title: imperative, no more than 70 characters, and lowercase after the colon
- Body with template: fill it without dropping required sections
- Body without template: bullet list only; no headers or prose paragraphs
- Bullets: 3-7 words; capture the reason and user-visible behavior
- Standard Markdown only: no em-dashes or curly quotes
- Draft status: plain "create PR" means draft; ready requires an explicit
  request
- Issue links: use repository conventions and closing keywords only for issues
  this PR resolves

No-template body example:

```markdown
- Describe the user-visible change
- Explain why the change matters
- Verify with `command` before submission
- Fixes #123 for affected users
- Related work remains in #456
```

Include only relevant bullets. Use `Fixes #123` for resolved issues and
`Related: #123` for non-closing links, and `Closes #123` for superseded PRs.

## Workflow

1. Resolve current branch, remote, upstream, base branch, and draft status
2. Read the full `git diff <base>...HEAD` and `git log <base>..HEAD`
3. Inspect uncommitted and unpushed state
4. Load `git-commit-message` in `pr-title` mode and compose the PR title
5. Compose the body from the current diff and repository template
6. Show the exact title, body, upstream push command, and PR creation command
7. Get approval before pushing or creating the PR
8. After approval, run the shown commands with the title and body unchanged
9. Pass multiline body content through `--body-file -`
10. Add `--draft` unless the user explicitly requested a ready PR
11. Return the PR URL from `gh pr create`

Use a quoted heredoc to preserve multiline Markdown:

```bash
gh pr create --draft --base "main" --title "PR title" --body-file - <<'EOF'
- Describe the user-visible change
- Explain why the change matters
EOF
```

Replace example values with resolved values in actual commands. Shell-quote all
dynamic values for the active shell. Regenerate commands if the branch state or
content changes.

## Compose-only requests

Return the title and body without pushing or creating a PR.
