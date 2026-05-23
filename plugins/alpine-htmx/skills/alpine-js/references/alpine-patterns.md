# Alpine.js — Common Component Patterns

## Modal Dialog (Accessible)

```html
<div x-data="{ open: false }">
    <button @click="open = true" x-ref="trigger">Open Modal</button>

    <div x-show="open"
         x-cloak
         role="dialog"
         aria-labelledby="modal-title"
         aria-modal="true"
         @keydown.escape.window="open = false; $refs.trigger.focus()"
         @click="open = false; $refs.trigger.focus()"
         x-transition:enter="transition ease-out duration-300"
         x-transition:enter-start="opacity-0"
         x-transition:enter-end="opacity-100"
         x-transition:leave="transition ease-in duration-200"
         x-transition:leave-start="opacity-100"
         x-transition:leave-end="opacity-0"
         class="modal-overlay">

        <div class="modal-backdrop" aria-hidden="true"></div>

        <div class="modal-content"
             x-trap.inert.noscroll="open"
             @click.stop
             x-transition:enter="transition ease-out duration-300"
             x-transition:enter-start="opacity-0 scale-90"
             x-transition:enter-end="opacity-100 scale-100"
             x-transition:leave="transition ease-in duration-200"
             x-transition:leave-start="opacity-100 scale-100"
             x-transition:leave-end="opacity-0 scale-90">
            <h2 id="modal-title">Modal Title</h2>
            <p>Modal body content.</p>
            <button @click="open = false; $refs.trigger.focus()">Close</button>
        </div>
    </div>
</div>
```

**Key points:**
- `x-trap.inert.noscroll` requires **@alpinejs/focus** plugin
- `@click.stop` on content prevents closing when clicking inside
- `$refs.trigger.focus()` returns focus to trigger button on close
- `aria-labelledby` points to the modal title
- Backdrop with `aria-hidden="true"` for screen readers

---

## Dropdown Menu

```html
<div x-data="{ open: false }" class="relative">
    <button @click="open = !open"
            :aria-expanded="open"
            aria-haspopup="true">
        Options
    </button>

    <div x-show="open"
         x-cloak
         @click.outside="open = false"
         @keydown.escape.window="open = false"
         x-transition
         role="menu"
         class="dropdown-menu">
        <a href="#" role="menuitem" @click="open = false">Edit</a>
        <a href="#" role="menuitem" @click="open = false">Delete</a>
    </div>
</div>
```

---

## Tabs

```html
<div x-data="{ activeTab: 'general' }">
    <div role="tablist">
        <button role="tab"
                :aria-selected="activeTab === 'general'"
                :class="{ 'active': activeTab === 'general' }"
                @click="activeTab = 'general'">
            General
        </button>
        <button role="tab"
                :aria-selected="activeTab === 'advanced'"
                :class="{ 'active': activeTab === 'advanced' }"
                @click="activeTab = 'advanced'">
            Advanced
        </button>
    </div>

    <div x-show="activeTab === 'general'" role="tabpanel">
        General settings content
    </div>
    <div x-show="activeTab === 'advanced'" role="tabpanel">
        Advanced settings content
    </div>
</div>
```

---

## Accordion / Collapsible Sections

```html
<!-- Requires @alpinejs/collapse plugin -->
<div x-data="{ openSection: null }">
    <div>
        <button @click="openSection = openSection === 'faq1' ? null : 'faq1'"
                :aria-expanded="openSection === 'faq1'">
            Question 1
        </button>
        <div x-show="openSection === 'faq1'" x-collapse>
            Answer 1 content.
        </div>
    </div>
    <div>
        <button @click="openSection = openSection === 'faq2' ? null : 'faq2'"
                :aria-expanded="openSection === 'faq2'">
            Question 2
        </button>
        <div x-show="openSection === 'faq2'" x-collapse>
            Answer 2 content.
        </div>
    </div>
</div>
```

---

## Toast / Notification System

```html
<script>
document.addEventListener('alpine:init', () => {
    Alpine.store('toasts', {
        items: [],
        add(message, type = 'info') {
            const id = Date.now()
            this.items.push({ id, message, type })
            setTimeout(() => this.remove(id), 5000)
        },
        remove(id) {
            this.items = this.items.filter(t => t.id !== id)
        }
    })
})
</script>

<!-- Toast container (place once in layout) -->
<div x-data class="toast-container" aria-live="polite">
    <template x-for="toast in $store.toasts.items" :key="toast.id">
        <div :class="'toast toast-' + toast.type"
             x-transition
             role="alert">
            <span x-text="toast.message"></span>
            <button @click="$store.toasts.remove(toast.id)"
                    aria-label="Dismiss">&times;</button>
        </div>
    </template>
</div>

<!-- Trigger from anywhere -->
<button x-data @click="$store.toasts.add('Saved!', 'success')">Save</button>
```

---

## Search / Filter List

