# acli reference

Verified against `acli` 1.3.39 on Jira Cloud. Substitute `{project_key}` before
running.

## Quick reference

| Operation  | Command                                                                          |
| ---------- | -------------------------------------------------------------------------------- |
| View       | `acli jira workitem view {project_key}-N`                                        |
| View (all) | `acli jira workitem view {project_key}-N --fields '*all' --json`                 |
| Search     | `acli jira workitem search --jql "project = {project_key} AND ..." --limit 20`   |
| Create     | `acli jira workitem create --from-json /dev/stdin --json`                        |
| Edit       | `acli jira workitem edit --from-json /dev/stdin --yes`                           |
| Assign     | `acli jira workitem assign --key {project_key}-N --assignee <email\|@me> --yes`  |
| Transition | `acli jira workitem transition --key {project_key}-N --status "In Progress"`     |
| Comment    | `acli jira workitem comment create --key {project_key}-N --body-file <adf.json>` |

`--from-json /dev/stdin` accepts a pipe, so no temp file is needed.

## Verified behavior

- Create JSON takes `projectKey`, `type`, `summary`, `parentIssueId` (works for
  a Task under an epic), `labels`, `assignee`, `additionalAttributes` (team and
  sprint custom fields), `description` (ADF).
- Create JSON `assignee` takes an email. `"@me"` there is accepted and assigns a
  different user. Never send it.
- `create --from-json ... --assignee @me` exits 0 and silently drops the flag.
  Put the email in the JSON.
- `--assignee @me` works on `assign` and on `edit` flags.
- `/dev/stdin` works for `create --from-json`, `edit --from-json`, and
  `comment create --body-file`. Empty stdin errors with `json: invalid format`
  and creates nothing.
- Link: `workitem link create --out A --in B --type Blocks` makes A "is blocked
  by" B (confirmed in the Jira UI). `--in` is the blocker, `--out` the blocked
  ticket, matching REST `inwardIssue` and `outwardIssue`. The success message
  prints `A Blocks B`, which is the reverse; ignore it.
  `view --fields issuelinks` shows `inwardIssue: B` on A.
  `link list --key K --json` returns `issueLinks[]` with `id` and `typeName`;
  `link delete --id <id>` removes one.
- Nested `taskList` (a `taskList` after its parent `taskItem`) is accepted by
  `create` and `edit` and stored as sent.
- Edit JSON takes `issues`, `summary`, `description`, `assignee`, `labelsToAdd`,
  `labelsToRemove`. No `additionalAttributes`, so team and sprint cannot change
  on an existing ticket (see `mcp.md`).
- One `edit` call applies summary, description (ADF), assignee and labels
  together, by flags (`--summary --description-file --assignee --labels`) or by
  JSON.
- `edit` and `comment create` accept ADF files: `--description-file`,
  `--body-file`.
- `acli create` is not idempotent. Before retrying a create, search by summary
  under the parent.
- `--generate-json` prints the schema:
  `acli jira workitem create|edit --generate-json`.

## Pitfalls

- `acli jira workitem edit` prompts y/N; pass `--yes` for non-interactive runs.
- Transition `--status` needs an exact status name and `acli` cannot list the
  allowed ones. Take it from the team's `statuses` map in `jira-data.yaml`.
- `transition --status "Won't Do"` fails with
  `Please add your comment with explanation why you're changing status to 'Won't Do'`.
  A comment added beforehand does not satisfy it, and `transition` has no
  comment flag, so `acli` cannot reach `Won't Do`. Other statuses may have the
  same rule; unverified. The MCP transition call takes a comment (verified, see
  `mcp.md`).
- `link delete` prompts; pass `--yes`.
- No `acli jira me`. Your email lives in `jira-data.yaml` as `my_email`.
- No `acli api` raw REST passthrough, and the OAuth token cannot be reused with
  `curl`.
- Resolve the active sprint id at runtime (SKILL.md); never reuse
  `{refinement_sprint_id}` for it.

## Create JSON template

Prefer `scripts/md2adf.py --format acli-create`, which builds this.

```json
{
  "projectKey": "{project_key}",
  "type": "Task",
  "summary": "Ticket title",
  "parentIssueId": "{project_key}-NNN",
  "labels": ["ai-assisted"],
  "assignee": "me@example.com",
  "additionalAttributes": {
    "{team_field}": "{team_id}",
    "{sprint_field}": {refinement_sprint_id}
  },
  "description": { "type": "doc", "version": 1, "content": [] }
}
```

## Edit JSON template

Prefer `scripts/md2adf.py --format acli-edit`, which builds this.

```json
{
  "issues": ["{project_key}-N"],
  "summary": "New title",
  "assignee": "me@example.com",
  "labelsToAdd": ["a"],
  "labelsToRemove": ["b"],
  "description": { "type": "doc", "version": 1, "content": [] }
}
```
