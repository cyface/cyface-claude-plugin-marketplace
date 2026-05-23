---
name: htmx
description: >-
  This skill should be used when the user asks to "add HTMX", "make an AJAX request",
  "add hx-get", "add hx-post", "swap content", "add auto-refresh", "add polling",
  "submit form with HTMX", "add sorting with HTMX", "use hx-trigger",
  "add partial page updates", "use hx-swap", "add loading indicator",
  "boost links", "use server-sent events with HTMX", "add infinite scroll",
  "replace page content without reload", "add websocket support",
  or mentions HTMX attributes (hx-get, hx-post, hx-put, hx-delete, hx-target,
  hx-swap, hx-trigger, hx-vals, hx-indicator, hx-push-url, hx-boost, hx-confirm,
  hx-ext, hx-on, hx-select, hx-headers, hx-sync, hx-encoding).
  Also applies when building server-driven UIs or working with HTMX alongside Alpine.js.
version: 1.0.0
---

# HTMX Development Guide

HTMX extends HTML with attributes that enable AJAX requests, CSS transitions, WebSockets, and Server-Sent Events directly in markup. It handles **data operations** — fetching content, form submissions, sorting, filtering, polling, and partial page updates.

## Core Philosophy

HTMX returns HTML from the server, not JSON. The server renders HTML fragments and HTMX swaps them into the page. This means:
- Server controls rendering logic (templates, formatting, localization)
- No client-side rendering framework needed
- Progressive enhancement — pages work without JavaScript
- Smaller client-side footprint

## Quick Reference

The essential HTMX workflow: **request** an endpoint, **target** where to place the response, **swap** how to insert it, and **trigger** when it fires.

```html
<button hx-get="/api/data"
        hx-target="#results"
        hx-swap="innerHTML"
        hx-trigger="click"
        hx-indicator="#spinner">
    Load Data
</button>
<span id="spinner" class="htmx-indicator">Loading...</span>
<div id="results"></div>
```

### Request Attributes

`hx-get`, `hx-post`, `hx-put`, `hx-patch`, `hx-delete` — issue HTTP requests from any element. Default triggers: `click` for most elements, `change` for inputs, `submit` for forms.

### Targeting (hx-target)

CSS selector for where to place the response. Supports `#id`, `.class`, `this`, and relative selectors (`closest tr`, `find .child`, `next`, `previous`). Inherited by child elements.

### Swapping (hx-swap)

How content is inserted: `innerHTML` (default), `outerHTML`, `afterbegin`, `beforeend`, `beforebegin`, `afterend`, `delete`, `none`. Supports modifiers for timing (`swap:300ms`, `settle:500ms`), scrolling (`scroll:top`), and transitions (`transition:true`).

### Triggers (hx-trigger)

When requests fire. Standard events (`click`, `change`, `submit`), polling (`every 5s`), load (`load`), intersection (`intersect once`), and custom events. Modifiers: `changed`, `once`, `delay:500ms`, `throttle:1s`, `from:document`, `queue:last`. Filter expressions: `keyup[key=='Enter']`, `click[ctrlKey]`.

```html
<!-- Common trigger patterns -->
<input hx-get="/search" hx-trigger="keyup changed delay:300ms" hx-target="#results">
<input hx-post="/save" hx-trigger="blur changed, keyup[key=='Enter']" hx-swap="none">
<div hx-get="/status" hx-trigger="every 5s">
```

### Synchronization (hx-sync)

Control concurrent requests from an element: `drop` (ignore new while in-flight), `abort` (cancel current, issue new), `replace`, `queue`. Essential for search inputs.

```html
<input hx-get="/search" hx-trigger="keyup changed delay:300ms"
       hx-sync="this:abort" hx-target="#results">
```

For complete attribute syntax, all modifiers, and edge cases, consult **`references/htmx-attributes.md`**.

## Sending Data

### hx-vals — Add extra values

```html
<!-- Static JSON -->
<button hx-post="/api" hx-vals='{"type": "archive"}'>Archive</button>

<!-- Dynamic via JavaScript (prefix with js:) -->
<input hx-post="/api/save" hx-vals='js:{guid: event.target.dataset.guid, value: event.target.value}'>

<!-- Dynamic via Alpine.js (use :hx-vals binding) -->
<button hx-post="/api" :hx-vals="JSON.stringify({ id: currentId })">
```

### Other data attributes

- **`hx-include`** — Include values from other elements: `hx-include="#search"`, `hx-include="closest form"`
- **`hx-params`** — Control which parameters: `*` (all), `none`, `name, email` (only), `not password` (exclude)
- **`hx-headers`** — Custom headers: `hx-headers='js:{"X-Timezone": Intl.DateTimeFormat().resolvedOptions().timeZone}'`
- **`hx-encoding`** — Set to `multipart/form-data` for file uploads

