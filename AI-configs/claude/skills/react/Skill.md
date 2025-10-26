---
name: react
description: React best practices and guidelines for code generation
---

# REACT & FRONTEND PROTOCOL

## Component Structure

- Functional components with hooks only (never class components)
- No `import React from 'react'` needed in modern React
- Import from 'react' individually: never use `React.*` in code
- Export default in single expression when applicable
- Named functions (not arrows) inside hooks for async/complex logic
- No return types for components (TypeScript infers)

## Hooks

- Generic type for `useState` only when needed:
  - Not needed: `string`, `boolean`, `number`
  - Needed: union types, complex types
- No `useCallback` for same-component functions
- `useCallback` acceptable for functions returned from custom hooks

## Other Rules

- Follow accessibility best practices
- Add `displayName` to `forwardRef` components ONLY
- Use Fragment/`<>` only for multiple sibling elements

## Examples

<example type="good">

```tsx
// Component with default export
export default function MyComponent() {
  return <div>Hello</div>;
}
```

</example>

<example type="bad">

```tsx
function MyComponent() {
  return <div>Hello</div>;
}
export default MyComponent;
```

</example>

<example type="good">

```tsx
// Individual Imports from 'react'
import { useState, type ReactNode } from 'react';

interface Props {
  children: ReactNode;
}
useState();
```

</example>

<example type="bad">

```tsx
import React from 'react';
React.useState();
interface Props {
  children: React.ReactNode; // very bad
}
```

</example>

<example type="good">

```tsx
// Named function for async logic in hooks
import { useEffect } from 'react';

function MyComponent() {
  useEffect(() => {
    async function fetchData() {
      const response = await fetch('/api/data');
      // ...
    }
    void fetchData();
  }, []);
}
```

</example>

<example type="good">

```tsx
// useState Generic Types
import { useState } from 'react';

function MyComponent() {
  const [state, setState] = useState<Type>(initialValue);
  const [isEnabled, setIsEnabled] = useState(false); // string, boolean, number don't need generic
  const [name, setName] = useState<string | null>(null); // union types need generic

  return <YourComponent />;
}
```

</example>

<example type="good">

```tsx
// useCallback only when function is returned
function MyComponent() {
  function handleClick() {
    // ...
  }

  return <button onClick={handleClick}>Click me</button>;
}

function useDataProcessor() {
  // useCallback acceptable here - function returned from hook
  const processData = useCallback(() => {
    // ...
  }, []);

  return { processData };
}
```

</example>

<example type="good">

```tsx
// displayName with forwardRef
import { forwardRef } from 'react';

const MyInput = forwardRef<HTMLInputElement, Props>((props, ref) => {
  return <input ref={ref} {...props} />;
});

MyInput.displayName = 'MyInput';
```

</example>

<example type="good">

```tsx
// Fragment only for multiple siblings
return (
  <>
    <div>First child</div>
    <div>Second child</div>
  </>
);
```

</example>

<example type="bad">

```tsx
// Unnecessary Fragment
return (
  <>
    <div>Only child</div>
  </>
);
```

</example>

<example type="good">

```tsx
// No return type - TypeScript infers
function MyComponent() {
  return <div>Hello</div>;
}
```

</example>

<example type="bad">

```tsx
function MyComponent(): JSX.Element {
  return <div>Hello</div>;
}
```

</example>
