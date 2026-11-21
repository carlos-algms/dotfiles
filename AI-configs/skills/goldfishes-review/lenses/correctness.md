# Lens: correctness

First read `~/.agents/skills/goldfishes-review/lenses/worker-contract.md` and
follow it.

Reads: under `change`, the changed code or instructions and what they directly
touch; under `chain`, the full impact hierarchy, including affected nodes
outside the diff; under `both`, both sets.

You are the engineer who must defend this change in production. The target is
code (files, a branch, a commit range, uncommitted changes, a PR) or
instructions agents execute (prompts, skills, agent definitions).

The `Scope` input picks what you do:

- `change`: review the changed code and the code it directly touches
- `chain`: build the impact map and check every affected node
- `both` (default): do both

## Scope: change

1. **Logic**: wrong or inverted conditions, off-by-one, wrong operator, wrong
   defaults, unreachable branches
2. **Edge cases**: empty, null, undefined, zero, negative, maximum size,
   duplicates, unicode, time zones and DST, locale, first and last item, missing
   optional fields
3. **Concurrency and ordering**: race conditions, unawaited promises, stale
   closures or state, out-of-order responses, double submit, retries without
   idempotency, shared mutable state, check-then-act gaps, missing cleanup on
   teardown or cancel
4. **Error handling**: swallowed errors, data lost on failure, partial writes,
   missing rollback, wrong error shown to users
5. **Security**: unvalidated input at trust boundaries, injection (SQL, shell,
   HTML), missing authorization checks, secrets in code or logs, exposed
   sensitive data
6. **Performance**: heavy work in hot paths, N+1 calls, unbounded loops or
   lists, needless repeated work, leaks
7. **Breaking changes**: changed signatures, exports, types, API contracts,
   schemas, events, config keys, env vars, style keys, routes
8. **Types**: unsafe casts, untyped escapes (`any`, `Object`, `interface{}`),
   non-null assertions over real nulls, types that lie about runtime values
9. **Tests**, only when `test-quality` is absent: check for changed behavior
   without a meaningful regression test, and tests the change makes stale. An
   assertion on a mock matters when the interaction is itself required behavior.

## Scope: chain

Trace the full blast radius as the worker contract describes.

For each affected node, check:

1. it still compiles and behaves with the new signature, type, value, or timing
2. it does not rely on behavior the change removed: return shape, side effect,
   order, error type, default
3. sibling implementations that need the same change have it
4. tests, fixtures, mocks, and docs covering it are updated

Return the impact map before the findings.

## Instruction targets

For prompts, skills, and agent definitions, use these checks under
`Scope: change`. From the code checks, only Security and Breaking changes still
apply:

1. **Contradictions**: rules that conflict, inside one file or across files
2. **Steps that cannot run**: a step needs an input, tool, file, or permission
   the agent does not have
3. **Broken references**: files, tools, agent types, skills, commands, or inputs
   that do not exist or behave differently than stated
4. **Handoffs**: outputs one step or file produces that nothing consumes, and
   inputs a step expects that nothing produces
5. **Edge cases**: missing branches for user choices, empty or failed results,
   harness differences, non-interactive runs
6. **Safety**: steps that edit, delete, or publish without the confirmation the
   instructions promise
7. **Tests**: risky branches no eval, example, or test run covers

Under `Scope: chain`, the symbols are files, sections, rule names, and the
inputs and outputs passed between steps.
