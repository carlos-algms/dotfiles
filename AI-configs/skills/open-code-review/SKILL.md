---
name: open-code-review
description: >
  Review a PR, branch, commit range, or uncommitted work with the `ocr` CLI,
  producing a local report to triage before anything is posted. Triggers on
  "ocr", "open code review", "ocr review", "review this PR with ocr", "review my
  changes with ocr", "PR review duty", "generate a review report".
---

# Open Code Review

`ocr` reviews a diff and writes findings locally. It never posts to GitHub and
never edits files. Posting and fixing are separate, explicit steps below.

## Pick a mode

| Want         | Mode              |
| ------------ | ----------------- |
| Speed        | A: `ocr review`   |
| No API spend | B: `ocr delegate` |

Mode A runs `ocr`'s own agent on the key in `~/.opencodereview/config.json`, up
to 8 file groups concurrently. Mode B uses this session's LLM and is serial.

## Choosing the target

Both modes take the same target flags:

| Target           | Flags                                                            |
| ---------------- | ---------------------------------------------------------------- |
| Uncommitted work | none (default)                                                   |
| Current branch   | `--from origin/HEAD --to HEAD`                                   |
| Someone's PR     | `gh pr checkout <PR>` first, then `--from origin/HEAD --to HEAD` |
| One commit       | `--commit <hash>`                                                |
| A commit range   | `--from <base-sha> --to <head-sha>`                              |

The default with no ref flags is workspace mode: staged, unstaged, and untracked
together. There is no staged-only flag; narrow with `--exclude` or stash the
rest.

`--from`/`--to` take SHAs as well as branch names, so a range covers every
commit a subagent produced: `--from $(git rev-parse HEAD~3) --to HEAD`. Range
mode reviews the merge-base diff, not each commit separately.

## Mode A: ocr review

Uncommitted work, the common case:

```bash
ocr review --audience agent --format json --output review.json \
  --background "Refactoring the retry loop to use exponential backoff"
ocr viewer
```

A PR:

```bash
gh pr checkout <PR>
ocr review --from origin/HEAD --to HEAD \
  --audience agent --format json --output review.json \
  --background "$(gh pr view <PR> --json title,body -q '.title + "\n" + .body')"
ocr viewer
```

`--background` is the biggest quality lever: without it `ocr` reviews the diff
with no idea what the change was for. It takes any free text: the intent, the
ticket, what to focus on, what to ignore. `-B <file.md>` reads it from a file
instead; its limits are 1 MiB raw and 8000 characters sanitised.

`ocr viewer` serves the saved session at `localhost:5483`, where comments can be
marked fixed or ignored while working through them.

Useful flags:

| Flag                         | Why                                                                  |
| ---------------------------- | -------------------------------------------------------------------- |
| `--audience agent`           | Summary only; `human` streams progress UI that pollutes agent output |
| `--effort high`              | 3 review rounds instead of 2                                         |
| `--exclude '**/generated/*'` | Skip vendored or generated noise                                     |
| `--resume <session-id>`      | Recover an interrupted run                                           |
| `--format sarif`             | Findings inline in the editor                                        |
| `--tools <file.json>`        | Override the embedded tool config                                    |

## Mode B: ocr delegate

No LLM is called on the `ocr` side. It supplies the file list and the rules;
this session reads the diffs and does the reviewing.

```bash
ocr delegate preview --format json          # uncommitted; add ref flags for other targets
ocr delegate rule --format json <paths from preview>
```

`preview` returns the mode and refs needed to build the git commands, plus the
reviewable and excluded file lists. Then:

- Review every `reviewable_files` entry against its rule group
- Mark each one reviewed, or skipped with a concrete reason
- Never silently drop a file
- Use `(path, status)` as the identity, since workspace mode can list one path
  twice when a staged deletion is followed by an untracked recreation

## Reading the output

Each comment carries `path`, `content`, `start_line`, `end_line`, `category`
(bug, security, performance, maintainability, test, style, documentation, other)
and `severity` (critical, high, medium, low).

Report critical and high always, medium with context, and drop low unless
clearly valuable.

Recall is deliberately lower than a general-purpose agent: `ocr` trades it for
precision. Treat a clean report as "no mechanical defects found", not as
"reviewed". Requirement coverage is never checked unless `--background` said
what was required.

## Rules

`~/.opencodereview/rule.json` already includes markdown and gives it a docs
review rule, so no flag is needed. Per-repo overrides go in
`<repo>/.opencodereview/rule.json`, or `--rule <path>` for one run.

## Posting to GitHub

Never post without being asked. When asked, post one review containing all
inline comments, not separate comments: a review creates threads that can be
replied to and resolved, and it arrives as a single notification.

Show the selected findings and get explicit approval before the call.

```bash
gh api repos/{owner}/{repo}/pulls/<PR>/reviews \
  --method POST --input review-payload.json
```

```json
{
  "body": "Summary line.",
  "event": "COMMENT",
  "comments": [
    { "path": "src/auth.ts", "line": 42, "side": "RIGHT", "body": "..." },
    {
      "path": "src/db.ts",
      "start_line": 10,
      "line": 14,
      "side": "RIGHT",
      "body": "..."
    }
  ]
}
```

`line` is the line in the head commit's file, `side: "RIGHT"` the post-change
side. Add `start_line` for a range. `event` is `COMMENT`, `APPROVE`, or
`REQUEST_CHANGES`.

`gh pr review` posts only a body, with no inline comments, so it cannot do this.
Reading or replying to existing threads is `replying-to-pr-review-threads`.

## Fixing

Reviewing someone else's PR: report only, never edit.

Reviewing own code and asked to fix: confirm first, naming the exact scope, for
example `Apply 4 fixes across 2 files: src/auth.ts, src/db.ts? (y/n)`. Fix
critical and high; describe medium fixes needing judgement rather than guessing.
Re-run the project's gate afterwards.

## Gotchas

- Never pipe to `head` or `tail`; either one drops findings. Use `--output` and
  read the file
- `start_line` and `end_line` both `0` means positioning failed. Read the
  comment, find the location, report the real one
- Set `language` to `English` in config; it defaults to Chinese
- `ocr` runs against the git repo in the current directory. `--repo <path>`
  overrides
- Diffs over 50 changed lines trigger an extra risk-analysis phase: slower,
  better
- Missing `ocr`: `pnpm add -g @alibaba-group/open-code-review`, or
  `brew install open-code-review`