## UX Essentials

- **`hx-indicator`** — Show element during request. Uses `.htmx-indicator` CSS class (auto-included by HTMX).
- **`hx-confirm`** — Browser confirmation dialog before request: `hx-confirm="Delete this item?"`
- **`hx-disabled-elt`** — Disable elements during request: `hx-disabled-elt="this"` or `hx-disabled-elt="find button"`
- **`hx-push-url`** — Update browser URL: `hx-push-url="true"` or `hx-push-url="/custom/path"`
- **`hx-replace-url`** — Replace URL without history entry
- **`hx-boost`** — Progressively enhance links/forms to use AJAX. Set on a parent to boost all children. Targets `<body>` by default.

## Events and Alpine.js Integration

HTMX fires events throughout the request lifecycle. The most useful for Alpine.js integration:

| Event | When |
|-------|------|
| `htmx:beforeRequest` | Before request is sent |
| `htmx:afterRequest` | After request completes (check `$event.detail.successful`) |
| `htmx:beforeSwap` | Before content is swapped |
| `htmx:afterSwap` | After content is swapped into DOM |
| `htmx:afterSettle` | After settling (animations complete) |
| `htmx:responseError` | On HTTP error response |
| `htmx:configRequest` | Configure headers/params before sending |

### Listening with Alpine.js

**Critical:** Use kebab-case for HTMX events in Alpine listeners (`htmx:after-request`, not `htmx:afterRequest`).

```html
<!-- Loading state via Alpine -->
<button hx-post="/api/save"
        @htmx:before-request="$el.disabled = true; $el.textContent = 'Saving...'"
        @htmx:after-request="$el.disabled = false; $el.textContent = 'Save'"
        @htmx:response-error="$store.toasts.add('Save failed', 'error')">
    Save
</button>

<!-- Close modal on success -->
<form hx-post="/api/create"
      @htmx:after-request="if($event.detail.successful) closeModal()">

<!-- Dynamic hx-vals from Alpine state -->
<button hx-post="/api/action"
        :hx-vals="JSON.stringify({ guid: currentGuid })">
```

### Global event configuration

```javascript
document.body.addEventListener('htmx:configRequest', (event) => {
    event.detail.headers['X-Timezone'] = Intl.DateTimeFormat().resolvedOptions().timeZone
    event.detail.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]')?.content
})
```

## Out-of-Band Swaps (OOB)

Update multiple elements from a single response. The server includes extra elements with `hx-swap-oob`:

```html
<!-- Server response -->
<div id="main-content">Updated main content</div>
<div id="notification-count" hx-swap-oob="true">3</div>
<div id="sidebar" hx-swap-oob="innerHTML">Updated sidebar</div>
```

Powerful for updating counters, notifications, or related content after an action without additional requests.

## HTMX + Alpine.js Responsibility Split

**Principle:** Alpine handles UI state (open/close, visibility, client-side logic). HTMX handles server communication (data fetching, form submission, content updates).

| Task | Use |
|------|-----|
| Toggle modal/dropdown | Alpine `x-show` |
| Submit form to server | HTMX `hx-post` |
| Show/hide edit mode | Alpine `x-data` |
| Save edited content | HTMX `hx-post` |
| Loading spinner state | Alpine `@htmx:before-request` |
| Refresh table data | HTMX `hx-get` |
| Client-side filter | Alpine `x-for` with getter |
| Server-side filter | HTMX `hx-get` with params |
| Optimistic UI update | Alpine state + HTMX request + revert on error |
| URL-driven navigation | HTMX `hx-push-url` |

**Key integration patterns:**
- Alpine state survives across HTMX swaps only if the `x-data` element is NOT the swap target. Place Alpine scope on a parent above the HTMX target.
- Use `@htmx:after-request` with `$event.detail.successful` to coordinate Alpine state changes after server responses.
- Bridge Alpine data into HTMX requests with `:hx-vals="JSON.stringify({...})"`.

## Security

- **CSRF protection:** HTMX includes cookies automatically. Add CSRF tokens via `hx-headers` or `htmx:configRequest` event.
- **XSS:** Server must escape user content in HTML responses. Never trust client-side escaping alone.
- **Content types:** HTMX expects HTML responses, not JSON. Use Alpine or extensions for JSON processing.
- **Sensitive data:** Avoid putting secrets in `hx-vals` — they are visible in the DOM.

## Additional Resources

### Reference Files
- **`references/htmx-attributes.md`** — Complete attribute reference with all options, modifiers, synchronization strategies, extensions, and edge cases
- **`references/htmx-patterns.md`** — Common server-driven UI patterns: active search, inline editing, infinite scroll, sortable tables, bulk operations, cascading selects, polling, optimistic UI, file uploads, and more
