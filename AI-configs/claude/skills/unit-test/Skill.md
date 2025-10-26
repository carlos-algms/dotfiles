---
name: Unit Test
description: Best practices and guidelines for writing unit tests
---

# UNIT TESTING PROTOCOL

## Test Framework Detection

Never assume Jest or Vitest.

Detect framework:

- Check test files imports, current or other
- Check config files: `vitest.config.*`, `jest.config.*`
- Inspect dependencies in `package.json` (workspace-specific in monorepos)
- Grep test scripts in package.json (usually contain `jest` or `vitest`)

## Running Tests

Run relevant tests only unless explicitly requested otherwise:

<example type="good">

```bash
pnpm run test path/to/file.test.ts
# or
npm run test path/to/file.test.ts
```

</example>

<example type="good" environment="monorepo">

```bash
cd apps/demo-app && pnpm run test path/to/file.test.ts
# or
cd apps/demo-app && npm run test path/to/file.test.ts
```

</example>

For all tests, prefer `test` script in closest `package.json`:

<example type="good">

```bash
pnpm run test
# or
npm run test
```

</example>

<example type="good" environment="monorepo">

```bash
cd apps/demo-app && pnpm run test
# or
cd apps/demo-app && npm run test
```

</example>
