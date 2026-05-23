---
name: alpine-js
description: >-
  This skill should be used when the user asks to "create an Alpine component",
  "add Alpine.js", "use x-data", "add reactivity", "create a dropdown",
  "build a modal", "use Alpine store", "add x-show", "toggle visibility",
  "bind attributes with Alpine", "add focus trap", "use Alpine plugins",
  or mentions Alpine.js directives (x-data, x-bind, x-on, x-model, x-show,
  x-for, x-if, x-transition, x-cloak, x-ref, x-effect, x-teleport).
  Also applies when working with Alpine.js alongside HTMX.
version: 1.0.0
---

# Alpine.js v3 Development Guide

Alpine.js is a lightweight reactive framework for composing behavior directly in HTML markup. It handles **UI state** — modals, dropdowns, toggles, tabs, form visibility, client-side validation feedback, and focus management.

## Core Concept: x-data Scopes

Every Alpine component starts with `x-data` on a parent element. All child elements can access the reactive state.

```html
<div x-data="{ open: false, count: 0 }">
  <button @click="open = !open">Toggle</button>
  <div x-show="open">Content</div>
</div>
```

**Key rules:**
- `x-data` accepts a plain JavaScript object expression
- Nested `x-data` scopes: child can access parent data
- Data-less components: `<div x-data>` for simple interactions with no state
- Extract reusable components with `Alpine.data('name', () => ({...}))`

## Essential Directives

### Rendering and Visibility
- **`x-show`** — Toggle display via CSS (`display: none`). Element stays in DOM. Pair with `x-transition` for animations.
- **`x-if`** — Conditionally add/remove element from DOM. Must wrap a single `<template>` element. Use when element should not exist at all (not just hidden).
- **`x-for`** — Loop over arrays. Must wrap a `<template>` with a single root child. Always add `:key` for efficient re-renders.
- **`x-text`** — Set element's `textContent`. Automatically escapes HTML (safe for user content).
- **`x-html`** — Set element's `innerHTML`. **Security risk** — never use with user-provided content.

### Data Binding and Events
- **`x-bind` / `:`** — Dynamically set any HTML attribute. Special handling for `class` (object/array syntax) and `style` (object syntax).
- **`x-on` / `@`** — Attach event listeners. Supports all DOM events plus custom events.
- **`x-model`** — Two-way binding for form inputs. Works with text, textarea, checkbox, radio, select, range. Modifiers: `.lazy`, `.debounce.500ms`, `.number`, `.trim`.

### Lifecycle and Side Effects
- **`x-init`** — Run expression when component initializes. Use for fetching data, setting up listeners.
- **`x-effect`** — Run expression reactively whenever dependencies change. Auto-tracks dependencies (like Vue's `watchEffect`).

### Utility Directives
- **`x-ref`** — Name an element for access via `$refs.name` in JavaScript.
- **`x-cloak`** — Hide element until Alpine initializes. **Must add CSS**: `[x-cloak] { display: none !important; }`
- **`x-teleport`** — Move element to another location in DOM (e.g., modals to `<body>`). Must be on a `<template>` element.
- **`x-ignore`** — Skip Alpine initialization for this subtree.
- **`x-id`** — Generate scoped unique IDs for accessibility patterns. Use with `$id('name')` magic to produce `name-1`, `name-2`, etc.

## Event Modifiers

Event modifiers chain after the event name with dots. Most common: `.prevent`, `.stop`, `.outside` (click outside), `.window` (listen on window), `.once`, `.debounce.500ms`, `.self`.

**Keyboard modifiers:** `.enter`, `.escape`, `.tab`, `.space`, `.arrow-up`, `.arrow-down`, `.shift`, `.meta`, `.ctrl`, `.alt`. Combine: `@keyup.shift.enter="submit()"`

Full modifier list with descriptions in **`references/alpine-directives.md`**.

## Magic Properties

| Property | Purpose |
|----------|---------|
| `$el` | Current DOM element |
| `$refs` | Access named elements (`x-ref`) |
| `$store` | Access global stores |
| `$watch` | Watch a property for changes |
| `$dispatch` | Dispatch a custom DOM event |
| `$nextTick` | Execute after DOM update |
| `$root` | Root element of component |
| `$data` | Current scope's data object |
| `$id` | Generate unique IDs |

## Global State with Alpine.store

Define stores in `alpine:init` event, access with `$store`:

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('notifications', {
    items: [],
    add(message) { this.items.push({ message, id: Date.now() }) },
    remove(id) { this.items = this.items.filter(n => n.id !== id) },
    get count() { return this.items.length }
  })
})
</script>

