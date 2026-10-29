---
name: alpine-js
description: >-
  Alpine.js v3 (3.17.x) guidance for reactive UI written directly in HTML. Use this
  skill BEFORE writing or editing any Alpine markup, even a small snippet you could
  write from memory: it carries version-specific rules (template-only directives,
  :key, x-cloak CSS, x-trap focus handling, plugin load order, the rewritten CSP
  build, htmx 2 vs 4 event names) that training data frequently gets wrong. Trigger
  on x-data, x-show, x-model, x-for, @click, :class, Alpine.data, Alpine.store,
  $dispatch, x-trap, x-collapse, x-anchor, and on requests for a dropdown, modal,
  dialog, tabs, accordion, toggle, toast, wizard, client-side filter, or any
  "sprinkle of interactivity" on a server-rendered page, including Django, Flask,
  Rails, Laravel/Livewire or Phoenix templates that already use Alpine even when
  the user does not name it. Also use when Alpine is combined with htmx.
---

# Alpine.js v3 Development Guide

Alpine composes behavior directly in markup. It owns **client-side UI state**: open/closed, selected tab, form visibility, client-side validation feedback, focus, and small reactive widgets. When a page also uses htmx, htmx owns server communication and Alpine owns what happens around it (see "Alpine + htmx" below).

Current stable line: **3.17.x** (no v4 exists). Everything below is v3.

## Installation

```html
<!-- Plugins first, then core. Pin a real version in production. -->
<script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/focus@3.17.5/dist/cdn.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.17.5/dist/cdn.min.js"></script>
<style>[x-cloak] { display: none !important; }</style>
```

- `defer` is required so Alpine runs after the DOM is parsed.
- **Plugin scripts go before the core script**; with npm, register them between `import` and `Alpine.start()`:
  ```js
  import Alpine from 'alpinejs'
  import focus from '@alpinejs/focus'
  Alpine.plugin(focus)          // also accepts an array of plugins
  window.Alpine = Alpine        // handy for devtools and console debugging
  Alpine.start()                // call exactly once per page
  ```
- Under a strict Content-Security-Policy that forbids `unsafe-eval`, use the **CSP build** (`@alpinejs/csp`) instead of core. See "CSP build" below.

## Core model

Every component starts at an `x-data` element; descendants read and write that scope. Nested `x-data` scopes see their ancestors, and the closest definition wins.

```html
<div x-data="{ open: false, count: 0, get doubled() { return this.count * 2 } }">
  <button type="button" @click="open = !open">Toggle</button>
  <div x-show="open" x-cloak>Content</div>
</div>
```

