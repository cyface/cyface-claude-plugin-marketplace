# Alpine.js v3 — Directive, Magic and Global Reference

Current as of Alpine 3.17.x. Version notes mark features that older 3.x releases lack.

## Contents

- [x-data](#x-data)
- [x-init](#x-init)
- [x-show](#x-show)
- [x-bind / :](#x-bind--)
- [x-on / @](#x-on--)
- [x-model](#x-model)
- [x-modelable](#x-modelable)
- [x-for](#x-for)
- [x-if](#x-if)
- [x-text / x-html](#x-text--x-html)
- [x-transition](#x-transition)
- [x-effect](#x-effect)
- [x-ref](#x-ref)
- [x-cloak](#x-cloak)
- [x-teleport](#x-teleport)
- [x-ignore](#x-ignore)
- [x-id](#x-id)
- [Magics](#magics)
- [Globals](#globals)
- [Reactivity gotchas](#reactivity-gotchas)
- [CSP build](#csp-build)

---

## x-data

Declares a component scope. Everything inside can read and write it.

```html
<!-- Object literal -->
<div x-data="{ open: false, items: [], count: 0 }">

<!-- Methods, getters, lifecycle -->
<div x-data="{
  count: 0,
  get doubled() { return this.count * 2 },   // recomputed on every read (not cached)
  increment() { this.count++ },
  init() { /* before first render; x-init on the same element runs after this */ },
  destroy() { /* on removal, or when a wrapping x-if becomes false */ }
}">

<!-- Stateless scope so $refs / $dispatch / @ work -->
<button type="button" x-data @click="$dispatch('ping')">Ping</button>

<!-- Nested scopes: child reads parent; closest definition wins on name clashes -->
<div x-data="{ name: 'Ada' }">
  <div x-data="{ greeting: 'Hi' }"><span x-text="greeting + ' ' + name"></span></div>
</div>

<!-- Reusable component -->
<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('counter', (start = 0) => ({
    count: start,
    increment() { this.count++ },
  }))
})
</script>
<div x-data="counter(10)">…</div>
```

Properties are deeply reactive (nested objects and arrays are tracked). `this` inside methods is the reactive scope, so `this.$watch`, `this.$refs`, `this.$el`, `this.$store`, `this.$dispatch`, `this.$nextTick` all work in `Alpine.data` objects.

---

## x-init

Run an expression when the element initializes. Works with or without `x-data`.

```html
<div x-data="{ posts: [] }" x-init="posts = await (await fetch('/api/posts')).json()">
<img x-init="console.log('image element initialized')">
<div x-data x-init="$nextTick(() => $refs.input.focus())">
```

Order on one element: data object `init()` method, then `x-init`. If you only need `init()`, skip `x-init`.

---

## x-show

Toggles `display: none`. The element stays in the DOM, so form values and nested component state persist.

```html
<div x-show="open">…</div>
<div x-show="open" x-cloak>Initially hidden without a flash</div>
<div x-show.important="open">Wins over a CSS rule that sets display</div>
<div x-show="open" x-transition>Animated</div>
```

Use `x-show` for frequent toggles and anything with transitions; use `x-if` when the element should not exist at all.

---

## x-bind / :

```html
<img :src="url" :alt="alt">
<input :disabled="busy" :placeholder="hint">
<a :href="url" :target="external ? '_blank' : null">   <!-- null/false removes the attribute -->

<!-- Class: object syntax toggles each key; static classes are preserved except ones Alpine toggles -->
<div class="card" :class="{ 'is-active': active, 'has-error': errors.length }">
<!-- Class: string expression is merged with static classes -->
<div :class="active ? 'ring-2' : ''">

<!-- Style: object syntax merges with static style -->
<div :style="{ color: textColor, '--progress': pct + '%' }">

<!-- Bind a whole bag of attributes / directives -->
<div x-bind="{ id: 'item-' + id, 'data-active': active, '@click.outside'() { this.open = false } }">
<!-- Or a named bag registered with Alpine.bind('Name', () => ({...})) -->
<button x-bind="DeleteButton">
```

Object syntax is only available for `class` (and `style`). Boolean attributes (`disabled`, `checked`, `required`, `open`) are added or removed based on truthiness.

---

## x-on / @

```html
<button type="button" @click="count++">+</button>
<form @submit.prevent="save()">
<input @keydown.enter="submit()" @keydown.escape="cancel()" @keydown.arrow-down.prevent="next()">
<div @custom-event.window="handle($event.detail)">
<button @click="save">   <!-- method referenced without () receives the event -->
```

Event names must be lowercase; kebab-case custom events are the convention.

### Modifiers

| Modifier | Effect |
|----------|--------|
| `.prevent` | `preventDefault()` |
| `.stop` | `stopPropagation()` |
| `.self` | Only when `event.target` is this element |
| `.outside` | Fires for clicks outside the element (only evaluated while the element is visible) |
| `.window` / `.document` | Listen on `window` / `document` |
| `.once` | Remove after first call |
| `.debounce[.500ms]` | Debounce, default 250ms |
| `.throttle[.500ms]` | Throttle, default 250ms |
| `.passive` / `.passive.false` | Passive listener (scroll/touch perf); `.passive.false` makes touch/wheel cancelable (3.15.9) |
| `.capture` | Capture phase |
| `.camel` | `@custom-event.camel` listens for `customEvent` |
| `.dot` | `@custom-event.dot` listens for `custom.event` |

### Key modifiers

`.enter` `.escape` `.space` `.tab` `.up` `.down` `.left` `.right` `.shift` `.ctrl` `.cmd` `.meta` `.alt` `.caps-lock` `.equal` `.period` `.comma` `.slash`, plus any kebab-cased `KeyboardEvent.key` such as `.page-down` or `.arrow-down`.

- Chain: `@keydown.ctrl.enter="submit()"`, `@keydown.shift.tab="prev()"`.
- The `.comma` key modifier (for the `,` key) was added in 3.13.10.
- `.shift` `.ctrl` `.cmd` `.meta` `.alt` also work on mouse events since 3.14: `@click.shift="rangeSelect()"`.

---

## x-model

Two-way binding for `input`, `textarea`, `select` (single and multiple), checkboxes (boolean or array), radios and range.

```html
<input x-model="name">
<input type="checkbox" x-model="agreed">                 <!-- boolean -->
<input type="checkbox" value="red" x-model="colors">    <!-- array -->
<input type="radio" value="s" x-model="size">
<select x-model="country">…</select>
<select x-model="tags" multiple>…</select>
<input type="range" x-model.number="volume">
```

| Modifier | Effect |
|----------|--------|
| `.lazy` / `.change` | Sync on `change` instead of `input` |
| `.blur` | Sync on blur, even if unchanged (3.15.5) |
| `.enter` | Sync when Enter is pressed; does not prevent submit (3.15.5) |
| `.number` | Cast to number |
| `.boolean` | Cast `"true"/"false"/1/0` to boolean (3.13.3) |
| `.trim` | Trim whitespace |
| `.debounce[.500ms]` / `.throttle[.500ms]` | Rate-limit syncing |
| `.fill` | Seed the property from the element's `value` attribute when the property is null/empty (3.12) |

Modifiers combine: `x-model.change.blur.enter="q"`. Programmatic access: `el._x_model.get()` / `el._x_model.set(v)`.

---

## x-modelable

Lets a reusable component expose one of its properties to an outer `x-model`.

```html
<div x-data="{ number: 5 }">
  <div x-data="{ count: 0 }" x-modelable="count" x-model="number">
    <button type="button" @click="count++">Increment</button>
  </div>
  Outer value: <span x-text="number"></span>
</div>
```

Values are cloned as JSON, so `File`, `Date`, `Map`, `Set`, class instances and DOM nodes do not survive. For those, `$dispatch('input', value)` from the inner component instead, which an outer `x-model` also listens to.

---

## x-for

```html
<template x-for="item in items" :key="item.id">
  <li x-text="item.name"></li>
</template>

<template x-for="(item, index) in items" :key="item.id">…</template>
<template x-for="(value, key) in object" :key="key">…</template>
<template x-for="i in 10">…</template>                 <!-- 1..10 -->
<template x-for="tag in tagSet">…</template>           <!-- Sets supported (3.15.9) -->
```

Rules: must be on `<template>`; exactly one root element inside (3.15.11 warns otherwise); `:key` must be unique (3.13.6 warns on duplicates) and should be a stable id, not the index. Nest templates for nested loops.

---

## x-if

```html
<template x-if="user.isAdmin">
  <section>Admin panel</section>      <!-- exactly one root -->
</template>
```

No transitions (use `x-show`). When the condition turns false the subtree is removed and any `destroy()` methods inside run. Prefer `x-show` for anything toggled often.

---

## x-text / x-html

```html
<span x-text="count + ' items'"></span>       <!-- sets textContent, HTML-escaped -->
<div x-html="trustedMarkup"></div>             <!-- sets innerHTML; never for user content -->
```

`x-html` is a stored-XSS vector with user-provided strings. Prefer `x-text`, or have the server sanitize and render.

---

## x-transition

```html
<div x-show="open" x-transition>                     <!-- fade + scale, 150ms in / 75ms out -->
<div x-show="open" x-transition.duration.300ms>
<div x-show="open" x-transition:enter.duration.300ms x-transition:leave.duration.150ms>
<div x-show="open" x-transition.delay.50ms>
<div x-show="open" x-transition.opacity>             <!-- fade only -->
<div x-show="open" x-transition.scale.90>            <!-- scale from 90% -->
<div x-show="open" x-transition.scale.origin.top.right>

<!-- Class API (Tailwind style) -->
<div x-show="open"
     x-transition:enter="transition ease-out duration-200"
     x-transition:enter-start="opacity-0 translate-y-1"
     x-transition:enter-end="opacity-100 translate-y-0"
     x-transition:leave="transition ease-in duration-150"
     x-transition:leave-start="opacity-100 translate-y-0"
     x-transition:leave-end="opacity-0 translate-y-1">
```

Only works with `x-show`. Respect `prefers-reduced-motion` in CSS if you use the class API.

---

## x-effect

```html
<div x-data="{ theme: 'light' }" x-effect="document.documentElement.dataset.theme = theme">
```

Runs immediately and again whenever a reactive value it **synchronously** read changes. Reads inside `setTimeout`, `await`, or promise callbacks are not tracked. There is no old value; use `$watch` for that.

---

## x-ref

```html
<input x-ref="search">
<button type="button" @click="$refs.search.focus()">Focus</button>
```

`$refs` resolves within the component, including into `x-teleport`ed content.

---

## x-cloak

```html
<style>[x-cloak] { display: none !important; }</style>
<div x-data="{ open: false }" x-show="open" x-cloak>…</div>
```

Alpine removes the attribute when it initializes the element. Without the CSS rule nothing is hidden. The morph plugin (3.17.5+) no longer re-applies `x-cloak` after a morph.

---

## x-teleport

```html
<div x-data="{ open: false }">
  <button type="button" @click="open = true">Open</button>
  <template x-teleport="body">
    <div x-show="open" x-cloak role="dialog" …>…</div>   <!-- appended to <body>, keeps this scope -->
  </template>
</div>
```

Must be on `<template>`. The value is any `querySelector` selector (first match). Teleported content keeps `$refs`, `$root` and scope. Events you listen for on the `<template x-teleport>` element itself (`<template x-teleport="body" @click=…>`) are forwarded to it and stopped from bubbling at the teleported node; other events bubble normally from where the content really lives. Nested teleports render as siblings.

---

## x-ignore

```html
<div x-ignore>        <!-- Alpine skips this entire subtree -->
  <div data-third-party-widget></div>
</div>
<div x-ignore.self>   <!-- skips only this element's own directives, not children (exported, undocumented) -->
```

Use for widgets that own their DOM (maps, editors) to avoid double initialization. To initialize later, remove the attribute, wait a tick (`await Alpine.nextTick()`) so the directive's cleanup clears the ignore flag, then call `Alpine.initTree(el)`.

---

## x-id

```html
<div x-data x-id="['text-input']">
  <label :for="$id('text-input')">Email</label>
  <input :id="$id('text-input')">
</div>

<!-- Keyed ids inside loops -->
<li :id="$id('option', item.id)" :aria-selected="…">
```

`$id()` returns ids like `text-input-1`, scoped to the nearest `x-id` declaring that name, so repeated components do not collide.

---

## Magics

| Magic | Details |
|-------|---------|
| `$el` | Current DOM element |
| `$refs` | Map of `x-ref` elements in the component |
| `$store` | Access stores: `$store.cart.items` |
| `$watch('prop', (value, old) => {})` | Dot paths (`'user.name'`); deep (fires on nested changes, callback gets the top-level value); lazy (first change only); not fired for unchanged primitives (3.15.7). Do not mutate the watched value inside the callback (infinite loop). |
| `$dispatch('name', detail, options?)` | Dispatches a bubbling `CustomEvent`. Third argument overrides options (`{ bubbles: false }`); returns `false` if a listener called `preventDefault()` (3.15.9). Use `.window` listeners for cross-component communication. |
| `$nextTick(cb?)` | Runs after Alpine flushes DOM updates; returns a promise |
| `$root` | Closest `x-data` element |
| `$data` | The merged reactive scope at this element |
| `$id('name', key?)` | See `x-id` |

---

## Globals

Register inside `alpine:init` (CDN) or between `import` and `Alpine.start()` (bundle).

```js
Alpine.data('name', (args) => ({ … }))        // reusable component
Alpine.store('name', { … } | value)           // global state; init() runs right after registration
Alpine.store('name')                          // read a store from JS
Alpine.bind('Name', () => ({ ':disabled'() {}, '@click'() {} }))   // reusable attribute bag
Alpine.directive('name', (el, { value, modifiers, expression }, { Alpine, effect, cleanup, evaluate, evaluateLater }) => {})
Alpine.directive('name', …).before('bind')    // ordering relative to built-ins
Alpine.magic('name', (el, { Alpine }) => value)
Alpine.plugin(fn | [fn, fn])
Alpine.reactive(obj)  /  Alpine.effect(fn)    // the reactivity primitives (Vue reactivity under the hood)
Alpine.morph(el, html, options) / Alpine.morphBetween(startNode, endNode, html, options)   // morph plugin
Alpine.$persist(value).as('key')              // persist plugin, for stores
Alpine.start()                                // bundles only; exactly once
Alpine.setErrorHandler((error, el, expression) => {})   // 3.15.2: central error reporting
Alpine.interceptInit(el => { … })             // 3.11+: hook before each element initializes
Alpine.deferInit(el, promise)                 // 3.17.0: suspend a subtree until the promise settles
Alpine.initTree(el) / Alpine.destroyTree(el)  // manual (re)initialization, e.g. after x-ignore
Alpine.raw(proxy)                             // unwrap a reactive proxy (exported, undocumented)
Alpine.version
```

### Deferring initialization (3.17.0)

```js
Alpine.interceptInit(el => {
  if (el.hasAttribute('data-needs-widget') && !window.Widget) {
    Alpine.deferInit(el, loadWidgetScript())   // x-cloak stays on until the promise settles
  }
})
```

Must be registered synchronously (from `interceptInit` or on an already-initialized element). A rejected promise is reported through the error handler and the tree initializes anyway. A never-settling promise suspends forever, so add timeouts.

---

## Reactivity gotchas

- **Getters re-run on every access.** For expensive filtering over large arrays, compute once in a method or cache in a property.
- **Destructuring breaks reactivity.** `const { items } = this` copies the current value; reference `this.items` directly.
- **Effects and getters track only synchronous reads.**
- **Replacing vs. mutating.** Both `this.items.push(x)` and `this.items = [...this.items, x]` are reactive; prefer whichever reads better.
- **`$watch` on objects fires for nested changes** but hands you the top-level value, not the changed leaf.
- **Proxies in third-party APIs.** When passing reactive objects to libraries that do identity checks or structured cloning, unwrap with `Alpine.raw(obj)` or `JSON.parse(JSON.stringify(obj))`.

---

## CSP build

`@alpinejs/csp` (same version as core) replaces `eval`-based evaluation with a parser. Load it *instead of* the core script and add a `nonce` if your policy needs one:

```html
<script defer nonce="…" src="https://cdn.jsdelivr.net/npm/@alpinejs/csp@3.17.5/dist/cdn.min.js"></script>
```

Supported in expressions: literals, property paths (`user.name`, `items[0]`), comparison and logical operators, ternaries, string concatenation, assignment to top-level properties, `count++`, method calls on data (`items.push(x)`), `x-model="user.name"`.

Not supported: arrow functions, template literals, destructuring, spread, globals (`window`, `document`, `console`, `Math`, `JSON`, `parseInt`), and `x-html`. Nested property assignment (`user.name = 'x'`) works on plain data objects since 3.15.12 (writes to DOM objects are blocked), although the docs page still lists it as unsupported; a method call is the portable choice. The `allowGlobals` option defaults to `false` since 3.15.1. Put logic in `Alpine.data()` methods and keep markup expressions simple.
