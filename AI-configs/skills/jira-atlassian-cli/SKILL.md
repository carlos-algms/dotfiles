---
name: jira-atlassian-cli
description: |
  Load before any Jira interaction or Atlassian MCP call. Holds required
  field values (team ID, sprint IDs, custom field mappings) unavailable
  elsewhere; skipping causes missing fields on created tickets. Triggers: Jira
  URLs, ticket keys (e.g. ABC-123), Atlassian/Jira MCP tools, acli, or
  keywords create/read/edit/search/transition, ticket, Jira, issue, sprint,
  backlog, refinement, work item.
---

# Jira Tools

## Team Context (load before any Jira call)

Private team values live in `~/OneDrive/work/contexts/jira-data.yaml`.

- Read the ENTIRE file once per session. No partial reads; risks missing
  `my_team` (pointer to default team key) or mixing cross-team values.
- Resolve team: user-named team, else top-level `my_team` field.
- Substitute placeholders from resolved team: `{cloud_id}`, `{project_key}`,
  `{team_field}`, `{team_id}`, `{sprint_field}`, `{refinement_sprint_id}`,
  `{active_sprint_board_id}`, and workflow statuses `{status_ready_for_dev}`,
  `{status_blocked}`, `{status_in_progress}`, `{status_in_review}`,
  `{status_done}`, `{status_wont_do}` (from the team's `statuses` map).
  Top-level `my_email` is the user's own email.
- File missing: ask user. Do not guess. End turn.

### Active (current) sprint is NOT constant

- `{refinement_sprint_id}` is stable; the active sprint id rotates every sprint.
- Never hardcode the active sprint id. Resolve it at runtime from the constant
  board `{active_sprint_board_id}` (flag is `--id`, the board id):

  ```bash
  acli jira board list-sprints --id {active_sprint_board_id} --state active --json
  ```

  Read `id` from the single active sprint. Pass it as `--sprint <id>` to the
  script. Do NOT use search with `customfield_10020`; it is rejected.

## Tool Priority

`acli` first, for reads, search, create, edit, assign, comment, and transition.
Make each write one `acli` call. Do not create and then edit to add fields.

## acli gaps (MCP fallback)

Use Atlassian/Jira MCP only for what `acli` cannot do. Recipes and payloads are
in `references/mcp.md`:

- Remove or change the parent of an existing ticket (`edit` has no parent)
- Team or sprint on an existing ticket (`edit` JSON rejects custom fields)
- Transition to `{status_wont_do}` (needs a comment inside the transition;
  generate the comment ADF with `scripts/md2adf.py`, never by hand)

A new gap: say so to the user, use MCP once, then record the recipe in
`references/mcp.md`. No MCP tools in the session: abort and explain.

## Write tickets with `scripts/md2adf.py`

Paths are relative to this skill's directory. The script turns Markdown into ADF
(Jira rich text) and wraps it as an `acli` payload. It is pure: no network, same
input gives identical output, so it is safe to rerun. Do not read its output.

How to run it:

- Write the Markdown body in a heredoc and pipe the script into `acli`
  (`/dev/stdin`)
- Lines between `<<'EOF'` and the closing `EOF` are literal text fed to the
  script's stdin. They are not shell commands
- The command is the line with `<<'EOF'`; the trailing `\` continues it onto the
  `| acli ...` line, then the body starts
- Run it as one bash call. Do not save it to a script file
- If the script fails it writes nothing, `acli` rejects the empty input
  (`json: invalid format`), and no ticket is created

- Checkboxes: `- [ ]` open, `- [x]` done, nesting allowed
- Smart link: `<https://{cloud_id}/browse/{project_key}-NNN>`
- Also supported: tables, fenced code, nested lists, blockquote, rule, bold,
  italic, strike, inline code, links, and `:::panel` / `:::expand` containers
- Not supported: images, raw HTML blocks, bullets or code under a checklist
  item, tables or headings inside list items. The script exits 2 with
  `line N: ...` on stderr and writes nothing

Create (one call; defaults to team `my_team`, sprint `refinement`, type `Task`):

```bash
scripts/md2adf.py --format acli-create --summary "Title" \
  --parent {project_key}-NNN --label ai-assisted <<'EOF' \
  | acli jira workitem create --from-json /dev/stdin --json | jq -r .key
## Context

- [ ] Acceptance criterion
EOF
```

Body from an existing Markdown file (for example a refined, approved ticket):
pass the path as the last argument and drop the heredoc. Do not read the file;
the script reads it, so its content never enters the context. The same works for
edit and comment.

```bash
scripts/md2adf.py --format acli-create --summary "Title" \
  --parent {project_key}-NNN --label ai-assisted ticket.md \
  | acli jira workitem create --from-json /dev/stdin --json | jq -r .key
```

Flags:

- `--assignee me`: your `my_email`
- `--assignee <email>`: another person
- Never `--assignee @me`: in JSON it assigns another person
- `--sprint <id>`: the active sprint
- `--team <key>`: another team
- `--type <type>`: issue type. Keep the default `Task` unless the user names
  another type
- `--label <name>`: repeatable

`acli create` is not idempotent. Before retrying a failed create, search by
summary under the parent.

Edit (one call; body, summary, assignee, labels together):

```bash
scripts/md2adf.py --format acli-edit --issues {project_key}-N \
  --summary "New title" --assignee me --label-add x --label-remove y <<'EOF' \
  | acli jira workitem edit --from-json /dev/stdin --yes
New body
EOF
```

Edit cannot change parent, team, or sprint; see "acli gaps".

The edit payload replaces the whole description. To change part of an existing
description, see "Change part of an existing description".

Change the type of one or more tickets (no script):

```bash
acli jira workitem edit --key {project_key}-A,{project_key}-B --type Task --yes
```

### Change part of an existing description

Never rebuild an existing description from `acli jira workitem view` output: it
is plain text and drops links, code marks, checkboxes and panels. Patch the
stored ADF instead; this is the only safe path that keeps formatting.

1. Save the stored ADF to a scratch file. Do not print it:
   `acli jira workitem view {project_key}-N --fields description --json | jq .fields.description > desc.json`
2. Find the target node by its top-level index:
   `jq -c '.content | map(.type)' desc.json`
3. Generate the new nodes with the script (bare ADF), never by hand:
   `scripts/md2adf.py -o new.json <<'EOF'` with the Markdown fragment, for
   example one bullet or one checkbox
4. Splice and send in one pipe. Example, append the new bullets to the list at
   index `I`:

   ```bash
   jq --slurpfile new new.json \
     '.content[I].content += $new[0].content[0].content' desc.json \
     | jq '{issues: ["{project_key}-N"], description: .}' \
     | acli jira workitem edit --from-json /dev/stdin --yes
   ```

   A new section (heading plus list) goes in as whole top-level nodes:
   `.content |= .[:I] + $new[0].content + .[I:]`

5. Verify with `acli jira workitem view {project_key}-N --fields description`
   and search the output for the new text

Comment, or an MCP description (default format is bare ADF):

```bash
scripts/md2adf.py <<'EOF' \
  | acli jira workitem comment create --key {project_key}-N --body-file /dev/stdin
Comment text
EOF
```

For MCP, run the script alone and pass the output as `description` with
`contentFormat: "adf"`. Use `-o <file>` to write a file instead of stdout.

Script fails or a node is missing: read `references/adf.md` and
`references/md2adf.md`. Do not hand-write ADF unless the script cannot emit the
node. Splicing script output into stored ADF with `jq` is not hand-writing (see
"Change part of an existing description").

## AI Disclosure (label only)

Apply this section ONLY when a global, enterprise, or company rule requires AI
disclosure. Otherwise add no label and no disclaimer.

- Disclose with the `ai-assisted` label only, and only on issues you create:
  `--label ai-assisted` on the script
- Editing or commenting on an existing issue: add no label and no disclaimer
- Never add an AI disclaimer, banner, or footer to a summary, description, or
  comment

## Ticket framing (summary = deliverable, not motivation)

The summary and description must describe the WORK to be done, not the event
that prompted it. A PR, bug sighting, or incident is the MOTIVATION; it belongs
in the description as context, never as the headline.

- Wrong: "Remove duplicate handler type in chat-embedded (PR #2100)" — that
  frames a one-off PR fix when the actual deliverable was a review-rule
  enhancement.
- Right: "Enhance AI-review duplication rule: same-app scope + near-dup
  detection" — names the durable change; the PR is one motivating line in the
  body.

Before creating: ask "what is the lasting deliverable?" If the summary names a
PR/ticket/incident as its subject, rewrite it to name the change instead.

## Common Workflows

### Read a ticket from a URL

Extract the key from `https://{cloud_id}/browse/{project_key}-NNN`, then
`acli jira workitem view {project_key}-NNN`. Add `--fields '*all' --json` for
all fields.

### Search team tickets

```bash
acli jira workitem search --jql "project = {project_key} AND status = 'New'" --limit 20
acli jira workitem search --jql "project = {project_key} AND sprint = {refinement_sprint_id}" --limit 50
```

### Assign, transition

```bash
acli jira workitem assign --key {project_key}-N --assignee @me --yes
acli jira workitem assign --key {project_key}-A,{project_key}-B --remove-assignee --yes
acli jira workitem transition --key {project_key}-N --status "{status_in_progress}"
```

- `@me` is valid on `assign` and on `edit` flags only
- Transition `--status` takes the exact name from the `statuses` map
- Never guess a status name
- A name missing from the map: ask the user
- `acli` cannot list allowed transitions
- A wrong name fails with `No allowed transitions found`
- `{status_wont_do}` needs a comment inside the transition, which `acli` cannot
  send (see "acli gaps")

### Link tickets

```bash
acli jira workitem link create --out {project_key}-A --in {project_key}-B --type Blocks
```

- With `--type Blocks`, `--in` is the blocker and `--out` is the blocked ticket
- `--out A --in B` makes A "is blocked by" B
- The success message prints the reverse (`A Blocks B`); ignore it
- List link types: `acli jira workitem link type`
- List links of a ticket: `acli jira workitem link list --key K --json`
- Remove a link: `acli jira workitem link delete --id <id> --yes`

## References

Do not load these in normal operation. Load one only to identify and debug a
failure.

- `references/acli.md` - verified `acli` behavior, pitfalls, JSON templates
- `references/adf.md` - ADF node shapes, debugging rejected nodes
- `references/md2adf.md` - exact Markdown grammar the script accepts
- `references/mcp.md` - MCP recipes for the acli gaps, subtasks, link types
