---
name: obsidian-bases
description: >
  Create or edit Obsidian Bases (.base files), including views, filters,
  formulas and summaries. Do not load for ordinary Markdown notes or merely
  querying an existing Base through the CLI.
---

# Obsidian Bases

A `.base` file is YAML. Load `obsidian-mechanics` when accessing the user's
vault and `obsidian-cli` only when running an `obsidian` command. Do not load
`obsidian-markdown` unless also editing a Markdown note.

## Minimal schema

```yaml
filters:
  and:
    - 'status == "active"'
    - 'file.inFolder("Projects")'

formulas:
  days_old: '(now() - file.ctime).days'

properties:
  formula.days_old:
    displayName: 'Days old'

summaries:
  custom_average: 'values.mean().round(1)'

views:
  - type: table
    name: 'Active'
    limit: 20
    order:
      - file.name
      - status
      - formula.days_old
    groupBy:
      property: status
      direction: ASC
    summaries:
      formula.days_old: Average
```

Views may use `table`, `cards`, `list` or `map`. Global filters affect every
view; a view may also define its own `filters`.

## Filters

A filter is an expression or a recursive `and`, `or` or `not` object:

```yaml
filters:
  or:
    - 'file.hasTag("book")'
    - and:
        - 'status == "active"'
        - 'priority >= 3'
    - not:
        - 'file.inFolder("Archive")'
```

Operators: `==`, `!=`, `>`, `<`, `>=`, `<=`, `&&`, `||` and `!`.

Property namespaces:

- Note property: `status` or `note.status`
- File property: `file.name`, `file.path`, `file.folder`, `file.ext`,
  `file.ctime`, `file.mtime`, `file.tags`, `file.links`, `file.backlinks`
- Formula property: `formula.<name>`

`this` refers to the Base itself in its main view, the embedding file when
embedded and the active file when opened in the sidebar.

## Formulas

```yaml
formulas:
  status_label: 'if(done, "Done", "Open")'
  created: 'file.ctime.format("YYYY-MM-DD")'
  days_until_due: 'if(due, (date(due) - today()).days, "")'
```

Common functions: `date()`, `now()`, `today()`, `if()`, `duration()`, `file()`
and `link()`. Load `references/FUNCTIONS_REFERENCE.md` only when another
function or type is needed.

Date subtraction returns a Duration. Access `.days`, `.hours`, `.minutes`,
`.seconds` or `.milliseconds` before number operations:

```yaml
formulas:
  age: '(now() - file.ctime).days.round(0)'
```

Guard optional properties with `if()`. Every `formula.X` reference must have a
matching `X` under `formulas`.

## Quoting

- Quote strings containing YAML punctuation.
- Prefer single quotes around formulas containing double-quoted strings.
- Check nested quotes before changing formula logic.

```yaml
properties:
  status:
    displayName: 'Status: Active'
formulas:
  label: 'if(done, "Yes", "No")'
```

## Validation

After editing:

1. Parse the file as YAML.
2. Confirm referenced properties and formulas exist.
3. Check filter and formula quoting.
4. Open the Base in Obsidian when available.

To embed a Base in Markdown:

```markdown
![[MyBase.base]]
![[MyBase.base#View Name]]
```

References: [syntax](https://help.obsidian.md/bases/syntax),
[functions](https://help.obsidian.md/bases/functions) and
[views](https://help.obsidian.md/bases/views).
