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
- Count commits in the branch range before composing the PR
- For a one-commit branch, use that commit's subject and body as the PR title
  and body without shortening or rewriting them
- A repository template may place the commit body inside required sections, but
  preserve its wording and complete every required section
- For a multi-commit branch, treat individual commits, plans, and initial file
  lists as incomplete summaries
- Detect uncommitted changes; they are not part of the PR
- Detect unpushed commits and whether the branch has an upstream
- Refresh branch, base, remote, diff, and push state before generating commands

## Content

- Title for a one-commit branch: use the commit subject unchanged
- Title for a multi-commit branch: imperative, no more than 70 characters, and
  lowercase after the colon
- Body with template: fill it without dropping required sections
- Body without template: use concise prose, bullets, or both
- Prefer a bullet when it conveys the same fact with fewer words
- Paragraphs: no more than 25 words each
- First paragraph: state only context that is clearer than a bullet
- Second paragraph: add only mandatory, important information not captured in
  the first paragraph or bullets
- Never add a second paragraph for padding, hedging, or unnecessary explanation
- Third paragraph: add only mandatory, important information not captured in the
  first two paragraphs or bullets
- Put one blank line between paragraphs and before the bullet list
- Keep bullet items consecutive, without blank lines between them
- Bullets: no more than 10 words
- State each fact once: in prose or a bullet, never both
- Describe only the merge-ready final state. Omit temporary status, pending
  work, and anything expected to change or be removed before merge
- Omit standard, expected, or self-evident information
- Unless the user explicitly requests it, omit testing probes, strategies,
  commands, validation methods, and validation results
- Standard Markdown only: no em-dashes or curly quotes
- Draft status: plain "create PR" means draft; ready requires an explicit
  request
- Issue links: use repository conventions and closing keywords only for issues
  this PR resolves

No-template body example:

```markdown
Explain why the change matters and its impact.

- Describe reviewer-relevant behavior
- Call out important constraints or decisions
- Fixes #123
```

Include only relevant bullets. Use `Fixes #123` for resolved issues and
`Related: #123` for non-closing links, and `Closes #123` for superseded PRs.

## Workflow

1. Resolve current branch, remote, upstream, base branch, and draft status
2. Read the full `git diff <base>...HEAD` and `git log <base>..HEAD`, then count
   commits in that range
3. Inspect uncommitted and unpushed state
4. For one commit, reuse its subject and body; for multiple commits, load
   `git-commit-message` in `pr-title` mode and compose from the complete branch
5. Apply the repository template when present without shortening reused commit
   content
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