```html
<div x-data="{
    search: '',
    items: ['Apple', 'Banana', 'Cherry', 'Date', 'Fig', 'Grape'],
    get filtered() {
        if (!this.search) return this.items
        const q = this.search.toLowerCase()
        return this.items.filter(i => i.toLowerCase().includes(q))
    }
}">
    <input type="search" x-model.debounce.300ms="search" placeholder="Search...">

    <ul>
        <template x-for="item in filtered" :key="item">
            <li x-text="item"></li>
        </template>
    </ul>

    <p x-show="filtered.length === 0">No results found.</p>
</div>
```

---

## Toggle / Switch Button

```html
<button x-data="{ on: false }"
        @click="on = !on"
        :class="{ 'bg-green': on, 'bg-gray': !on }"
        :aria-pressed="on"
        role="switch"
        type="button">
    <span :class="on ? 'translate-x-5' : 'translate-x-0'"
          class="toggle-handle"></span>
</button>
```

---

## Confirm Before Action

```html
<div x-data="{ confirming: false }">
    <button x-show="!confirming" @click="confirming = true" class="btn-danger">
        Delete
    </button>
    <div x-show="confirming" x-transition class="confirm-group">
        <span>Are you sure?</span>
        <button @click="deleteItem(); confirming = false" class="btn-danger">Yes, Delete</button>
        <button @click="confirming = false" class="btn-secondary">Cancel</button>
    </div>
</div>
```

---

## Lazy-Loaded Content with Intersection Observer

```html
<!-- Requires @alpinejs/intersect plugin -->
<div x-data="{ loaded: false, content: '' }"
     x-intersect:enter.once="loaded = true; content = await (await fetch('/api/content')).json()">
    <template x-if="!loaded">
        <div class="skeleton-loader">Loading...</div>
    </template>
    <template x-if="loaded">
        <div x-html="content"></div>
    </template>
</div>
```

---

## Dark Mode Toggle with Persistence

```html
<!-- Requires @alpinejs/persist plugin -->
<script>
document.addEventListener('alpine:init', () => {
    Alpine.store('darkMode', {
        on: Alpine.$persist(false).as('darkMode'),
        toggle() { this.on = !this.on }
    })
})
</script>

<div :class="{ 'dark': $store.darkMode.on }">
    <button x-data @click="$store.darkMode.toggle()"
            :aria-pressed="$store.darkMode.on">
        <span x-text="$store.darkMode.on ? 'Light Mode' : 'Dark Mode'"></span>
    </button>
</div>
```

---

## Character Counter for Textarea

```html
<div x-data="{ text: '', maxLength: 280 }">
    <textarea x-model="text"
              :maxlength="maxLength"
              placeholder="What's happening?"></textarea>
    <div :class="{ 'text-red': text.length > maxLength * 0.9 }">
        <span x-text="text.length"></span>/<span x-text="maxLength"></span>
    </div>
</div>
```

---

## Multi-Step Form / Wizard

```html
<div x-data="{
    step: 1,
    totalSteps: 3,
    formData: { name: '', email: '', plan: '' },
    get canProceed() {
        if (this.step === 1) return this.formData.name.length > 0
        if (this.step === 2) return this.formData.email.includes('@')
        return true
    }
}">
    <!-- Step indicators -->
    <div class="steps">
        <template x-for="i in totalSteps" :key="i">
            <span :class="{ 'active': step === i, 'done': step > i }" x-text="i"></span>
        </template>
    </div>

    <!-- Step 1 -->
    <div x-show="step === 1">
        <label>Name</label>
        <input x-model="formData.name" type="text">
    </div>

    <!-- Step 2 -->
    <div x-show="step === 2">
        <label>Email</label>
        <input x-model="formData.email" type="email">
    </div>

    <!-- Step 3 -->
    <div x-show="step === 3">
        <label>Plan</label>
        <select x-model="formData.plan">
            <option value="free">Free</option>
            <option value="pro">Pro</option>
        </select>
    </div>

    <!-- Navigation -->
    <button @click="step--" x-show="step > 1">Back</button>
    <button @click="step++" x-show="step < totalSteps" :disabled="!canProceed">Next</button>
    <button x-show="step === totalSteps" @click="submitForm()">Submit</button>
</div>
```

---

## Clipboard Copy Button

```html
<div x-data="{ copied: false }">
    <code x-ref="code">npm install alpinejs</code>
    <button @click="
        navigator.clipboard.writeText($refs.code.textContent);
        copied = true;
        setTimeout(() => copied = false, 2000)
    ">
        <span x-text="copied ? 'Copied!' : 'Copy'"></span>
    </button>
</div>
```

---

## Reusable Component with Alpine.data()

```html
<script>
document.addEventListener('alpine:init', () => {
    Alpine.data('counter', (initialCount = 0) => ({
        count: initialCount,
        increment() { this.count++ },
        decrement() { this.count-- },
        reset() { this.count = initialCount }
    }))
})
</script>

<!-- Reuse with different initial values -->
<div x-data="counter(0)">
    <button @click="decrement">-</button>
    <span x-text="count"></span>
    <button @click="increment">+</button>
</div>

<div x-data="counter(100)">
    <button @click="decrement">-</button>
    <span x-text="count"></span>
    <button @click="increment">+</button>
</div>
```
