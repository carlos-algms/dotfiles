---
name: writing-frontend-unit-tests
description:
  Detects Jest or Vitest and applies the user's frontend test conventions. Use
  before writing, running, or suggesting unit tests, in files or in chat.
---

# Unit Test Protocol

Project rules override these. Apply these where the project is silent.

## Framework Detection

Never assume Jest or Vitest. Detect first:

- Check imports in test files
- Check config: `vitest.config.*`, `jest.config.*`
- Check `package.json` dependencies (workspace-specific in monorepos)
- Search test scripts in `package.json`

## Running Tests

Use the project's package manager from the closest workspace. Run relevant tests
only unless explicitly requested. Run once, not in watch mode (Vitest watches by
default; use `vitest run` or the project's equivalent):

```bash
<pm> run test path/to/file.test.ts
```

For all tests, use the `test` script in the closest `package.json`.

## Workflow

Write the test, run it, and read the failure. Fix the code or the test, then run
it again until it passes.
