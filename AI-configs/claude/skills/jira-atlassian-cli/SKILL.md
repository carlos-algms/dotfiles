---
name: jira-atlassian-cli
description: |
  Load before any Jira interaction or mcp__atlassian__* call. Holds required
  field values (team ID, sprint IDs, custom field mappings) unavailable
  elsewhere; skipping causes missing fields on created tickets. Triggers: Jira
  URLs, ticket keys (e.g. ABC-123), MCP tools mcp__atlassian__*, acli, or
  keywords create/read/edit/search/transition, ticket, Jira, issue, sprint,
  backlog, refinement, work item.
---

# Jira Tools

## Team Context (load before any Jira call)

Private team values live in `~/OneDrive/work/contexts/jira-teams.yaml`.

- Read the ENTIRE file once per session. No partial reads; risks missing
  `my_team` (pointer to default team key) or mixing cross-team values.
- Resolve team: user-named team, else top-level `my_team` field.
- Substitute placeholders from resolved team: `{cloud_id}`, `{project_key}`,
  `{team_field}`, `{team_id}`, `{sprint_field}`, `{refinement_sprint_id}`.
- File missing: ask user. Do not guess. End turn.

## Tool Priority

Prefer MCP (`mcp__atlassian__*`) for everything. Supports markdown
(`contentFormat: "markdown"`) and full ADF (`contentFormat: "adf"`). Pass
`cloudId: "{cloud_id}"` on all MCP calls.

Use `acli` only when MCP cannot do the job, or not available (bulk ops, advanced
JQL export, edge cases).

## MCP Create/Edit Notes

- `contentFormat: "adf"` required when description contains acceptance criteria
  or any checklist. Jira markdown renders `- [ ]` as literal text in bullets,
  not checkboxes. Only `taskList`/`taskItem` ADF nodes produce real checkboxes.
- `contentFormat: "markdown"` for simple descriptions (headings, bold, lists,
  links, no checklists).
- `contentFormat: "adf"` for full control (checkboxes, panels, complex layouts).
  Pass ADF JSON as the `description` string.
- Always set team and sprint via `additional_fields`:

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
  paragraph-wrapped `taskItem.content` (see ADF Reference).

## ADF Reference (for `contentFormat: "adf"`)

Pass ADF JSON as the `description` value.

Canonical docs:
https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/.
Per-node spec at `.../document/nodes/<nodeName>/`.

### Debugging a node

1. Fetch the node spec for allowed `content`, `attrs`, `marks`:

   ```bash
   defuddle parse \
     "https://developer.atlassian.com/cloud/jira/platform/apis/document/nodes/<nodeName>/" \
     --md
   ```

2. Still rejected: isolate by replacing the suspect subtree with a minimal valid
   node (e.g. `taskList` -> `bulletList`). Success means the suspect is the
   cause. MCP errors usually name the offending node.