Prefer `Alpine.data()` for anything with more than a couple of properties, and register it in `alpine:init` (or before `Alpine.start()` in a bundle):

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('dropdown', (initiallyOpen = false) => ({
    open: initiallyOpen,
    init() { /* runs before the element renders; this.$watch etc. are available */ },
    destroy() { /* runs when the element is removed or an x-if goes false */ },
    toggle() { this.open = !this.open },
  }))
})
</script>
<div x-data="dropdown(true)">…</div>
```

Lifecycle events: `alpine:init` (register data, stores, directives, magics, binds) and `alpine:initialized` (page is live). An `init()` method on the data object runs automatically and before any `x-init` on the same element.

## Rules that prevent most Alpine bugs

- **`x-for`, `x-if` and `x-teleport` must be on a `<template>` with exactly one root child.** Alpine warns when they are not on a `<template>`; `x-for` (3.15.11+) also warns about extra roots, while `x-if`/`x-teleport` silently use only the first.
- **Add `:key` to `x-for`** when items can be added, removed or reordered. Use a stable id, never the index.
- **`x-transition` only works with `x-show`**, never `x-if`.
- **`x-cloak` needs the CSS rule** `[x-cloak] { display: none !important; }` somewhere on the page, or it does nothing.
- **Never put user-provided content in `x-html`.** Use `x-text`, or sanitize on the server.
- **Getters are not cached.** `get filtered()` re-runs on every read; keep them cheap or precompute in a method.
- **Event names are lowercase.** `@click`, `@keydown.escape`. Custom events use kebab-case; use `.camel` or `.dot` only when a library dispatches `camelCase`/`dotted.names`.
- **Buttons inside forms need `type="button"`** unless they are meant to submit.
- **Effects track only synchronous reads.** Reads inside `setTimeout`, `await` or `.then()` are not tracked by `x-effect`/`Alpine.effect`.
- **`x-modelable` clones via JSON.** Files, Dates, Maps, Sets and DOM nodes do not survive it; `$dispatch('input', value)` instead.

## Directive cheat sheet

| Directive | Use for | Notes |
|-----------|---------|-------|
| `x-data` | Declare a component scope | Object literal or `Alpine.data` name; `x-data` alone for stateless |
| `x-init` | Run code when the element initializes | Works without `x-data`; use `$nextTick` for post-render work |
| `x-show` | Toggle `display` | `.important` when a CSS rule fights it; keeps the element in the DOM |
| `x-if` | Add/remove from the DOM | On `<template>`; no transitions; runs `destroy()` of inner components |
| `x-for` | Loop | `(item, index) in items`, `(value, key) in obj`, `i in 10`; Sets supported |
| `x-bind` / `:` | Attribute binding | Object syntax for `class`/`style`; bind `null`/`false` to remove; `x-bind="obj"` binds many |
| `x-on` / `@` | Event listeners | Rich modifier set, see below |
| `x-model` | Two-way form binding | `.lazy` `.change` `.blur` `.enter` `.number` `.boolean` `.trim` `.fill` `.debounce` `.throttle` |
| `x-modelable` | Expose inner state to an outer `x-model` | For reusable inputs/components |
| `x-text` / `x-html` | Set content | `x-text` is XSS-safe; `x-html` is not |
| `x-effect` | Reactive side effect | Runs immediately and on every change of what it read |
| `x-ref` / `$refs` | Name an element | Works across `x-teleport` |
| `x-cloak` | Hide until Alpine starts | Requires the CSS rule above |
| `x-teleport` | Move content elsewhere in the DOM | On `<template>`; selector target; keeps scope; listeners on the template receive forwarded events |
| `x-ignore` | Skip a subtree | Use for third-party widgets that manage their own DOM |
| `x-id` / `$id()` | Scoped unique ids | For `for`/`id`, `aria-controls`, `aria-labelledby` |
| `x-transition` | Enter/leave animation | `.duration.300ms` `.opacity` `.scale.90` `.scale.origin.top` or the six class hooks |

Full syntax, every modifier, and edge cases: **`references/alpine-directives.md`**.

### Event modifiers (`x-on`)

`.prevent` `.stop` `.self` `.outside` (only while the element is visible) `.window` `.document` `.once` `.debounce[.500ms]` `.throttle[.500ms]` `.passive` `.passive.false` `.capture` `.camel` `.dot`

Key modifiers: `.enter` `.escape` `.space` `.tab` `.up/.down/.left/.right` `.shift` `.ctrl` `.cmd`/`.meta` `.alt` `.caps-lock` `.equal` `.period` `.comma` `.slash`, or any kebab-cased `KeyboardEvent.key` (`.page-down`). Chain them: `@keydown.ctrl.enter="save()"`. Since 3.14 the `.shift/.ctrl/.cmd/.alt` modifiers also work on mouse events (`@click.shift`).

## Magics

| Magic | Purpose |
|-------|---------|
| `$el` | The current element |
| `$refs` | Elements named with `x-ref` |
| `$store` | Global stores (`$store.cart.count`) |
| `$watch('prop', (value, old) => …)` | Watch a property (dot paths allowed, deep by default, lazy) |
| `$dispatch('name', detail, options?)` | Bubbling `CustomEvent`; returns `false` if cancelled; `$dispatch('input', v)` drives an outer `x-model` |
| `$nextTick(cb?)` | After the next DOM flush; awaitable |
| `$root` | Closest `x-data` element |
| `$data` | Merged current scope |
| `$id('name', key?)` | Scoped id, see `x-id` |

Plugin magics: `$persist`, `$focus`, `$anchor`, `$money`/`$input` (mask), `$width`/`$height` (resize), `$item`/`$position` (sort).

## Global state

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('toasts', {
    items: [],
    init() { /* runs right after registration */ },
    add(message, type = 'info') {
      const id = crypto.randomUUID()
      this.items.push({ id, message, type })
      setTimeout(() => this.remove(id), 5000)
    },
    remove(id) { this.items = this.items.filter(t => t.id !== id) },
  })
})
</script>
<button type="button" x-data @click="$store.toasts.add('Saved')">Save</button>
```

`Alpine.store('name')` reads a store from plain JS. `Alpine.bind('Name', () => ({ … }))` packages a bundle of attributes and listeners for reuse via `x-bind="Name"`.

## Official plugins (all `@alpinejs/<name>`, versioned with core)

| Plugin | Gives you | Essentials |
|--------|-----------|------------|
| **focus** | `x-trap`, `$focus` | `x-trap.inert.noscroll="open"` for dialogs; `.noreturn`, `.noautofocus` |
| **collapse** | `x-collapse` | On an `x-show` element; `.duration.500ms`, `.min.50px` |
| **intersect** | `x-intersect[:enter|:leave]` | `.once` `.half` `.full` `.threshold.50` `.margin.200px` `.parent` `.dwell[.500ms]` |
| **resize** | `x-resize`, `$width`/`$height` | `.document`, `.viewport` |
| **persist** | `$persist(v)` | `.as('key')`, `.using(sessionStorage)`; use `function` syntax in `Alpine.data` for `this.$persist` |
| **mask** | `x-mask`, `x-mask:dynamic`, `$money`, `$input` | `9` digit, `a` letter, `*` any |
| **anchor** | `x-anchor` (Floating UI) | `.bottom-start.offset.8`, `.noflip`, `.fixed`, `.no-style` + `$anchor.x/y` |
| **morph** | `Alpine.morph(el, html, opts)`, `Alpine.morphBetween(start, end, html)` | Keeps Alpine state across DOM updates; keyed by `key=""` by default |
| **sort** | `x-sort`, `x-sort:item/:group/:handle/:ignore/:config`, `$item`/`$position` | SortableJS under the hood; `.ghost` |

