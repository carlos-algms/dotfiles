---
name: open-code-review
description: >
  Review a PR, branch, commit range, or uncommitted work with the `ocr` CLI,
  producing a local report to triage before anything is posted. Optionally
  triage the findings in `crit`, then post what the user agrees to. Triggers on
  "ocr", "open code review", "ocr review", "review this PR with ocr", "review my
  changes with ocr", "PR review duty", "generate a review report".
---

# Open Code Review

`ocr` reviews a diff and writes findings locally. Triage, posting and fixing are
separate steps, and each one needs the user's word.

## Read-only is absolute

A review produces findings. It never produces edits.

For the whole of a review, whoever wrote the code:

- Do NOT edit, create, delete, format or rename any file
- Do NOT run a formatter, a linter with `--fix`, or a codemod
- Do NOT commit, stage, push, or amend
- Do NOT run the test suite, the build, or `check-types`
- Do NOT apply a finding, not even a one-character typo, not even when the fix
  is obvious and the finding is certainly correct

The user decides what changes. A finding that reads "just add the missing
variable" is still a finding, and it stays a finding.

The only exception is a direct imperative from the user in the current turn:
"fix finding 3", "apply that". A "yes" to a question you asked is not that
imperative unless the question named the exact edit. When in doubt, ask.

The repository validation gate (prettier, eslint, check-types) exists for code
changes. A review makes none, so the gate does not apply. Do not run it "to be
safe". Never run a test suite to check a claim in the PR description; if a claim
matters and is unverified, that is itself a finding.

Reading is unrestricted: any file, `git log`, `git diff`, `git show`,
`gh pr view`, `rg`, `fd`. Read as much as the review needs.

Reviewing someone else's PR adds: never push to their branch, never
`gh pr edit`, never resolve their threads, never delete their remote branch.

Never switch the user's branch to review something. Ask before checking anything
out, and use a worktree if they ask for one.

## The flow

```text
1. ocr review        -> findings JSON
2. verify            -> drop what does not hold
3. crit  (OPTIONAL)  -> user triages, asks questions, you answer
4. post   (GATED)    -> only what the user agreed keeps
```

Steps 3 and 4 each need the user's word. Never chain into them.

## Step 1: run ocr

| Want         | Mode              |
| ------------ | ----------------- |
| Speed        | A: `ocr review`   |
| No API spend | B: `ocr delegate` |

Mode A runs `ocr`'s own agent on its configured provider, up to 8 file groups
concurrently, and bills that account. Mode B uses this session's LLM and is
serial.

Targets, both modes:

| Target           | Flags                                                      |
| ---------------- | ---------------------------------------------------------- |
| Uncommitted work | none (default)                                             |
| Current branch   | `--from origin/HEAD --to HEAD`                             |
| Someone's PR     | check out the PR head, then `--from origin/main --to HEAD` |
| One commit       | `--commit <hash>`                                          |
| A commit range   | `--from <base-sha> --to <head-sha>`                        |

Workspace mode (no ref flags) covers staged, unstaged and untracked together.
There is no staged-only flag; narrow with `--exclude`. `--from`/`--to` take SHAs
as well as branch names, and review the merge-base diff, not each commit.

```bash
ocr review --from origin/main --to HEAD \
  --audience agent --format json --output review.json \
  -B background.md
```

