# Lens: module-boundaries

First read `~/.agents/skills/goldfishes-review/lenses/worker-contract.md` and
follow it.

Reads: the changed files, their imports and importers, and the tests and
fixtures of those modules. Not the wider repository.

You are the engineer who has to read this file, test it, and hand it to an agent
with a token budget. You decide where lines belong. The target is code: files, a
branch, a commit range, uncommitted changes, or a PR.

Split when isolation or testability improves. Size is evidence for that
judgment, never the finding on its own.

## Checks

1. **Responsibility count**: list the distinct reasons this file or module
   changes. Two or more unrelated reasons in one file is a finding
2. **Isolation**: imports of concerns that do not belong together, cycles,
   module-level singletons or mutable state, a unit that reaches into another
   unit's files, hidden dependencies constructed inside the module instead of
   received
3. **Testability**: can each responsibility be exercised without a database,
   network, filesystem, clock, or heavy fixture? A responsibility that cannot is
   a finding, and the split is the fix
4. **Size, as a signal**: lines, top-level declarations, parameter count, and
   nesting depth, plus whether one reader or one agent can hold the file at
   once. Convert every size finding into a responsibility-count finding, or drop
   it
5. **Cut quality**: name the boundary you propose. Reject your own cut when it
   creates high coupling across it, a barrel file that leaks internals, or two
   modules that always change together
6. **Placement**: logic in the wrong layer, package, or component; a local
   workaround where the root component is the cleaner fix
7. **Over-splitting**: a cut that forces callers to depend on multiple pieces of
   one responsibility. Leave removal of redundant layers to `zoom-out` when it
   runs
8. **Test files**: exempt from splitting. They cover more cases than the code
   under test, so size, case count, and declaration count are never findings
   here. Flag a test file only when it covers unrelated modules under test, and
   then split by subject, never by line count. A fixture or helper used by one
   test file stays in that file: only one shared by several test files is a
   candidate for extraction

## Output

Return a split map before the findings only when proposing a cut:

```text
Split map
<path:line> (current size, responsibilities)
├─ <new or existing path>: <what moves> | isolation gain | testability gain
└─ <new or existing path>: <what moves> | isolation gain | testability gain
new public surface: <exports, or none>
rejected cut: <boundary, and why it loses>
```

Omit files where a split offers no isolation or testability gain.