Details, options and examples: **`references/alpine-plugins.md`**.

## Alpine + htmx

Alpine and htmx coexist well because htmx swaps HTML and Alpine's MutationObserver initializes any `x-data` that arrives. The three things that go wrong:

1. **State lost on swap.** Alpine state lives on the `x-data` element. If htmx swaps that element (or an ancestor) the state is recreated from scratch. Put `x-data` on a parent *above* the `hx-target`, or accept the reset and let the server render the initial state.
2. **Wrong event name.** The HTML parser lowercases attribute names, so `@htmx:afterRequest` reaches Alpine as `@htmx:afterrequest` and never matches. The correct spelling depends on the htmx line (check the script tag):
   - **htmx 2.x** dispatches every event twice, camelCase and kebab-case. Use the kebab form: `@htmx:after-request`, `@htmx:response-error`, `@htmx:after-swap`. `@htmx:afterRequest` silently never fires.
   - **htmx 4** names are already lowercase and colon-separated, dispatched once: `@htmx:after:request`, `@htmx:response:error`, `@htmx:after:swap`. The kebab aliases are gone.
3. **Alpine-rendered DOM being swapped.** Do not `hx-target` into something `x-for`/`x-if` controls; give htmx its own container.

```html
<div x-data="{ open: false }">                        <!-- state lives here -->
  <button type="button" @click="open = true">Edit</button>
  <form x-show="open" x-cloak
        hx-post="/notes/42" hx-target="#note-42" hx-swap="outerHTML"
        @htmx:after-request="if ($event.detail.successful) open = false">
    <!-- htmx 4: @htmx:after:request="if ($event.detail.ctx.response.status < 400) open = false" -->
    …
  </form>
</div>
<ul><li id="note-42">…</li></ul>                      <!-- swap target lives outside -->
```

- Pass Alpine data to htmx with `:hx-vals="JSON.stringify({ id })"` (htmx re-reads attributes at request time).
- To keep Alpine state *inside* swapped content, morph instead of replacing. htmx 2.x: the `alpine-morph` extension (`hx-ext="alpine-morph" hx-swap="morph"`, needs `@alpinejs/morph` loaded before Alpine) or `idiomorph`. htmx 4: `hx-swap="outerMorph"` is built in; add the `hx-alpine-compat` extension so `x-data` state is carried across the morph and Alpine initialization waits until the swap settles.
- Alpine initializes swapped-in nodes automatically; `Alpine.initTree()` is only needed for `x-ignore`d or hand-built nodes. Markup that Alpine renders with `hx-*` attributes needs `htmx.process(el)`.
- Which library owns what, CSRF, and the full 2.x/4 event table live in the **htmx** skill.

## Accessibility

- **Dialogs**: `role="dialog"`, `aria-modal="true"`, `aria-labelledby` via `x-id`/`$id`, `x-trap.inert.noscroll="open"`, `@keydown.escape.prevent.stop="close()"`, return focus to the trigger on close. See the modal pattern in `references/alpine-patterns.md`.
- **Dropdowns/popovers**: trigger has `type="button"`, `:aria-expanded="open"`, `:aria-controls="$id('panel')"`; close on `@click.outside`, Escape, and `@focusin.window` leaving the panel. Only use `role="menu"`/`menuitem` for true command menus with arrow-key navigation.
- **Disclosure/accordion**: `:aria-expanded` on the button, `x-collapse` on the panel.
- **Toggles**: `:aria-pressed` for toggle buttons, or `role="switch"` + `:aria-checked`.
- **Live regions**: `aria-live="polite"` on toast/status containers that exist before content arrives.
- **Visibility vs. presence**: `x-show` content is hidden from assistive tech while `display:none`, which is usually what you want; `x-if` removes it entirely.

## CSP build

`@alpinejs/csp` evaluates expressions without `eval`/`new Function`. Since 3.15 it has a real expression parser, so most markup works unchanged: object and array literals, property paths (`user.name`, `items[0]`), comparisons, `&&`/`||`/`!`, ternaries, string concatenation, assignments and `count++`, `x-model="user.name"`, and method calls on your data (`items.push(x)`). Not supported: arrow functions, template literals, destructuring, spread, globals (`window`, `document`, `Math`, `JSON`, `console`), and `x-html`. Nested property assignment (`user.name = 'x'`) works on plain data objects since 3.15.12 even though the docs still list it as unsupported; a method call is the portable choice. Keep anything non-trivial in `Alpine.data()` methods.

## Reference files

- **`references/alpine-directives.md`** — every directive and magic with all modifiers, globals (`Alpine.data/store/bind/directive/magic/plugin/deferInit/setErrorHandler`), reactivity gotchas.
- **`references/alpine-plugins.md`** — the nine official plugins with options and examples.
- **`references/alpine-patterns.md`** — accessible modal, dropdown, tabs, accordion, toasts, filters, wizard, dark mode, custom inputs with `x-modelable`, sortable lists, and more.
