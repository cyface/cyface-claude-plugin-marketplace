# Alpine.js v3 — Complete Directive Reference

## x-data

Initialize a reactive component scope.

```html
<!-- Object literal -->
<div x-data="{ open: false, items: [], count: 0 }">

<!-- With methods and getters -->
<div x-data="{
    count: 0,
    increment() { this.count++ },
    get doubled() { return this.count * 2 }
}">

<!-- Data-less (for simple $dispatch, $refs, etc.) -->
<button x-data @click="alert('clicked')">Click</button>

<!-- Nested scopes (child accesses parent) -->
<div x-data="{ name: 'John' }">
    <div x-data="{ greeting: 'Hello' }">
        <span x-text="greeting + ' ' + name"></span>
    </div>
</div>

<!-- Reusable component via Alpine.data() -->
<script>
document.addEventListener('alpine:init', () => {
    Alpine.data('dropdown', () => ({
        open: false,
        toggle() { this.open = !this.open },
        close() { this.open = false }
    }))
})
</script>
<div x-data="dropdown">...</div>
```

**Reactivity details:**
- Properties are deeply reactive (nested objects/arrays tracked automatically)
- Getters (`get prop()`) recompute when dependencies change
- `init()` method runs automatically when component initializes
- `destroy()` method runs when component is removed from DOM

---

## x-bind / : (shorthand)

Dynamically set any HTML attribute.

```html
<!-- Basic attribute binding -->
<img :src="imageUrl" :alt="imageAlt">
<input :type="inputType" :disabled="isDisabled" :placeholder="hint">
<a :href="url" :target="openInNew ? '_blank' : null">

<!-- Class binding — object syntax -->
<div :class="{ 'active': isActive, 'bg-red': hasError, 'hidden': !visible }">

<!-- Class binding — array syntax -->
<div :class="[baseClass, isActive ? 'active' : '', errorClass]">

<!-- Style binding — object syntax -->
<div :style="{ color: textColor, fontSize: size + 'px', display: show ? 'block' : 'none' }">

<!-- Bind multiple attributes at once -->
<div x-bind="{ id: 'item-' + itemId, 'data-active': isActive, class: 'base ' + extraClass }">
```

**Special class behavior:** When binding `:class`, Alpine **merges** with existing static `class` attribute rather than replacing it.

**Removing attributes:** Bind to `null` or `false` to remove the attribute entirely: `:disabled="false"` removes the disabled attribute.

---

## x-on / @ (shorthand)

Attach event listeners.

```html
<!-- Basic events -->
<button @click="count++">Increment</button>
<button @click="handleClick($event)">With event object</button>
<form @submit.prevent="save()">

<!-- Inline multi-statement -->
<button @click="open = true; $nextTick(() => $refs.input.focus())">Open</button>

<!-- Keyboard events -->
<input @keyup.enter="submit()"
       @keyup.escape="cancel()"
       @keydown.arrow-down="selectNext()"
       @keydown.shift.tab="focusPrevious()">

<!-- Mouse events -->
<div @mouseenter="hovering = true" @mouseleave="hovering = false">
<div @contextmenu.prevent="showMenu($event)">
```

### All Event Modifiers

| Modifier | Description |
|----------|-------------|
| `.prevent` | Calls `preventDefault()` |
| `.stop` | Calls `stopPropagation()` |
| `.outside` | Only fires if click originates outside the element |
| `.window` | Registers listener on `window` instead of element |
| `.document` | Registers listener on `document` |
| `.once` | Handler fires at most once then auto-removes |
| `.debounce` | Debounce handler (default 250ms) |
| `.debounce.500ms` | Debounce with custom timing |
| `.throttle` | Throttle handler (default 250ms) |
| `.throttle.100ms` | Throttle with custom timing |
| `.self` | Only fires if `event.target` is the element itself |
| `.passive` | Adds passive flag (for scroll performance) |
| `.capture` | Adds capture flag |

### Keyboard Modifiers

