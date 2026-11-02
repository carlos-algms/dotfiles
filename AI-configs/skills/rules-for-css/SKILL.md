---
name: writing-css
description: >
  Applies the user's CSS and CSS Modules conventions. Use before writing,
  editing, or suggesting CSS, in files or in chat.
---

# CSS Protocol

Project rules override these. Apply these where the project is silent.

## Modern Features

Prefer modern CSS over legacy patterns. Use only Baseline widely or newly
available features. Check MDN Baseline before using anything newer.

### Nesting

- `&` is required for compound selectors: `&:hover`, `&.active`, `&[disabled]`
- `&` is required for parent context. In CSS Modules, use `:global(.dark) &`
- Never write a bare `:hover {}` in nesting. It means `& :hover` (descendant)
- No Sass suffixes. `&__title` and `&-active` are invalid in native CSS

```css
/* ✗ */
.card {
  &__title { ... }
  &-active { ... }
}

/* ✓ */
.cardTitle { ... }
.card {
  &.active { ... }
}
```

### Logical properties

Always use logical properties. Never use physical ones.

- `inline-size`, `block-size`, `min-block-size` (not `width`, `height`)
- `margin-inline`, `padding-block` (not `margin-left`, `padding-top`)
- `inset`, `inset-inline-start` (not `top`, `left`)
- Never use 2-4 value physical shorthands (`margin: 0 auto`,
  `padding: 8px 16px`, `inset: 0 auto auto 0`). Use the logical longhands
- Exempt where no Baseline logical form exists: `overflow-x`, `overflow-y`,
  `translate`, `transform`, `transform-origin`, shadow offsets,
  `background-position`, `object-position`, gradient directions

```css
/* ✗ */
.box {
  margin: 0 auto;
  padding-top: 8px;
  padding-bottom: 8px;
}

/* ✓ */
.box {
  margin-inline: auto;
  padding-block: 8px;
}
```

### Sizing

Never write `width: 100%`, `height: 100%`, `inline-size: 100%`, or
`block-size: 100%`. Under `content-box`, padding and borders overflow the
parent. `100%` also ignores sibling space.

- Block items fill the inline axis, and flex items fill the cross axis, by
  default. Write no size
- Flex main axis: `flex: 1` (width in a row, height in a column). Add
  `min-inline-size: 0` if the content overflows
- Flex cross axis: `align-self: stretch`
- Grid: `grid-column: 1 / -1` spans the explicit columns. Use
  `justify-self: stretch` for a form control in a grid cell
- Page height: `min-block-size: 100dvb` (not `100vh`)
- Fill a positioned parent: `position: absolute; inset: 0`. Overlay:
  `position: fixed; inset: 0`
- Images and video: `max-inline-size: 100%; block-size: auto`
- `100%` is allowed inside `min()`, `max()`, `clamp()`, and `max-inline-size`
- Exempt: `table { inline-size: 100% }`. A table does not stretch

```css
.app {
  display: grid;
  grid-template-rows: auto 1fr auto;
  min-block-size: 100dvb;
}

.overlay {
  position: fixed;
  inset: 0;
}
```

### Layout

- `gap` between siblings (no margin hacks)
- `place-items: center` to center grid content
- `aspect-ratio` (no padding-top ratio hack)
- Container queries (`@container`) for component responsiveness. The container
  needs `container-type`, and it cannot style itself. Media queries only for
  viewport and user preferences
- Range media syntax: `@media (width <= 600px)` (not `max-width`)
- `clamp()`, `min()`, `max()` for fluid sizing

```css
.wrap {
  container-type: inline-size;
}

.card {
  @container (width > 40rem) {
    display: grid;
  }
}
```

### Selectors

- `:is()` to group selectors. It keeps the highest specificity of its arguments
- `:where()` to group selectors with zero specificity
- `:has()` for parent-based state
- `:focus-visible` (not `:focus`) for focus rings
- No ID selectors, no `!important`, no `@import` in CSS Modules

### Color and transforms

- `oklch()`, `color-mix()`. No hand-picked hover shades
- `light-dark()` needs `color-scheme`. Set `color-scheme: light dark` on `:root`
  and `color-scheme: dark` on the dark scope
- `translate`, `scale`, `rotate` (not `transform: translate(...)`)

```css
:root {
  color-scheme: light dark;
}

:global(.dark) {
  color-scheme: dark;
}

.card {
  background: light-dark(white, oklch(25% 0 0));
}
```

### Text

- `text-wrap: balance` for headings
- `text-wrap: pretty` for paragraphs, as progressive enhancement only (not
  Baseline)

### Cascade and custom properties

- `@layer` for cascade control
- `@property` for typed, animatable custom properties

### Motion and accessibility

- Wrap motion in `@media (prefers-reduced-motion: no-preference)`
- `@starting-style` for entry animations
- `transition-behavior: allow-discrete` to animate `display`
- `accent-color` for native form controls

## CSS Modules

- camelCase class names only (no dashes)
- No tag selectors at root level
- `:root`, `html`, and `body` styles belong in a global stylesheet
- `composes` works only on top-level single-class rules
- Nest only with compound `&` selectors (pseudo-classes, pseudo-elements,
  attribute selectors, at-rules). No descendant or child selectors via nesting,
  with or without `&` (`.child`, `& .child`, `> .child`, `& > .child`).
  Exception: parent context `:global(.x) &`

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

  @media (width <= 600px) {
    display: block;
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