<span x-data x-text="$store.notifications.count"></span>
```

## Transitions

Add smooth enter/leave animations to `x-show` and `x-if`:

```html
<div x-show="open"
     x-transition:enter="transition ease-out duration-300"
     x-transition:enter-start="opacity-0 transform scale-90"
     x-transition:enter-end="opacity-100 transform scale-100"
     x-transition:leave="transition ease-in duration-200"
     x-transition:leave-start="opacity-100 transform scale-100"
     x-transition:leave-end="opacity-0 transform scale-90">
```

Shorthand `x-transition` applies sensible defaults (fade + scale).

## Official Plugins

Load plugins **before** Alpine.js in `<head>`:

| Plugin | Purpose | Key directive/feature |
|--------|---------|----------------------|
| **Focus** | Focus trapping for modals/dialogs | `x-trap`, `x-trap.inert.noscroll` |
| **Collapse** | Smooth height animations | `x-collapse`, `x-collapse.duration.500ms` |
| **Intersect** | Intersection Observer | `x-intersect`, `x-intersect:enter`, `x-intersect:leave` |
| **Persist** | LocalStorage persistence | `$persist(value)`, `$persist(value).as('key')` |
| **Mask** | Input masking | `x-mask="(999) 999-9999"`, `x-mask:dynamic` |
| **Morph** | DOM morphing | `Alpine.morph(el, html)` |
| **Sort** | Drag-and-drop sorting | `x-sort`, `x-sort:item`, `x-sort:group` |

## Alpine + HTMX Integration

Alpine handles UI state, HTMX handles server communication. They complement each other.

### Event bridging

Use kebab-case for HTMX events in Alpine listeners (not camelCase):

```html
<button hx-post="/api/save"
        @htmx:before-request="$el.disabled = true; $el.textContent = 'Saving...'"
        @htmx:after-request="$el.disabled = false; $el.textContent = 'Save'"
        @htmx:response-error="$store.toasts.add('Save failed', 'error')">
    Save
</button>
```

### Key patterns

- **Dynamic hx-vals from Alpine state**: `:hx-vals="JSON.stringify({ id: currentId })"`
- **Close modals after success**: `@htmx:after-request="if($event.detail.successful) closeModal()"`
- **Reset Alpine state after swap**: `@htmx:after-swap="editing = false"`
- **Preserve Alpine scope**: Place `x-data` on a parent **above** the HTMX swap target — Alpine state is lost if the `x-data` element itself is swapped out

## Accessibility Requirements

- Modals: `role="dialog"`, `aria-labelledby`, `aria-modal="true"`, focus trap with `x-trap.inert.noscroll`
- Return focus to trigger element on close: `$refs.trigger.focus()`
- Escape key closes: `@keydown.escape.window="close()"`
- Dropdowns: `aria-expanded`, `aria-haspopup`, `role="menu"` on container
- Toggle buttons: `:aria-pressed="isActive"`
- Live regions: `aria-live="polite"` for dynamic content updates

## Additional Resources

### Reference Files
- **`references/alpine-directives.md`** — Complete directive reference with all modifiers, edge cases, and advanced patterns
- **`references/alpine-patterns.md`** — Common component patterns: modals, dropdowns, tabs, accordions, search filters, toast notifications, and more
