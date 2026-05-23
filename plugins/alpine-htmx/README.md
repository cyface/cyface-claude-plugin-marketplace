# alpine-htmx

A Claude Code plugin providing expert guidance for **Alpine.js v3** and **HTMX** development — the lightweight, hypermedia-driven frontend stack.

## What's Included

### Skills

| Skill | Triggers On | What It Provides |
|-------|-------------|------------------|
| **Alpine.js Development** | Alpine directives, reactivity, stores, components | Directive reference, patterns (modals, dropdowns, tabs, forms), plugins, accessibility |
| **HTMX Development** | HTMX attributes, AJAX, swapping, triggers, polling | Attribute reference, patterns (search, inline edit, infinite scroll, bulk ops, polling) |

Both skills include **Alpine + HTMX integration patterns** for combined usage.

### Agent

| Agent | Triggers | What It Does |
|-------|----------|--------------|
| **alpine-htmx-reviewer** | Proactively after writing Alpine/HTMX code | Reviews for anti-patterns, accessibility issues, security vulnerabilities, and framework misuse |

## Installation

```bash
# From the Claude Code marketplace (recommended)
/install alpine-htmx

# Or install directly from GitHub
claude plugin add --git https://github.com/cyface/alpine-htmx-claude-plugin.git
```

## Skills Detail

### Alpine.js Development

Covers Alpine.js v3 essentials:
- All directives (`x-data`, `x-bind`, `x-on`, `x-show`, `x-for`, `x-if`, `x-model`, `x-transition`, `x-ref`, `x-cloak`, `x-teleport`, `x-effect`, `x-init`, `x-html`, `x-text`, `x-ignore`, `x-id`)
- Event modifiers (`.prevent`, `.stop`, `.outside`, `.window`, `.debounce`, `.throttle`, etc.)
- Magic properties (`$store`, `$refs`, `$dispatch`, `$watch`, `$nextTick`, `$el`, `$root`, `$id`)
- Global state with `Alpine.store()` and `Alpine.data()`
- Official plugins: Focus, Collapse, Intersect, Persist, Mask, Morph, Sort
- Component patterns: modals, dropdowns, tabs, accordions, toasts, search/filter, wizards, dark mode

### HTMX Development

Covers HTMX 2.x essentials:
- Request attributes (`hx-get`, `hx-post`, `hx-put`, `hx-patch`, `hx-delete`)
- Targeting (`hx-target` with CSS and relative selectors)
- Swap modes (`innerHTML`, `outerHTML`, `beforeend`, `afterbegin`, `delete`, `none`) and modifiers
- Trigger syntax (`hx-trigger` events, modifiers, filters, polling)
- Data sending (`hx-vals`, `hx-include`, `hx-params`, `hx-headers`)
- UX features (`hx-indicator`, `hx-confirm`, `hx-disabled-elt`, `hx-push-url`, `hx-boost`)
- Events lifecycle and Alpine.js integration
- Out-of-band swaps, synchronization, extensions
- Patterns: active search, inline editing, infinite scroll, sortable tables, bulk operations, polling, optimistic UI

### Code Reviewer Agent

Automatically checks for:
- **Anti-patterns**: Missing `x-cloak`, incorrect `x-for`/`x-if` usage, missing `:key`, double-submit
- **Accessibility**: Missing ARIA attributes, focus traps, keyboard handlers, live regions
- **Security**: XSS via `x-html`, unescaped user content, missing CSRF tokens
- **Integration**: Incorrect event casing, lost Alpine state on HTMX swaps

## File Structure

```
alpine-htmx/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── alpine-js/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── alpine-directives.md
│   │       └── alpine-patterns.md
│   └── htmx/
│       ├── SKILL.md
│       └── references/
│           ├── htmx-attributes.md
│           └── htmx-patterns.md
├── agents/
│   └── alpine-htmx-reviewer.md
└── README.md
```

## Framework Versions

- **Alpine.js**: v3.x (current stable)
- **HTMX**: v2.x (current stable)

## License

MIT
