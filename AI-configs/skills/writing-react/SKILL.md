---
name: writing-react
description: >
  Applies the user's React conventions for components and hooks. Use before
  writing, editing, or suggesting React code, in files or in chat.
---

# React Protocol

Project rules override these. Apply these where the project is silent.

Read the `react` version from the closest `package.json`, including
`peerDependencies`. Use the lowest version the range allows. For `catalog:` or
`workspace:`, read `node_modules/react/package.json`. Apply `React 19+:` and
`React 19.2+:` rules only on matching versions.

## Component Structure

- Functional components only (no classes, except error boundaries)
- Import named exports from `react`; **Never** `import React` or `React.*`
  (e.g., `React.useState`, `React.ReactNode`)
- Export default in single expression
- No return types for components (TypeScript infers)

```tsx
// ✓ Good
import { useState, type ReactNode } from 'react';

export default function MyComponent() {
  return <div>Hello</div>;
}

// ✗ Bad
import React from 'react';
function MyComponent(): JSX.Element { ... }
export default MyComponent;
```

## Hooks

- `useState` generic only when inference is wrong: unions, `null` initial value,
  empty arrays (not for `string`, `boolean`, `number`)
- No `useCallback` for same-component functions
- Move functions an effect calls inside the effect
- `useCallback` acceptable for functions returned from custom hooks
- Named functions (not arrows) for async/complex logic inside hooks
- Fetch and mutate through the project's data layer (TanStack Query, framework
  loaders) when one exists; effects last
- Never silence the deps lint
- React 19.2+: `useEffectEvent` for non-reactive logic inside effects

```tsx
// ✓ Good
const [name, setName] = useState(''); // no generic needed
const [status, setStatus] = useState<'a' | 'b'>('a'); // union needs generic
const [data, setData] = useState<Data | null>(null); // null needs generic
const [error, setError] = useState<unknown>(null);

useEffect(() => {
  const controller = new AbortController();
  async function fetchData() {
    try {
      const res = await fetch('/api', { signal: controller.signal });
      if (!res.ok) {
        throw new Error(String(res.status));
      }
      setData(await res.json());
    } catch (error) {
      if (!controller.signal.aborted) {
        setError(error);
      }
    }
  }
  void fetchData();
  return () => controller.abort();
}, []);
```

## Move State Down, Lift Content Up

- Keep state, queries, mutations, and form state in the lowest common parent of
  the components that read them. Extract a component instead. Never use `memo`
  unless the user asks
- Pass static subtrees as `children` or element props. They skip rerenders when
  the receiving component's own state changes
- A provider that owns state must take `children`. Consumers still rerender on
  each value change
- Put state and its `dispatch`/setter in separate contexts. Components that only
  trigger actions then skip state changes. See
  <https://react.dev/learn/scaling-up-with-reducer-and-context>

```tsx
// ✓ Move state down: clicks rerender only Counter
function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}

export default function Stage() {
  return (
    <>
      <h1>Demo counter</h1>
      <HeavyTree />
      <Counter />
    </>
  );
}

// ✗ State in parent: every click rerenders HeavyTree
export default function Stage() {
  const [count, setCount] = useState(0);
  return (
    <>
      <HeavyTree />
      <button onClick={() => setCount(count + 1)}>{count}</button>
    </>
  );
}

// ✓ Lift content up: Header and Main skip ComplexLayout's state updates
return <ComplexLayout header={<Header />} main={<Main />} />;
```

## Other Rules

- Follow accessibility best practices
- `displayName` only for `forwardRef` components
- Fragment `<>` only for multiple siblings
- Never define a component inside another component. It remounts on each render
  and loses its state
- Never use `&&` with a number: `{count && <X />}` renders `0`. Use
  `count > 0 &&` or a ternary, or extract a component that returns `null` early
  when the JSX is large and needs no new props
- Stable IDs as keys, not the array index. Change `key` on purpose to reset a
  component's state
- Functional updater for multiple updates in one event, or for updates from
  async or delayed callbacks
- Never mutate state. Create new objects and arrays
- Derive values during render. Never sync derived state with `useEffect`
- React 19+: accept `ref` as a prop; no `forwardRef`, no `displayName`
- React 19+: `<Context value>` instead of `<Context.Provider>`
- React 19+: form `action`, `useActionState`, `useFormStatus` (`react-dom`), and
  `useOptimistic` for mutations instead of hand-written pending/error state
- React 19.2+: `<Activity mode="hidden">` to keep hidden UI state

```tsx
// ✓ React 19+: ref as a prop
function MyInput({ ref, ...props }: Props & { ref?: Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />;
}

// ✓ Below React 19: forwardRef with displayName
const MyInput = forwardRef<HTMLInputElement, Props>((props, ref) => (
  <input ref={ref} {...props} />
));
MyInput.displayName = 'MyInput';
```
