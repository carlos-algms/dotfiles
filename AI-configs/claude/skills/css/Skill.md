---
name: css
description: |
  Best practices and guidelines for writing CSS, including CSS Modules and
  modern CSS features.
---

# CSS PROTOCOL

## Modern Features

Use modern CSS: `:has()`, nesting, `&`, `&:hover`

<example type="good">

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

</example>

## CSS Modules

- Never use tag selectors at root level
- Always camelCase for classes
- Never use dashes in class names
- Never nest class/id selectors
- Always nest pseudo-classes, pseudo-elements, media queries using `&`

### Naming for CSS modules

Class selectors: unique, simple, readable, camelCase

<example type="good">

```css
.container { ... }
.headerTitle { ... }
.submitButton { ... }
```

</example>
