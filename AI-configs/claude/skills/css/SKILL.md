---
name: css
description: >
  Enforces strict CSS and CSS Modules policies for ALL CSS authoring, including
  stylesheet files (.css/.scss/.module.css) and CSS-in-JS (styled-components,
  Emotion, vanilla-extract, styled-jsx, Stitches, template literal styles
  embedded in TS/JS files). Use when creating, writing, or editing ANY CSS,
  styled component, or inline style block. Triggers include: component styles,
  global stylesheets, theme files, design tokens, animations, keyframes, utility
  classes, styled.X or styled() definitions, or any agent-authored CSS content.
---

# CSS Protocol

General CSS preferences, lower priority over project's local instructions.

If possible merge instructions, if conflicting, prefer project's local
instructions.

## Modern Features

Use nesting, `:has()`, `&`, `&:hover`, nested `@media`

```css
.button {
  color: blue;

  &:hover {
    color: darkblue;
  }

  @media (max-width: 600px) {
    width: 100%;
  }
}
```

## CSS Modules

- camelCase class names only (no dashes)
- No tag selectors at root level
- Nest only with `&` (pseudo-classes, pseudo-elements, attribute selectors,
  at-rules). No descendant or child selectors via nesting.

```css
/* ✓ Good */
.container { ... }
.headerTitle { ... }
.submitButton {
  background: blue;

  &:hover {
    background: darkblue;
  }

  &[disabled] {
    opacity: 0.5;
  }

  @media (max-width: 600px) {
    width: 100%;
  }
}
```

```css
/* ✗ Tag selector at root */
div { ... }

/* ✗ Descendant via nesting */
.parent {
  .child { ... }
}

/* ✗ kebab-case */
.submit-button { ... }
```
