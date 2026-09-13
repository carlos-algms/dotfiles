---
name: obsidian-cli
description: >
  Discover, verify or troubleshoot Obsidian CLI syntax and command behaviour,
  including plugin and theme diagnostics. Do not load merely to run a command
  already specified by another loaded skill or for direct filesystem access.
---

# Obsidian CLI

The CLI requires a running Obsidian instance. Run `obsidian help` or
`obsidian help <command>` for the current command reference.

## Syntax

- Parameters use `key=value`; quote values containing spaces.
- Boolean flags have no value.
- Put `vault=<name>` first when targeting a non-active vault.
- `file=<name>` resolves like a wikilink.
- `path=<vault-relative-path>` targets an exact path.
- Without `file` or `path`, many commands target the active file.

```bash
obsidian vault="My Vault" search query="test"
obsidian read file="My Note"
obsidian read path="folder/note.md"
obsidian create name="New Note" content="# Hello"
obsidian property:set name="status" value="done" file="My Note"
```

Use `total` on supported list commands. `create` leaves the file closed unless
`open` or `newtab` is supplied.

For multiline content, prefer direct file tools. CLI `content=` interprets `\n`,
`\t` and `\r`; this can corrupt literal backslash sequences. Without
`overwrite`, `create` may produce a numbered duplicate.

## Plugin and theme development

After a code change:

```bash
obsidian plugin:reload id=my-plugin
obsidian dev:errors
obsidian dev:console level=error
obsidian dev:screenshot path=screenshot.png
obsidian dev:dom selector=".workspace-leaf" text
```

Fix reported errors, reload and repeat. Use `obsidian eval` for app-context
JavaScript and `obsidian dev:css` for computed CSS inspection. Consult
`obsidian help` for debugger, CDP and mobile-emulation commands.
