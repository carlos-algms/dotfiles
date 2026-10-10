---
name: writing-css
description: >
  Applies the user's CSS and CSS Modules conventions. Use before writing,
  editing, or suggesting CSS, in files or in chat.
---

# CSS Protocol

Project rules override these. Apply these where the project is silent.

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
