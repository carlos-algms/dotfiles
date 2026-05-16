---
name: replying-to-pr-review-threads
description: >
  Use when a `discussion_rNNN` URL anchor appears, when replying to a specific
  PR review comment (CodeRabbit, human reviewer), reading all reviews on a PR
  with their replies as a tree, or resolving review threads from the CLI.
  Triggers on "reply to coderabbit", "answer this review comment", "read all
  reviews on PR", "show review threads", "resolve this thread".
---

# PR review threads

A PR has three independent comment surfaces. Cover all three to "read all
reviews".

| Stream                | What it is                                         | How to read               |
| --------------------- | -------------------------------------------------- | ------------------------- |
| PR conversation       | Top-level issue comments                           | `gh pr view N --comments` |
| Review summaries      | Body of each "Approve / Request changes / Comment" | `gh pr view N --comments` |
| Inline review threads | Diff comments + replies, grouped by file/line      | GraphQL `reviewThreads`   |

`gh pr comment` writes only to stream 1. There is no native `gh` subcommand for
reading nested inline threads or replying to one (cli/cli#12273). Use `gh api`.

URL anchor: `pull/N#discussion_rNNN` -> `NNN` is the comment's REST `id` and
GraphQL `databaseId`.

## Account check (do this first)

Multiple gh accounts (work + personal). Verify before any write.

```bash
gh auth status
gh auth switch --user <login>   # if wrong account
```

Set and forget. No restore.

## Reading all reviews on a PR

```bash
# Streams 1 + 2
gh pr view N --comments

# Stream 3: inline threads as a tree
gh api graphql -f query='
  query($owner:String!,$repo:String!,$num:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$num){
        reviewThreads(first:100){
          nodes{
            id isResolved isOutdated path line
            comments(first:50){
              nodes{ databaseId author{ login } createdAt body url }
            }
          }
        }
      }
    }
  }' -f owner=OWNER -f repo=REPO -F num=N
```

`-F num=N` (typed Int), not `-f`.

Shape:

- Each `reviewThreads.nodes[]` is one diff-anchored thread.
- `comments.nodes[0]` is the original; `[1..]` are replies in order.
- `id` (`PRRT_*`) is the GraphQL thread ID, needed for resolve.
- `databaseId` is the REST id (the `NNN` in `discussion_rNNN`), needed to reply
  or to find a thread by URL.

Filter examples (`--jq`):

```bash
# Only unresolved threads
... --jq '.data.repository.pullRequest.reviewThreads.nodes
  | map(select(.isResolved|not))'

# Only CodeRabbit threads
... --jq '.data.repository.pullRequest.reviewThreads.nodes
  | map(select(.comments.nodes[0].author.login == "coderabbitai"))'

# Find the GraphQL thread.id given a discussion_rNNN
... --jq --argjson id NNN '.data.repository.pullRequest.reviewThreads.nodes[]
  | select(.comments.nodes[].databaseId == $id) | .id'
```

## Replying to a thread

```bash
gh api repos/OWNER/REPO/pulls/comments/NNN \
  --jq '{id, path, body: (.body|.[0:200])}'

gh api repos/OWNER/REPO/pulls/N/comments/NNN/replies \
  -X POST \
  -f body="$(cat <<'EOF'
Reply body. Markdown OK.
EOF
)" --jq '.html_url'
```

### Replying to an AI reviewer (CodeRabbit, Claude, etc.)

AI reviewers persist your reply as a learning for future reviews (CodeRabbit
shows an "✏️ Learnings added" block confirming it). Write the reply so the
stored learning is correct AND generalizable.

- Terse and low word count: Facts + rationale, no pleasantries, no closing.
- Lead with the conclusion ("Skipping. YAGNI." / "Applied as suggested.").
- Give the verifiable evidence: command run, files inspected, why the rule
  applies or doesn't.
- Phrase the rationale in terms that generalize beyond this file/line. "For sync
  helpers in this codebase, ..." beats "for `with_modifiable`, ...". The
  reviewer copies your wording into the learning - narrow phrasing produces a
  one-off rule.
- If the AI reviewer should change behavior next time, say so directly. ("Grep
  callers before flagging defensive guards on sync helpers.")
- Do not include code blocks or diffs unless correcting the suggestion. The
  thread already has the suggested code.

## Resolving a thread

REST has no resolve endpoint. Mutation needs the GraphQL thread `id` (`PRRT_*`),
not the REST comment id - look it up via the `reviewThreads` query above.

```bash
gh api graphql -f query='
  mutation($id:ID!){
    resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } }
  }
' -f id=PRRT_xxxx
```

## Common mistakes

| Mistake                                                       | Symptom                                  | Fix                                              |
| ------------------------------------------------------------- | ---------------------------------------- | ------------------------------------------------ |
| Used `repos/.../pulls/{n}/comments/{id}` to fetch one comment | 404 Not Found                            | Drop the `/{n}`: `repos/.../pulls/comments/{id}` |
| Used `POST /pulls/{n}/comments` with `in_reply_to`            | 422 "in_reply_to is not a permitted key" | Use `/pulls/{n}/comments/{id}/replies`           |
| Passed numeric ID with `-f`                                   | 422 "not a number"                       | Use `-F`                                         |
| Resolving with the REST comment id                            | GraphQL: invalid ID                      | Look up `thread.id` (`PRRT_*`) via reviewThreads |
