---
name: json-canvas
description: >
  Create or edit JSON Canvas (.canvas) files containing nodes, edges and groups.
  Do not load for ordinary Obsidian notes or Markdown diagrams.
---

# JSON Canvas

A `.canvas` file follows JSON Canvas 1.0:

```json
{
  "nodes": [],
  "edges": []
}
```

Load `obsidian-mechanics` when accessing the user's vault. Do not load
`obsidian-markdown` unless also editing a Markdown note or writing
Obsidian-specific syntax inside a text node.

## Nodes

Every node requires `id`, `type`, `x`, `y`, `width` and `height`.

| Type    | Additional required field |
| ------- | ------------------------- |
| `text`  | `text`                    |
| `file`  | `file`                    |
| `link`  | `url`                     |
| `group` | none                      |

Optional common field: `color`, using `"1"` through `"6"` or a hex colour. File
nodes may use `subpath`; groups may use `label`, `background` and
`backgroundStyle`.

```json
{
  "id": "6f0ad84f44ce9c17",
  "type": "text",
  "x": 0,
  "y": 0,
  "width": 400,
  "height": 200,
  "text": "# Summary\n\nCanvas text."
}
```

Use actual newline escapes (`\n`) in JSON strings, not literal `\\n`.

## Edges

Every edge requires a unique `id`, `fromNode` and `toNode`.

```json
{
  "id": "0123456789abcdef",
  "fromNode": "6f0ad84f44ce9c17",
  "fromSide": "right",
  "fromEnd": "none",
  "toNode": "a1b2c3d4e5f67890",
  "toSide": "left",
  "toEnd": "arrow",
  "label": "leads to"
}
```

`fromSide` and `toSide` accept `top`, `right`, `bottom` or `left`. `fromEnd` and
`toEnd` accept `none` or `arrow`.

## Editing rules

- Generate unique 16-character lowercase hexadecimal IDs for nodes and edges.
- Preserve existing IDs when editing objects.
- Array order controls z-index; later nodes appear above earlier nodes.
- Coordinates may be negative; `x` increases right and `y` increases down.
- Avoid overlap and leave visible padding inside groups.
- Every edge endpoint must reference an existing node.

## Validation

After editing:

1. Parse the JSON.
2. Confirm IDs are unique across nodes and edges.
3. Confirm every edge endpoint exists.
4. Confirm each node has its type-specific required field.
5. Validate side, end and colour values.

Load `references/EXAMPLES.md` only when a complete layout example is needed.
Specification: [JSON Canvas 1.0](https://jsoncanvas.org/spec/1.0/).