3. MCP-stricter-than-spec traps:
   - `taskItem.content`: bare inline nodes, NOT `paragraph`-wrapped. Same rule
     inside `expand`. See
     [atlassian/atlassian-mcp-server#25](https://github.com/atlassian/atlassian-mcp-server/issues/25)
     (also confirms markdown `- [ ]` does NOT auto-convert to `taskList`; send
     ADF).
   - `tableCell` / `tableHeader` / `panel` / `expand`: block-node children only;
     wrap raw text in `paragraph`.

### ADF Node Types

Use inside `description.content`:

- **Paragraph:**
  `{ "type": "paragraph", "content": [{ "type": "text", "text": "..." }] }`
- **Heading:**
  `{ "type": "heading", "attrs": { "level": 2 }, "content": [{ "type": "text", "text": "..." }] }`
- **Code block:**
  `{ "type": "codeBlock", "attrs": { "language": "tsx" }, "content": [{ "type": "text", "text": "..." }] }`
- **Bullet list:**
  `{ "type": "bulletList", "content": [{ "type": "listItem", "content": [{ "type": "paragraph", "content": [...] }] }] }`
- **Ordered list:**
  `{ "type": "orderedList", "content": [/* same as bulletList */] }`
- **Bold text:**
  `{ "type": "text", "text": "...", "marks": [{ "type": "strong" }] }`
- **Inline code:**
  `{ "type": "text", "text": "...", "marks": [{ "type": "code" }] }`
- **Task list (checkboxes):**
  `{ "type": "taskList", "attrs": { "localId": "ac-1" }, "content": [{ "type": "taskItem", "attrs": { "localId": "ac-1-1", "state": "TODO" }, "content": [{ "type": "text", "text": "..." }] }] }`

  Acceptance criteria MUST use `taskList`/`taskItem`, not `bulletList`.
  `taskItem.content` MUST be bare `text` nodes; paragraph-wrapping is rejected
  with `INVALID_INPUT` (see Debugging trap above).

- **Expand (collapsible section):**
  `{ "type": "expand", "attrs": { "title": "..." }, "content": [<block nodes>] }`
  Children: block nodes (`paragraph`, `bulletList`, `heading`, etc.). Use to
  hide long context (findings, traces) below the fold.

- **Inline smart link** (renders as Jira card / Notion preview / any URL):
  `{ "type": "inlineCard", "attrs": { "url": "https://{cloud_id}/browse/{project_key}-NNN" } }`
  Use inside a `paragraph` content array. Works for any URL.

- **Panel** (info/warning/error/success callout):

  ```json
  {
    "type": "panel",
    "attrs": { "panelType": "info" },
    "content": [
      {
        "type": "paragraph",
        "content": [{ "type": "text", "text": "Note text here" }]
      }
    ]
  }
  ```

  `panelType`: `info`, `note`, `warning`, `error`, `success`.

- **Table:**

  ```json
  {
    "type": "table",
    "attrs": { "isNumberColumnEnabled": false, "layout": "default" },
    "content": [
      {
        "type": "tableRow",
        "content": [
          {
            "type": "tableHeader",
            "content": [
              {
                "type": "paragraph",
                "content": [{ "type": "text", "text": "Header" }]
              }
            ]
          }
        ]
      },
      {
        "type": "tableRow",
        "content": [
          {
            "type": "tableCell",
            "content": [
              {
                "type": "paragraph",
                "content": [{ "type": "text", "text": "Cell" }]
              }
            ]
          }
        ]
      }
    ]
  }
  ```

  Header row: `tableHeader`. Data rows: `tableCell`. Cell content: block nodes
  (wrap text in `paragraph`).

- **Horizontal rule:** `{ "type": "rule" }`
- **Link mark:**
  `{ "type": "text", "text": "click here", "marks": [{ "type": "link", "attrs": { "href": "https://..." } }] }`

## Issue Linking (Blocks, Relates, etc.)

Use MCP `mcp__atlassian__createIssueLink`. Available link types:

| Name          | Inward (passive) | Outward (active) |
| ------------- | ---------------- | ---------------- |
| **Blocks**    | is blocked by    | blocks           |
| **Relates**   | relates to       | relates to       |
| **Duplicate** | is duplicated by | duplicates       |
| **Fixes**     | is fixed by      | fixes            |
| **Improves**  | is improved by   | improves         |

Directionality for "Blocks": `inwardIssue` = blocker, `outwardIssue` = blocked.
A blocks B:

```
inwardIssue: "{project_key}-A", outwardIssue: "{project_key}-B", type: "Blocks"
```

## Subtasks

MCP create with `issueTypeName: "Sub-task"` and `parent: "{project_key}-NNN"`.
Same `parent` field as epic linking; issue type determines subtask vs. epic
child.

### Sprint Field

`{sprint_field}` takes a plain integer, not an object:

```json
"{sprint_field}": {refinement_sprint_id}
```

NOT `{ "id": ... }` (errors with "Number value expected as the Sprint id").

### Parent / Epic Linking

MCP create: `"parent": "{project_key}-NNN"`. MCP edit
(`mcp__atlassian__editJiraIssue`):
`fields: {"parent": {"key": "{project_key}-NNN"}}`.

## acli Fallback Reference

Use `acli jira workitem` subcommands only when MCP cannot do the job.

### Quick Reference

Substitute `{project_key}` before running.

| Operation  | Command                                                                         |
| ---------- | ------------------------------------------------------------------------------- |
| View       | `acli jira workitem view {project_key}-N`                                       |
| View (all) | `acli jira workitem view {project_key}-N --fields '*all' --json`                |
| Search     | `acli jira workitem search --jql "project = {project_key} AND ..." --limit 20`  |
| Create     | `acli jira workitem create --project {project_key} --type Task --summary "..."` |
| Create ADF | `acli jira workitem create --from-json file.json`                               |
| Edit       | `acli jira workitem edit --key {project_key}-N --summary "New title"`           |
| Transition | `acli jira workitem transition --key {project_key}-N --status "In Progress"`    |
| Comment    | `acli jira workitem comment create --key {project_key}-N --body "..."`          |

### acli JSON Template (for `--from-json`)

```json
{
  "additionalAttributes": {
    "{team_field}": "{team_id}",
    "{sprint_field}": {refinement_sprint_id}
  },
  "parentIssueId": "{project_key}-NNN",
  "projectKey": "{project_key}",
  "summary": "Ticket title",
  "type": "Task",
  "description": {
    "type": "doc",
    "version": 1,
    "content": [
      {
        "type": "paragraph",
        "content": [{ "type": "text", "text": "Description here." }]
      }
    ]
  }
}
```

### acli Edit JSON Format

Uses `"issues"` (array of keys) instead of `"projectKey"`:

```json
{
  "issues": ["{project_key}-N"],
  "description": {
    "type": "doc",
    "version": 1,
    "content": [...]
  }
}
```

## Common Workflows

### Read a ticket from a URL

Extract key from URL (e.g. `{project_key}-NNN` from
`https://{cloud_id}/browse/{project_key}-NNN`), then MCP
`mcp__atlassian__getJiraIssue` with `issueIdOrKey: "{project_key}-NNN"`.

### Search team tickets

MCP `mcp__atlassian__searchJiraIssuesUsingJql`, or fallback:

```bash
acli jira workitem search --jql "project = {project_key} AND status = 'New'" --limit 20
acli jira workitem search --jql "project = {project_key} AND sprint = {refinement_sprint_id}" --limit 50
```
