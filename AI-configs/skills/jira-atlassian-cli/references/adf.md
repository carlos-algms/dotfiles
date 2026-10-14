# ADF reference

Read this only when `scripts/md2adf.py` fails, or when a node it cannot emit is
needed. Pass ADF JSON as the description or comment body.

Canonical docs:
<https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/>.
Per-node spec at `.../document/nodes/<nodeName>/`.

## Debugging a node

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

4. Markdown `- [ ]` renders as literal text in a Jira description. Only
   `taskList` / `taskItem` produce real checkboxes.

## Node types

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
  `{ "type": "text", "text": "...", "marks": [{ "type": "code" }] }` The `code`
  mark combines with `link` only, never with `strong`, `em`, or `strike`.
- **Task list (checkboxes):**
  `{ "type": "taskList", "attrs": { "localId": "ac-1" }, "content": [{ "type": "taskItem", "attrs": { "localId": "ac-1-1", "state": "TODO" }, "content": [{ "type": "text", "text": "..." }] }] }`

  `state` is `TODO` or `DONE`. Acceptance criteria MUST use
  `taskList`/`taskItem`, not `bulletList`. `taskItem.content` MUST be bare
  inline nodes; paragraph-wrapping is rejected with `INVALID_INPUT`. A nested
  checklist is a `taskList` placed as a sibling after its parent `taskItem` (the
  first child must be a `taskItem`). `acli` accepts it.

- **Expand (collapsible section):**
  `{ "type": "expand", "attrs": { "title": "..." }, "content": [<block nodes>] }`
  Children: block nodes (`paragraph`, `bulletList`, `heading`, etc.). Use to
  hide long context (findings, traces) below the fold.

- **Inline smart link** (renders as Jira card / Notion preview / any URL):
  `{ "type": "inlineCard", "attrs": { "url": "https://{cloud_id}/browse/{project_key}-NNN" } }`
  Use inside a `paragraph` content array. Works for any URL. A GitHub PR URL
  renders as `Restricted content` when Jira's GitHub integration lacks access.

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