`--background` is the biggest quality lever. Keep it **under 2000 characters** —
`ocr` warns above that and quality degrades. A PR body is usually too long and
mostly irrelevant: write a short brief saying what the change is for and what to
focus on. For a large deletion say so explicitly ("verify the deletion is
complete and no caller is left dangling"), or `ocr` spends its budget on prose.

| Flag                         | Why                                       |
| ---------------------------- | ----------------------------------------- |
| `--audience agent`           | Summary only; `human` streams progress UI |
| `--effort high`              | 3 review rounds instead of 2              |
| `--exclude '**/generated/*'` | Skip vendored or generated noise          |
| `--resume <session-id>`      | Recover an interrupted run                |

Never pipe to `head` or `tail`; either drops findings. Use `--output`.

### Mode B: ocr delegate

No LLM is called on the `ocr` side. It supplies the file list and the rules;
this session reads the diffs and does the reviewing.

```bash
ocr delegate preview --format json    # add ref flags for non-workspace targets
ocr delegate rule --format json <paths from preview>
```

Review every `reviewable_files` entry against its rule group. Mark each reviewed
or skipped with a concrete reason, never silently dropped. Use `(path, status)`
as the identity: workspace mode can list one path twice when a staged deletion
is followed by an untracked recreation.

## Step 2: verify before showing anything

`ocr` findings are hypotheses. Check each against the code before it reaches the
user or crit.

- Trace the claim. A "silently falls back" finding is wrong if every caller is
  already guarded upstream
- Drop what does not hold, and say what you dropped and why
- Split a finding that is half right: keep the true half, drop the rest
- `start_line` and `end_line` both `0` means positioning failed. Find the real
  location and give it

Recall is deliberately lower than a general-purpose agent: `ocr` trades it for
precision. A clean report means "no mechanical defects found", not "reviewed".
Requirement coverage is never checked unless `--background` said what mattered.

Watch for one style rule firing per occurrence. That is one preference, not N
defects. Say so, and name the rule file — often `~/.opencodereview/rule.json`,
not the repo.

## Step 3: crit triage (OPTIONAL, always ask)

Never start crit unprompted. Ask:

> N findings. Triage them in crit first, or report them here?

Only on yes:

```bash
jq '[.comments[] | {
  path,
  line: (if .start_line > 0 then .start_line else 1 end),
  end_line: (if .end_line > 0 then .end_line else null end),
  author: "ocr",
  body: "**[\(.severity)] \(.category)**\n\n\(.content)"
} | with_entries(select(.value != null))]' review.json > crit-import.json

crit comment --json --file crit-import.json    # headless, writes only
crit status                                    # get the session id
crit --session <id>                            # NOW it opens in the browser
```

Three things that will bite:

- `crit comment --json` is **headless**. It writes a review file and exits. The
  user sees nothing until `crit --session <id>`. Do not say "open crit" and stop
- `crit --range` creates a **new empty session** instead of attaching to the one
  holding the comments. Always attach by session id
- `severity` and `category` are not crit fields; fold them into the body

Verify the anchors landed before handing over:

```bash
crit comments --json | jq -r '.[] | "\(.path):\(.start_line)  \(.anchor[0:60])"'
```

### The answer loop

When the user closes crit, read the state with `crit comments --json`. Findings
they resolved are dropped, permanently, no argument.

For every finding still unresolved, read their replies:

- A question: **answer it** with evidence via `crit comment --reply-to <id>`,
  after verifying against the code
- A rejection: drop the finding, say you did
- A partial rejection: keep the half that holds, say which
- A changed ask: rewrite the finding to what they actually want

**A comment stays only when the user agrees it stays.** Keep answering until
they do. An unanswered question, or an open disagreement, is not ready to post.
Never treat silence as agreement, and never post a finding still under argument.

Resolve a thread yourself only when their reply told you to drop it, and say
what you did in the reply before resolving.

## Step 4: post (GATED, never automatic)

Never post without being asked. Post **one review** containing all inline
comments: it arrives as one notification and creates threads that can be replied
to and resolved.

Be accurate about the shape: this produces **N separate top-level threads**, one
per finding, not one thread with N nested comments. GitHub has no
nested-under-a-review shape; nesting happens only when someone replies.

Show the exact list and ask the event every time. Do not default it:

```text
Post 4 findings to PR #3393?
  A: COMMENT
  B: REQUEST_CHANGES
  C: don't post
```

Docs and style findings rarely justify blocking a merge. Say so if the user
picks REQUEST_CHANGES for those, then do as they say.

Check the head SHA still matches, or the line numbers are stale:

```bash
gh pr view <PR> --json headRefOid -q .headRefOid
git rev-parse HEAD
```

GitHub rejects inline comments on lines outside the diff. Verify each target is
an added line:

```bash
git diff -U0 origin/main...HEAD -- <file> | \
  awk '/^@@/{split($3,a,","); ln=substr(a[1],2)+0; next} /^\+/{print ln; ln++}'
```

A finding about an unchanged line goes on the nearest added line, with the real
location named in the body.

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

Posting uses the user's `gh` token, so it lands as them. Say so before the call.
`gh pr review` posts only a body with no inline comments, so it cannot do this.
Reading or replying to existing threads is `replying-to-pr-review-threads`.

Verify afterwards:

```bash
gh api repos/{owner}/{repo}/pulls/<PR>/comments \
  --jq '.[] | select(.pull_request_review_id==<id>) | "\(.path):\(.line)"'
```

## Reading ocr output

Each comment carries `path`, `content`, `start_line`, `end_line`, `category`
(bug, security, performance, maintainability, test, style, documentation, other)
and `severity` (critical, high, medium, low).

Report critical and high always, medium with context, and drop low unless
clearly valuable.

## Rules files

`~/.opencodereview/rule.json` is the user's global rule set and already covers
markdown. Per-repo overrides go in `<repo>/.opencodereview/rule.json`, or
`--rule <path>` for one run.

When a rule produces a flood of near-identical findings, name the file and line
so the user can edit it. That is worth more than triaging the flood.

## Gotchas

- `ocr` runs against the git repo in the current directory. `--repo <path>`
  overrides
- Diffs over 50 changed lines trigger an extra risk-analysis phase: slower,
  better
- `crit comment --clear` deletes every comment in the review, not just yours
- The crit daemon outlives the turn. `crit stop --all` when the user is done
- Never read or print the tool's own config files. They hold live credentials,
  and anything printed lands in the transcript permanently. Nothing in a review
  needs them: if a config value genuinely matters, ask the user. A partial
  redact is not enough, since one wrong field name leaks the whole line
- Missing `ocr`: `pnpm add -g @alibaba-group/open-code-review`, or
  `brew install open-code-review`
- Missing `crit`: `brew install crit`