`.enter`, `.escape`, `.space`, `.tab`, `.arrow-up`, `.arrow-down`, `.arrow-left`, `.arrow-right`, `.shift`, `.ctrl`, `.alt`, `.meta`, `.caps-lock`

**Combine modifiers:** `@keydown.ctrl.enter="submit()"`, `@click.prevent.stop="handle()"`

---

## x-model

Two-way data binding for form elements.

```html
<!-- Text input -->
<input type="text" x-model="name">

<!-- Textarea -->
<textarea x-model="bio"></textarea>

<!-- Checkbox → boolean -->
<input type="checkbox" x-model="agreed">

<!-- Checkbox group → array -->
<input type="checkbox" value="red" x-model="colors">
<input type="checkbox" value="blue" x-model="colors">

<!-- Radio → string value -->
<input type="radio" value="small" x-model="size">
<input type="radio" value="large" x-model="size">

<!-- Select → string -->
<select x-model="country">
    <option value="">Choose...</option>
    <option value="us">USA</option>
</select>

<!-- Multi-select → array -->
<select x-model="selected" multiple>
    <option value="a">A</option>
    <option value="b">B</option>
</select>

<!-- Range -->
<input type="range" x-model="volume" min="0" max="100">
```

### x-model Modifiers

| Modifier | Effect |
|----------|--------|
| `.lazy` | Sync on `change` instead of `input` (useful for text fields) |
| `.number` | Cast value to number |
| `.trim` | Trim whitespace |
| `.debounce` | Debounce sync (default 250ms) |
| `.debounce.500ms` | Debounce with custom timing |
| `.fill` | Fill input with current data value on init (for pre-existing values) |

---

## x-show

Toggle visibility via CSS display property. Element remains in DOM.

```html
<div x-show="isVisible">Always in DOM, toggled via display</div>

<!-- With transition -->
<div x-show="open" x-transition>Fade + scale default</div>

<!-- With custom transition -->
<div x-show="open"
     x-transition:enter="transition ease-out duration-300"
     x-transition:enter-start="opacity-0 -translate-y-2"
     x-transition:enter-end="opacity-100 translate-y-0"
     x-transition:leave="transition ease-in duration-200"
     x-transition:leave-start="opacity-100"
     x-transition:leave-end="opacity-0">
```

**x-show vs x-if:** Use `x-show` for frequent toggling (cheaper, no DOM removal). Use `x-if` when element should not exist (SEO, memory, or conditional initialization).

---

## x-if

Conditionally add/remove elements from DOM.

```html
<!-- Must wrap a <template> tag -->
<template x-if="showAdvanced">
    <div class="advanced-options">
        <!-- Only one root element allowed inside template -->
    </div>
</template>
```

**Rules:**
- Must be used on a `<template>` element
- Template must contain exactly one root element
- No `x-transition` support (use `x-show` if transitions needed)
- Element is fully removed from DOM when false

---

## x-for

Iterate over arrays.

```html
<!-- Basic iteration -->
<template x-for="item in items" :key="item.id">
    <div x-text="item.name"></div>
</template>

<!-- With index -->
<template x-for="(item, index) in items" :key="item.id">
    <div>
        <span x-text="index + 1"></span>: <span x-text="item.name"></span>
    </div>
</template>

<!-- Range (1 to n) -->
<template x-for="i in 10">
    <span x-text="i"></span>
</template>

<!-- Nested loops -->
<template x-for="group in groups" :key="group.id">
    <div>
        <h3 x-text="group.name"></h3>
        <template x-for="item in group.items" :key="item.id">
            <p x-text="item.label"></p>
        </template>
    </div>
</template>
```

**Rules:**
- Must be on a `<template>` element with exactly one root child
- Always provide `:key` for efficient updates (use unique identifier, not index)
- Supports arrays and integer ranges

---

## x-text and x-html

