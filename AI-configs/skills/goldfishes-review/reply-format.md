# Goldfish reply format

Workers reply in this format. The coordinator parses and grades replies with it.

## Reply shapes

A reply is either `not run: <reason>` alone, when the lens did not review, or
these parts in order:

1. `Not read: <files or hunks>`: required when the worker could not read every
   part of the target
2. Lens blocks: every block the lens file says to return before findings. Return
   them even when there are no findings
3. Findings, or `No findings` when the lens ran and found nothing.
   `inventive-catalyst` uses `No false compromise detected` instead
4. The `Unverified:` list, only when needed

The coordinator ignores anything outside this shape, such as a file list the
harness adds. Workers do not add such text.

## Severity

This is the only severity rule. Lenses do not set their own.

- **Blocker**: wrong behavior, data loss, a security hole, a broken consumer, a
  plan that cannot be executed as written, a plan step whose wrong guess forces
  rework across files, or an objective or section a reader cannot understand
- **Major**: a likely bug (a realistic input gives a wrong result), a missing
  test for a branch that can fail, over-engineering (something that can be
  removed, or replaced by existing code, with no behavior lost), or a gap where
  someone must guess, ask, or change it again before it works
- **Nit**: polish that changes neither behavior nor outcome

## Findings

Most severe first, one block each:

```text
Severity: Blocker | Major | Nit
Location: <path:line, section heading, or symbol>
Issue: <one or two sentences>
Evidence: <path:line, quote, or command output>
Fix: <concrete change>
```

## Unverified

List each claim you could not verify once, at the end:

```text
Unverified:
- <claim> | tried: <what you did> | would settle it: <what is missing>
```

## Impact map

Return one `Impact map` header with one root per changed symbol. Merge symbols
whose nodes and tags are all the same into one root: `<a>, <b> (<path>)`.

```text
Impact map
<symbol> (<path:line>)
├─ up
│  ├─ <path:line> <name> [ok | handled | NOT handled | unverified]
│  └─ ...
├─ down
│  └─ ...
└─ sideways
   └─ ...
```

- `ok`: not affected
- `handled`: affected, and the change or plan covers it
- `NOT handled`: affected, and nothing covers it. Also report it as a finding
- `unverified`: still unknown after investigating. Also list it under
  `Unverified:`
- More than 10 `ok` nodes in one direction: one line with the count and one
  example path. Never collapse `NOT handled` or `unverified` nodes
