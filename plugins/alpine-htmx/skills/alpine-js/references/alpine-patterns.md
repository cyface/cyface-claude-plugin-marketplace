# Alpine.js — Component Patterns

Copy-and-adapt patterns. Each one is accessible by default and uses only core Alpine unless a plugin is named. Tailwind-style class names are illustrative.

## Contents

- [Modal dialog](#modal-dialog)
- [Dropdown / popover](#dropdown--popover)
- [Tabs](#tabs)
- [Accordion](#accordion)
- [Toast notifications](#toast-notifications)
- [Search / filter list](#search--filter-list)
- [Toggle switch](#toggle-switch)
- [Inline confirm](#inline-confirm)
- [Lazy-loaded section](#lazy-loaded-section)
- [Dark mode with persistence](#dark-mode-with-persistence)
- [Character counter](#character-counter)
- [Multi-step wizard](#multi-step-wizard)
- [Clipboard copy](#clipboard-copy)
- [Custom input with x-modelable](#custom-input-with-x-modelable)
- [Sortable list](#sortable-list)
- [Reusable component with Alpine.data](#reusable-component-with-alpinedata)

---

## Modal dialog

Requires `@alpinejs/focus`. Teleported to `<body>` so it escapes `overflow`/`z-index` traps.

```html
<div x-data="{ open: false }" x-id="['modal-title']">
  <button type="button" @click="open = true" x-ref="trigger">Delete account</button>

  <template x-teleport="body">
    <div x-show="open" x-cloak
         class="fixed inset-0 z-50 flex items-center justify-center"
         @keydown.escape.prevent.stop="open = false; $refs.trigger.focus()">

      <!-- Backdrop -->
      <div class="fixed inset-0 bg-black/50" x-show="open" x-transition.opacity aria-hidden="true"></div>

      <!-- Panel -->
      <div x-show="open" x-transition
           x-trap.inert.noscroll="open"
           @click.outside="open = false; $refs.trigger.focus()"
           role="dialog" aria-modal="true" :aria-labelledby="$id('modal-title')"
           class="relative rounded bg-white p-6 shadow">
        <h2 :id="$id('modal-title')">Delete your account?</h2>
        <p>This cannot be undone.</p>
        <div class="mt-4 flex gap-2">
          <button type="button" @click="open = false; $refs.trigger.focus()">Cancel</button>
          <button type="button" class="btn-danger" @click="deleteAccount(); open = false">Delete</button>
        </div>
      </div>
    </div>
  </template>
</div>
```

Why each piece is there:
- `x-trap.inert.noscroll` traps Tab, marks the rest of the page `aria-hidden`, and locks scroll; focus returns to the trigger automatically on release, and the explicit `$refs.trigger.focus()` covers cases where it does not.
- `@keydown.escape.prevent.stop` on the wrapper, not `.window`, so nested components do not all react.
- `@click.outside` on the panel closes on backdrop clicks without needing `@click.stop` inside.
- `x-id` + `$id` keep `aria-labelledby` unique when the component repeats.
- Buttons are `type="button"` so a surrounding form is never submitted by accident.

---

## Dropdown / popover

Follows the structure of the official Alpine dropdown component (which names its id scope `dropdown-button`). Add `@alpinejs/anchor` if the panel must escape a clipping container.

```html
<div x-data="{
       open: false,
       toggle() { this.open ? this.close() : (this.open = true) },
       close(focusAfter) { if (!this.open) return; this.open = false; focusAfter && focusAfter.focus() }
     }"
     x-id="['dropdown-panel']"
     @keydown.escape.prevent.stop="close($refs.button)"
     @focusin.window="!$refs.panel.contains($event.target) && close()"
     class="relative">

  <button type="button" x-ref="button" @click="toggle()"
          :aria-expanded="open" :aria-controls="$id('dropdown-panel')">
    Options
  </button>

  <div x-ref="panel" x-show="open" x-cloak x-transition.origin.top.left
       :id="$id('dropdown-panel')"
       @click.outside="close($refs.button)"
       class="absolute left-0 mt-2 w-48 rounded bg-white shadow">
    <a href="/settings" @click="close()">Settings</a>
    <button type="button" @click="archive(); close($refs.button)">Archive</button>
  </div>
</div>
```

Add `role="menu"` / `role="menuitem"` plus arrow-key handling (`$focus.wrap().next()` from the focus plugin) only when it is a true command menu; for a list of links, plain markup is more accessible.

---

## Tabs

```html
<div x-data="{ tab: 'general' }" x-id="['tab']">
  <div role="tablist" @keydown.right.prevent="$focus.wrap().next()" @keydown.left.prevent="$focus.wrap().previous()">
    <template x-for="t in ['general', 'advanced']" :key="t">
      <button type="button" role="tab"
              :id="$id('tab', t)" :aria-controls="$id('tab', t + '-panel')"
              :aria-selected="tab === t" :tabindex="tab === t ? 0 : -1"
              :class="{ 'active': tab === t }"
              @click="tab = t" @focus="tab = t"
              x-text="t"></button>
    </template>
  </div>

  <div role="tabpanel" :id="$id('tab', 'general-panel')" :aria-labelledby="$id('tab', 'general')" x-show="tab === 'general'">General settings</div>
  <div role="tabpanel" :id="$id('tab', 'advanced-panel')" :aria-labelledby="$id('tab', 'advanced')" x-show="tab === 'advanced'">Advanced settings</div>
</div>
```

The arrow-key handlers use `$focus` from `@alpinejs/focus`; drop them for a simpler version.

---

## Accordion

Requires `@alpinejs/collapse`.

```html
<div x-data="{ active: null }">
  <template x-for="faq in faqs" :key="faq.id">
    <div x-id="['faq']">
      <h3>
        <button type="button" @click="active = active === faq.id ? null : faq.id"
                :aria-expanded="active === faq.id" :aria-controls="$id('faq')"
                x-text="faq.question"></button>
      </h3>
      <div :id="$id('faq')" x-show="active === faq.id" x-collapse x-text="faq.answer"></div>
    </div>
  </template>
</div>
```

Set `active` to an array and toggle membership if several panels may be open at once.

---

## Toast notifications

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('toasts', {
    items: [],
    add(message, type = 'info', timeout = 5000) {
      const id = crypto.randomUUID()
      this.items.push({ id, message, type })
      if (timeout) setTimeout(() => this.remove(id), timeout)
    },
    remove(id) { this.items = this.items.filter(t => t.id !== id) },
  })
})
</script>

<!-- Once per layout. aria-live must exist before messages arrive. -->
<div x-data aria-live="polite" class="fixed bottom-4 right-4 space-y-2">
  <template x-for="toast in $store.toasts.items" :key="toast.id">
    <div role="status" x-transition :class="'toast toast-' + toast.type">
      <span x-text="toast.message"></span>
      <button type="button" @click="$store.toasts.remove(toast.id)" aria-label="Dismiss">&times;</button>
    </div>
  </template>
</div>

<!-- From anywhere, including htmx event handlers -->
<button type="button" x-data @click="$store.toasts.add('Saved', 'success')">Save</button>
```

Use `role="alert"` (assertive) only for errors that need immediate attention.

---

## Search / filter list

```html
<div x-data="{
  q: '',
  items: ['Apple', 'Banana', 'Cherry', 'Date'],
  get filtered() {
    const q = this.q.trim().toLowerCase()
    return q ? this.items.filter(i => i.toLowerCase().includes(q)) : this.items
  }
}">
  <label for="filter">Filter</label>
  <input id="filter" type="search" x-model.debounce.200ms="q" autocomplete="off">
  <p aria-live="polite" x-text="filtered.length + ' results'"></p>
  <ul>
    <template x-for="item in filtered" :key="item">
      <li x-text="item"></li>
    </template>
  </ul>
</div>
```

For server-side data, use htmx `hx-get` with `hx-trigger="input changed delay:300ms"` instead and keep Alpine out of the list (see the htmx skill).

---

## Toggle switch

```html
<button type="button" x-data="{ on: false }" role="switch" :aria-checked="on"
        @click="on = !on" :class="on ? 'bg-green-500' : 'bg-gray-300'">
  <span class="sr-only">Enable notifications</span>
  <span class="knob" :class="on ? 'translate-x-5' : 'translate-x-0'" aria-hidden="true"></span>
</button>
```

Use `role="switch"` + `aria-checked` for on/off, or `aria-pressed` for a pressed/unpressed toggle button. Not both.

---

## Inline confirm

```html
<div x-data="{ confirming: false }" @keydown.escape.window="confirming = false">
  <button type="button" x-show="!confirming" @click="confirming = true; $nextTick(() => $refs.yes.focus())">Delete</button>
  <span x-show="confirming" x-cloak role="group" aria-label="Confirm delete">
    Are you sure?
    <button type="button" x-ref="yes" @click="remove(); confirming = false">Yes, delete</button>
    <button type="button" @click="confirming = false">Cancel</button>
  </span>
</div>
```

With htmx, `hx-confirm` on the delete button is the simpler option; use this when you need a styled confirm.

---

## Lazy-loaded section

Requires `@alpinejs/intersect`. For HTML from the server, prefer htmx `hx-trigger="intersect once"`; this is the JSON/Alpine version.

```html
<section x-data="{ loaded: false, items: [] }"
         x-intersect.once.margin.200px="items = await (await fetch('/api/items')).json(); loaded = true">
  <template x-if="!loaded"><p class="skeleton">Loading…</p></template>
  <template x-for="item in items" :key="item.id">
    <article x-text="item.title"></article>
  </template>
</section>
```

---

## Dark mode with persistence

Requires `@alpinejs/persist`.

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('theme', {
    dark: Alpine.$persist(window.matchMedia('(prefers-color-scheme: dark)').matches).as('theme-dark'),
    toggle() { this.dark = !this.dark },
  })
})
</script>

<html x-data :class="{ 'dark': $store.theme.dark }">
  <button type="button" @click="$store.theme.toggle()" :aria-pressed="$store.theme.dark">
    <span x-text="$store.theme.dark ? 'Light mode' : 'Dark mode'"></span>
  </button>
</html>
```

To avoid a flash, also apply the class from an inline blocking script that reads `localStorage` before Alpine loads.

---

## Character counter

```html
<div x-data="{ text: '', max: 280 }">
  <label for="post">Post</label>
  <textarea id="post" x-model="text" :maxlength="max" :aria-describedby="'post-count'"></textarea>
  <p id="post-count" aria-live="polite" :class="{ 'text-red-600': text.length > max * 0.9 }">
    <span x-text="text.length"></span>/<span x-text="max"></span>
  </p>
</div>
```

---

## Multi-step wizard

```html
<form x-data="{
        step: 1, total: 3,
        form: { name: '', email: '', plan: 'free' },
        get canProceed() {
          if (this.step === 1) return this.form.name.trim().length > 0
          if (this.step === 2) return this.form.email.includes('@')
          return true
        },
        next() { if (this.canProceed && this.step < this.total) this.step++ },
        back() { if (this.step > 1) this.step-- },
      }"
      @submit.prevent="submit(form)">

  <ol class="steps" aria-label="Progress">
    <template x-for="i in total" :key="i">
      <li :aria-current="step === i ? 'step' : null" :class="{ done: step > i }" x-text="i"></li>
    </template>
  </ol>

  <fieldset x-show="step === 1"><legend>Name</legend><input x-model="form.name" required></fieldset>
  <fieldset x-show="step === 2"><legend>Email</legend><input type="email" x-model="form.email" required></fieldset>
  <fieldset x-show="step === 3"><legend>Plan</legend>
    <select x-model="form.plan"><option value="free">Free</option><option value="pro">Pro</option></select>
  </fieldset>

  <button type="button" @click="back()" x-show="step > 1">Back</button>
  <button type="button" @click="next()" x-show="step < total" :disabled="!canProceed">Next</button>
  <button type="submit" x-show="step === total">Submit</button>
</form>
```

Hidden steps still submit their fields because `x-show` keeps them in the DOM. If the final submit should go through htmx, replace `@submit.prevent` with `hx-post`.

---

## Clipboard copy

```html
<div x-data="{ copied: false }">
  <code x-ref="code">npm install alpinejs</code>
  <button type="button"
          @click="await navigator.clipboard.writeText($refs.code.textContent); copied = true; setTimeout(() => copied = false, 2000)"
          :aria-label="copied ? 'Copied' : 'Copy to clipboard'">
    <span x-text="copied ? 'Copied!' : 'Copy'" aria-live="polite"></span>
  </button>
</div>
```

---

## Custom input with x-modelable

A reusable quantity stepper whose value binds to the parent's `x-model`.

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('stepper', (min = 0, max = 99) => ({
    value: min,
    dec() { if (this.value > min) this.value-- },
    inc() { if (this.value < max) this.value++ },
  }))
})
</script>

<div x-data="{ qty: 1 }">
  <div x-data="stepper(1, 10)" x-modelable="value" x-model="qty" role="group" aria-label="Quantity">
    <button type="button" @click="dec()" aria-label="Decrease">−</button>
    <output x-text="value"></output>
    <button type="button" @click="inc()" aria-label="Increase">+</button>
  </div>
  <input type="hidden" name="qty" :value="qty">   <!-- so a plain or htmx form submits it -->
</div>
```

---

## Sortable list

Requires `@alpinejs/sort`.

```html
<ul x-data="{ todos: [...], reorder(id, position) { /* persist, e.g. htmx.ajax('POST', '/reorder', { values: { id, position } }) */ } }"
    x-sort="reorder($item, $position)">
  <template x-for="todo in todos" :key="todo.id">
    <li x-sort:item="todo.id">
      <span x-sort:handle aria-hidden="true">⋮⋮</span>
      <span x-text="todo.title"></span>
    </li>
  </template>
</ul>
```

Provide a keyboard alternative (move up/down buttons) for users who cannot drag.

---

## Reusable component with Alpine.data

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('counter', (initial = 0) => ({
    count: initial,
    increment() { this.count++ },
    decrement() { this.count-- },
    reset() { this.count = initial },
    init() { this.$watch('count', (v, old) => console.debug('count', old, '→', v)) },
  }))
})
</script>

<div x-data="counter()">
  <button type="button" @click="decrement()" aria-label="Decrease">−</button>
  <output x-text="count"></output>
  <button type="button" @click="increment()" aria-label="Increase">+</button>
</div>
<div x-data="counter(100)">…</div>
```