```html
<!-- x-text: sets textContent (auto-escapes HTML — safe) -->
<span x-text="message"></span>
<span x-text="count + ' items'"></span>
<span x-text="items.length > 0 ? items.length + ' results' : 'No results'"></span>

<!-- x-html: sets innerHTML (DANGEROUS with user content) -->
<div x-html="richContent"></div>
```

**Security:** Always prefer `x-text` for user-provided content. Only use `x-html` for trusted, sanitized HTML.

---

## x-transition

Animate elements during show/hide.

```html
<!-- Default transition (opacity + scale) -->
<div x-show="open" x-transition>

<!-- Duration/delay modifiers -->
<div x-show="open" x-transition.duration.500ms>
<div x-show="open" x-transition.delay.100ms>
<div x-show="open" x-transition.opacity> <!-- Opacity only, no scale -->
<div x-show="open" x-transition.scale.80> <!-- Custom scale origin -->

<!-- CSS class-based (full control) -->
<div x-show="open"
     x-transition:enter="transition ease-out duration-300"
     x-transition:enter-start="opacity-0 translate-y-4"
     x-transition:enter-end="opacity-100 translate-y-0"
     x-transition:leave="transition ease-in duration-200"
     x-transition:leave-start="opacity-100 translate-y-0"
     x-transition:leave-end="opacity-0 -translate-y-4">
```

**Transition classes applied in sequence:**
1. `enter` / `leave` — Applied for entire duration
2. `enter-start` / `leave-start` — Applied on first frame, removed on next
3. `enter-end` / `leave-end` — Applied on second frame, removed when transition finishes

---

## x-init

Run code when component initializes.

```html
<!-- Inline expression -->
<div x-data="{ posts: [] }" x-init="posts = await (await fetch('/api/posts')).json()">

<!-- Method call -->
<div x-data="{ init() { console.log('Component ready') } }">
<!-- init() is called automatically — x-init not needed if using init() method -->
```

**Note:** If an `x-data` object has an `init()` method, it runs automatically without needing `x-init`.

---

## x-effect

Run reactive side effects. Auto-tracks dependencies.

```html
<div x-data="{ count: 0 }"
     x-effect="console.log('Count changed to:', count)">
    <button @click="count++">Increment</button>
</div>

<!-- Practical: sync to localStorage -->
<div x-data="{ theme: 'light' }"
     x-effect="localStorage.setItem('theme', theme); document.body.className = theme">
```

**Like Vue's watchEffect:** Runs immediately, then re-runs whenever any reactive dependency changes.

---

## x-ref

Name an element for programmatic access.

```html
<div x-data>
    <input x-ref="searchInput" type="text">
    <button @click="$refs.searchInput.focus()">Focus Search</button>
</div>
```

---

## x-cloak

Hide element until Alpine initializes (prevents flash of uninitialized content).

```html
<!-- Required CSS -->
<style>[x-cloak] { display: none !important; }</style>

<!-- Usage -->
<div x-data="{ loaded: false }" x-cloak>
    <span x-show="loaded">Ready</span>
</div>
```

---

## x-teleport

Move element rendering to another part of the DOM.

```html
<!-- Teleport modal to body to escape z-index/overflow issues -->
<div x-data="{ open: false }">
    <button @click="open = true">Open Modal</button>

    <template x-teleport="body">
        <div x-show="open" class="modal-overlay">
            <div class="modal-content">
                Modal content here
            </div>
        </div>
    </template>
</div>
```

**Rules:** Must be on a `<template>` element. Target is a CSS selector. Teleported content maintains reactivity with its original scope.

---

## x-ignore

Prevent Alpine from initializing a subtree.

```html
<div x-data>
    <div x-ignore>
        <!-- Alpine will not process anything here -->
        <span x-text="this won't work"></span>
    </div>
</div>
```

---

## x-id

Generate unique IDs for accessibility patterns.

```html
<div x-id="['dropdown']">
    <button :aria-controls="$id('dropdown')">Toggle</button>
    <div :id="$id('dropdown')">Dropdown content</div>
</div>
```

Generates unique IDs like `dropdown-1`, `dropdown-2` etc. for reusable components.
