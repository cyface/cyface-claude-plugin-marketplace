# Alpine.js — Official Plugins Reference

Nine official plugins, all published as `@alpinejs/<name>` and versioned in lockstep with core (3.17.x). Each loads the same way:

```html
<!-- CDN: plugin BEFORE core -->
<script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/focus@3.17.5/dist/cdn.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.17.5/dist/cdn.min.js"></script>
```

```js
// npm
import Alpine from 'alpinejs'
import focus from '@alpinejs/focus'
Alpine.plugin(focus)   // or Alpine.plugin([focus, collapse, …])
Alpine.start()
```

## Contents

- [Focus](#focus)
- [Collapse](#collapse)
- [Intersect](#intersect)
- [Resize](#resize)
- [Persist](#persist)
- [Mask](#mask)
- [Anchor](#anchor)
- [Morph](#morph)
- [Sort](#sort)

---

## Focus

`x-trap` keeps keyboard focus inside an element while an expression is truthy; `$focus` is a focus-management helper.

```html
<div x-data="{ open: false }">
  <button type="button" @click="open = true" x-ref="trigger">Open</button>
  <div x-show="open" x-cloak x-trap.inert.noscroll="open" role="dialog" aria-modal="true">
    <input placeholder="Receives focus first">
    <button type="button" @click="open = false">Close</button>
  </div>
</div>
```

| Modifier | Effect |
|----------|--------|
| `.inert` | Sets `aria-hidden="true"` on everything else on the page while trapped (use for modals) |
| `.noscroll` | Locks page scrolling while trapped |
| `.noreturn` | Do not return focus to the previously focused element on release (focus-opened dropdowns) |
| `.noautofocus` | Do not move focus into the trap automatically |

Traps nest: opening a dialog from a dialog traps the inner one, then restores the outer.

`$focus` helpers: `$focus.focus(el)`, `.focusable(el)`, `.focusables()`, `.focused()`, `.lastFocused()`, `.within(el)`, `.wrap()`, `.first()`, `.last()`, `.next()`, `.previous()`, `.noscroll()`, `.getFirst()`, `.getLast()`, `.getNext()`, `.getPrevious()`.

```html
<!-- Arrow-key navigation inside a listbox -->
<ul @keydown.down.prevent="$focus.wrap().next()" @keydown.up.prevent="$focus.wrap().previous()">
```

---

## Collapse

Animates height between `0` (plus `display: none`) and auto. Only valid on an element that also has `x-show`.

```html
<div x-data="{ expanded: false }">
  <button type="button" @click="expanded = !expanded" :aria-expanded="expanded">Details</button>
  <div x-show="expanded" x-collapse>…</div>
</div>

<div x-show="expanded" x-collapse.duration.500ms>
<div x-show="expanded" x-collapse.min.50px>   <!-- collapsed state keeps 50px visible, no display:none -->
```

---

## Intersect

Wraps `IntersectionObserver`.

```html
<div x-intersect="shown = true">
<div x-intersect:enter="load()" x-intersect:leave="pause()">
<div x-intersect.once="track('seen')">
<div x-intersect.half="…">            <!-- > 50% visible -->
<div x-intersect.full="…">            <!-- > 99% visible -->
<div x-intersect.threshold.25="…">    <!-- 0–100 -->
<div x-intersect.margin.200px="…">    <!-- rootMargin; negative values allowed -->
<div x-intersect.parent="…">          <!-- observe within the parent scroll container (3.16.0) -->
<div x-intersect.dwell.500ms="…">     <!-- fire only after staying visible 500ms; default 250ms (3.17.1) -->
<div x-intersect.dwell.once="…">      <!-- once, after the first completed dwell -->
```

Typical uses: lazy-loading sections, analytics impressions, infinite scroll in pure-Alpine apps (with htmx, prefer `hx-trigger="intersect once"`).

---

## Resize

Wraps `ResizeObserver` and exposes `$width` / `$height`.

```html
<div x-resize="width = $width; height = $height">
<div x-resize.document="…">    <!-- observe the document instead -->
<div x-resize.viewport="…">    <!-- observe window.visualViewport, falls back to document (3.17.4) -->
```

---

## Persist

Persists a property to `localStorage` (default) across page loads.

```html
<div x-data="{ count: $persist(0) }">
<div x-data="{ count: $persist(0).as('counter-count') }">        <!-- custom key; default is `_x_count` -->
<div x-data="{ draft: $persist('').using(sessionStorage) }">     <!-- or any { getItem, setItem } -->
```

```js
Alpine.data('settings', function () {          // function, not arrow, so `this.$persist` works
  return { theme: this.$persist('light').as('theme') }
})
Alpine.store('darkMode', { on: Alpine.$persist(false).as('darkMode_on') })
```

`undefined` is no longer persisted (3.16.2). Values are JSON-serialized.

---

## Mask

Formats input as the user types.

```html
<input x-mask="(999) 999-9999">          <!-- 9 digit, a letter, * any -->
<input x-mask="99/99/9999" placeholder="MM/DD/YYYY">
<input x-mask:dynamic="$input.startsWith('34') || $input.startsWith('37') ? '9999 999999 99999' : '9999 9999 9999 9999'">
<input x-mask:dynamic="$money($input)">              <!-- 1,234.56 -->
<input x-mask:dynamic="$money($input, ',', '.', 2)"> <!-- decimal separator, thousands separator, precision -->
```

`x-mask:dynamic` accepts an expression returning a mask string, or a function name on your data.

---

## Anchor

Positions an element relative to another using Floating UI (flip/shift handled for you).

```html
<div x-data="{ open: false }">
  <button type="button" x-ref="button" @click="open = !open">Options</button>
  <div x-show="open" x-anchor.bottom-start.offset.8="$refs.button">…</div>
</div>
```

| Modifier | Effect |
|----------|--------|
| `.top` `.top-start` `.top-end` `.bottom` `.bottom-start` `.bottom-end` `.left` `.left-start` `.left-end` `.right` `.right-start` `.right-end` | Placement |
| `.offset.10` | Gap in px |
| `.noflip` | Keep the placement even if it overflows (3.15.11) |
| `.fixed` | Use `position: fixed` so the element escapes `overflow: hidden` ancestors (3.15.12) |
| `.no-style` | Compute only; read `$anchor.x` / `$anchor.y` and position it yourself |

---

## Morph

Morphs an existing DOM tree into new HTML while preserving Alpine state, focus and form values. Used by Livewire/LiveView-style frameworks and by htmx's `alpine-morph` extension.

```js
Alpine.morph(el, newHtml, {
  key(el) { return el.id },               // default: the `key=""` attribute
  lookahead: false,
  updating(el, toEl, childrenOnly, skip) {},
  updated(el, toEl) {},
  removing(el, skip) {},
  removed(el) {},
  adding(el, skip) {},
  added(el) {},
})

// Root-less fragments between two comment/marker nodes (3.15.0)
Alpine.morphBetween(startMarker, endMarker, newHtml, options)
```

There is no `x-morph` directive. With htmx: `hx-ext="alpine-morph" hx-swap="morph"` (community extension `htmx-ext-alpine-morph`, which requires `@alpinejs/morph` loaded before Alpine core; the response must contain the element being replaced). htmx's own `idiomorph` extension does a similar morph without the Alpine plugin.

---

## Sort

Drag-and-drop reordering backed by SortableJS.

```html
<ul x-sort="reorder($item, $position)">          <!-- $item = x-sort:item value, $position = 0-based index -->
  <template x-for="todo in todos" :key="todo.id">
    <li x-sort:item="todo.id">
      <span x-sort:handle>⋮⋮</span>
      <span x-text="todo.title"></span>
      <button type="button" x-sort:ignore>Delete</button>   <!-- never starts a drag -->
    </li>
  </template>
</ul>

<ul x-sort x-sort:group="lists">…</ul>          <!-- drag between lists sharing a group -->
<ul x-sort.ghost>…</ul>                           <!-- keep a ghost in the source position -->
<ul x-sort x-sort:config="{ animation: 0 }">     <!-- raw SortableJS options -->
```

CSS hooks: `.sortable-ghost` on the placeholder and `body.sorting` while dragging. With htmx, post the new order from the handler (`htmx.ajax('POST', '/reorder', { values: { order } })`) or let a form with hidden inputs submit.
