---
name: typescript-and-javascript
description: Typescript and JavaScript protocols and code styles
---

# TYPESCRIPT & JAVASCRIPT PROTOCOL

## Type Checking

When iterating solutions (not reviewing code):

- Detect package manager per protocol
- Run `<package-manager> exec tsc --noEmit` to check errors

<example type="good">

```bash
pnpm tsc --noEmit
# or
npm exec tsc --noEmit
```

</example>

<example type="good" environment="monorepo">

```bash
cd apps/demo-app && pnpm tsc --noEmit
# or
cd apps/demo-app && npm exec tsc --noEmit
```

</example>

## Code Block Types

- Pure TypeScript: use `ts`
- TypeScript with JSX/React: use `tsx`

## Style Rules

- Early returns over nested conditionals
- Named functions over arrow functions (except callbacks/one-liners)
- Strict equality: `===`, `!==` exclusively
- `const` for non-changing variables
- `async/await` over `.then()`
- Never use `any` type - grep and find specific types
- `import type` for type-only imports
- Always use curly braces for `if` statements
- Never create an index.ts file to do barrel exports
- Never write code in an index.ts(x) file, give it a specific name
- Use `satisfies never` in switch default for exhaustiveness checking
- Prefer `satisfies <Type>` over type casting for traceability

## Examples

<example type="good" kind="early-return">

```ts
function process(data: DataType | null) {
  if (!data) {
    return;
  }
  // process data
}
```

</example>

<example type="bad">

```ts
function process(data: DataType | null) {
  if (data) {
    // process data
  }
}
```

</example>

<example type="good" kind="named-function">

```ts
function add(a: number, b: number): number {
  return a + b;
}
// One-liner arrow function: acceptable
const add = (a: number, b: number): number => a + b;
```

</example>

<example type="bad">

```ts
const add = (a: number, b: number): number => {
  return a + b;
};
```

</example>

<example type="good" kind="type-only-imports">

```ts
import type { MyType } from './types';
import { type ReactNode } from 'react';
```

</example>

<example type="good" kind="exhaustiveness-checking">

```ts
function factory(target: 'a' | 'b'): A | B | null {
  switch (target) {
    case 'a':
      return new A();
    case 'b':
      return new B();
    default:
      target satisfies never;
      return null;
  }
}
```

</example>

<example type="good" kind="satisfies-traceability">

```ts
const myObject = {
  key: 'value',
} satisfies Record<string, string>;

interface MyInterface {
  key: string;
}
const myObject2: MyInterface = {
  key: 'value',
};
```

</example>

<example type="bad">

```ts
const myObject: Record<string, string> = {
  key: 'value',
};
```

</example>

<example type="good" kind="async-await">

```ts
async function fetchData() {
  // ...
}
const data = await fetchData();
```

</example>

<example type="bad">

```ts
fetchData()
  .then((data) => {
    /* ... */
  })
  .catch((error) => {
    /* ... */
  });
```

</example>

<example type="good" kind="always-curly-braces">

```ts
if (!condition) {
  return;
}
```

</example>

<example type="bad">

```ts
if (!condition) return;
if (other) return;
```

</example>

<example type="good" kind="jsx-code-block">

```tsx
import { useState } from 'react';

export function MyComponent() {
  const [count, setCount] = useState(0);
  return <Component />;
}
```

</example>

<example type="bad" kind="not-using-jsx-code-block">

```ts
// Using 'ts' for JSX code, very bad
return <Component />;
```

</example>
