# MCP fallback reference

Use the Atlassian/Jira MCP only when `acli` cannot do the job. Pass
`cloudId: "{cloud_id}"` on every call. Tool names depend on the session; pick
the Atlassian/Jira tools that are available. No such tools: abort and explain.

## Recipes for acli gaps

Verified on Jira Cloud. After any MCP write, confirm with `acli` (the MCP
response omits many fields).

- **Remove the parent** (`acli edit` has no parent field): `editJiraIssue` with
  `fields: {"parent": null}`. Confirm with
  `acli jira workitem view K --fields parent --json`. Works on tickets in
  `Won't Do`.
- **Transition to `Won't Do`** (needs a comment inside the transition; `acli`
  has no comment flag): `getTransitionsForJiraIssue`, then `transitionJiraIssue`
  with `transition: {id: "71"}` and the comment as ADF:

  ```json
  {
    "transition": { "id": "71" },
    "update": {
      "comment": [
        {
          "add": {
            "body": {
              "type": "doc",
              "version": 1,
              "content": [
                {
                  "type": "paragraph",
                  "content": [{ "type": "text", "text": "Reason" }]
                }
              ]
            }
          }
        }
      ]
    }
  }
  ```

  Id `71` is the `Won't Do` transition (status id `10239`) from `New`. Other
  statuses and source states may use other ids; read them from the available
  transitions.

- **Team or sprint on an existing ticket**: `acli edit --from-json` rejects
  `additionalAttributes` (`json: unknown field`) and `acli` has no sprint-move
  command. Use `editJiraIssue` with `additional_fields` (see below). Unverified.
- `acli` fails or is unavailable.

## Create and edit notes

- `contentFormat: "adf"` required when the description has acceptance criteria
  or any checklist. Pass ADF JSON as the `description` string; generate it with
  `scripts/md2adf.py` (default format).
- `contentFormat: "markdown"` for simple descriptions (headings, bold, lists,
  links, no checklists).
- Set team and sprint through `additional_fields`:

  ```json
  "additional_fields": {
    "{team_field}": "{team_id}",
    "{sprint_field}": {refinement_sprint_id}
  }
  ```

- Epic link: `"parent": "{project_key}-NNN"`.
- API response body is unreliable for verifying rendering. Create/edit/get
  responses echo `description` as markdown even when sent or requested as ADF
  (including `responseContentFormat: "adf"`); ADF features (checkboxes, expand,
  panels) appear flat in the echo but render correctly in Jira. Verify by
  opening the issue URL.
- `expand` IS valid in issue ADF. `editJiraIssue` `INVALID_INPUT` almost always
  means a structural error in a sibling node, not `expand`. Most common:
  paragraph-wrapped `taskItem.content` (see `adf.md`).

## Parent / epic

- Create: `"parent": "{project_key}-NNN"`.
- Edit: `editJiraIssue` with `fields: {"parent": {"key": "{project_key}-NNN"}}`.

## Subtasks

Create with `issueTypeName: "Sub-task"` and `parent: "{project_key}-NNN"`. Same
`parent` field as epic linking; the issue type decides subtask vs epic child.

## Sprint field

`{sprint_field}` takes a plain integer, not an object:

```json
"{sprint_field}": {refinement_sprint_id}
```

NOT `{ "id": ... }` (errors with "Number value expected as the Sprint id").

## Issue linking

Prefer `acli jira workitem link create --in BLOCKER --out BLOCKED --type Blocks`
(verified, see `acli.md`). The table lists link type names for
`createIssueLink`. The "Blocks" direction note below matches the verified `acli`
result (`--in` = `inwardIssue` = blocker) but has not been tested through MCP.

| Name          | Inward (passive) | Outward (active) |
| ------------- | ---------------- | ---------------- |
| **Blocks**    | is blocked by    | blocks           |
| **Relates**   | relates to       | relates to       |
| **Duplicate** | is duplicated by | duplicates       |
| **Fixes**     | is fixed by      | fixes            |
| **Improves**  | is improved by   | improves         |

Directionality for "Blocks": `inwardIssue` = blocker, `outwardIssue` = blocked.
A blocks B:

```text
inwardIssue: "{project_key}-A", outwardIssue: "{project_key}-B", type: "Blocks"
```
