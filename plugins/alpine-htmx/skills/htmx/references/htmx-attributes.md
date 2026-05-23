# HTMX — Complete Attribute Reference

## Request Attributes

### hx-get / hx-post / hx-put / hx-patch / hx-delete

Issue an HTTP request to the given URL.

```html
<button hx-get="/api/items">Load</button>
<form hx-post="/api/items">
    <input name="name" required>
    <button type="submit">Create</button>
</form>
<button hx-put="/api/items/5" hx-vals='{"name": "Updated"}'>Update</button>
<button hx-patch="/api/items/5" hx-vals='{"status": "active"}'>Activate</button>
<button hx-delete="/api/items/5" hx-confirm="Delete this item?">Delete</button>
```

**Default triggers by element:**
- `<button>`, `<a>`, most elements: `click`
- `<input>`, `<select>`, `<textarea>`: `change`
- `<form>`: `submit`

**Form data:** Forms automatically include all input values. Other elements include their value if they have a `name` and `value` attribute.

---

## Targeting & Swapping

### hx-target

CSS selector for where to put the response.

```html
<!-- By ID -->
<button hx-get="/data" hx-target="#results">Load</button>

<!-- Self -->
<div hx-get="/data" hx-target="this">Refresh me</div>

<!-- Relative selectors -->
<button hx-get="/row" hx-target="closest tr">Refresh row</button>
<button hx-get="/cell" hx-target="find .content">Update child</button>
<button hx-get="/data" hx-target="next .output">Next sibling</button>
<button hx-get="/data" hx-target="previous .output">Previous sibling</button>
```

**Inheritance:** Placing `hx-target` on a parent applies to all child HTMX elements.

### hx-swap

How to insert the response content.

| Value | Description |
|-------|-------------|
| `innerHTML` | Replace children of target (default) |
| `outerHTML` | Replace entire target element |
| `afterbegin` | Prepend inside target |
| `beforeend` | Append inside target |
| `beforebegin` | Insert before target |
| `afterend` | Insert after target |
| `delete` | Remove the target |
| `none` | No swap (fire-and-forget, still processes OOB and headers) |

**Modifiers** (append with space):

```html
<!-- Timing -->
hx-swap="innerHTML swap:300ms"          <!-- delay before swap -->
hx-swap="innerHTML settle:500ms"        <!-- delay before settling -->

<!-- Scrolling -->
hx-swap="innerHTML scroll:top"          <!-- scroll target to top -->
hx-swap="innerHTML scroll:#list:bottom" <!-- scroll element to bottom -->
hx-swap="innerHTML show:top"            <!-- show target at top of viewport -->
hx-swap="innerHTML show:#el:bottom"     <!-- show element at bottom of viewport -->
hx-swap="innerHTML focus-scroll:false"  <!-- prevent focus-based scrolling -->

<!-- Transitions -->
hx-swap="innerHTML transition:true"     <!-- use View Transitions API -->

<!-- Ignore title -->
hx-swap="innerHTML ignoreTitle:true"    <!-- don't update document title -->
```

### hx-select

Pick specific content from the response:

```html
<!-- Only swap in the #results div from the full page response -->
<button hx-get="/page" hx-select="#results" hx-target="#results">Load</button>
```

### hx-select-oob

Select and out-of-band swap specific elements from the response:

```html
<button hx-get="/page" hx-select-oob="#notification-count">Load</button>
```

### hx-swap-oob

Server-side attribute for out-of-band swaps. Place on elements in the **response**:

```html
<!-- In server response HTML -->
<div id="main">Main content update</div>
<span id="count" hx-swap-oob="true">42</span>
<div id="sidebar" hx-swap-oob="innerHTML">New sidebar</div>
<div id="footer" hx-swap-oob="outerHTML">New footer</div>
```

---

## Triggering

### hx-trigger

Control when requests are issued.

**Standard events:**
```html
hx-trigger="click"                     <!-- default for most elements -->
hx-trigger="change"                    <!-- default for inputs -->
hx-trigger="submit"                    <!-- default for forms -->
hx-trigger="mouseenter"
hx-trigger="focus"
hx-trigger="blur"
hx-trigger="keyup"
```

**Special triggers:**
```html
hx-trigger="load"                      <!-- on page load -->
hx-trigger="revealed"                  <!-- when scrolled into view -->
hx-trigger="intersect"                 <!-- IntersectionObserver -->
hx-trigger="intersect threshold:0.5"   <!-- with threshold -->
hx-trigger="every 2s"                  <!-- polling -->
hx-trigger="every 5s [isActive]"       <!-- conditional polling -->
```

**Modifiers:**
```html
hx-trigger="click once"                <!-- fire once -->
hx-trigger="keyup changed"             <!-- only if value changed -->
hx-trigger="keyup changed delay:500ms" <!-- debounce -->
hx-trigger="scroll throttle:200ms"     <!-- throttle -->
hx-trigger="click consume"             <!-- don't propagate -->
hx-trigger="click queue:last"          <!-- queue: first, last, all, none -->
hx-trigger="click from:document"       <!-- listen on document -->
hx-trigger="click from:window"         <!-- listen on window -->
hx-trigger="click from:closest .parent"<!-- listen on ancestor -->
hx-trigger="click target:.child"       <!-- only from matching child -->
```

**Filter expressions:**
```html
hx-trigger="keyup[key=='Enter']"       <!-- only Enter key -->
hx-trigger="click[ctrlKey]"            <!-- only with Ctrl -->
hx-trigger="click[!ctrlKey]"           <!-- only without Ctrl -->
hx-trigger="keyup[key=='Enter' && !shiftKey]"
```

**Multiple triggers:**
```html
hx-trigger="blur changed, keyup[key=='Enter']"
hx-trigger="click, keyup[key==' ']"
```

---

## Data Sending

### hx-vals

Include additional values in the request.

```html
<!-- Static JSON -->
<button hx-post="/api" hx-vals='{"type": "draft", "priority": 1}'>Save Draft</button>

<!-- Dynamic JavaScript (prefix with js:) -->
<input hx-post="/api/save"
       hx-trigger="blur changed"
       hx-vals='js:{
           guid: event.target.dataset.guid,
           field: event.target.dataset.field,
           value: event.target.value.trim()
       }'>

<!-- With Alpine.js (use :hx-vals binding) -->
<button hx-post="/api"
        :hx-vals="JSON.stringify({ id: selectedId, action: currentAction })">
```

### hx-headers

Add custom headers to the request.

```html
<!-- Static -->
<div hx-get="/api" hx-headers='{"X-Custom": "value"}'>

<!-- Dynamic -->
<div hx-get="/api" hx-headers='js:{"X-Timezone": Intl.DateTimeFormat().resolvedOptions().timeZone}'>
```

### hx-include

Include values from other elements in the request.

```html
<input id="token" name="csrf" type="hidden" value="abc123">
<button hx-post="/save" hx-include="#token">Save</button>

<!-- Include all inputs in nearest form -->
<button hx-post="/save" hx-include="closest form">Save</button>

<!-- Include multiple -->
<button hx-post="/save" hx-include="#field1, #field2">Save</button>
```

### hx-params

Control which parameters from the element's form data are submitted.

```html
hx-params="*"                <!-- all (default) -->
hx-params="none"             <!-- none -->
hx-params="name, email"      <!-- only these -->
hx-params="not password"     <!-- everything except these -->
```

### hx-encoding

Set request encoding.

```html
<!-- For file uploads -->
<form hx-post="/upload" hx-encoding="multipart/form-data">
    <input type="file" name="document">
    <button type="submit">Upload</button>
</form>
```

---

## UX Attributes

### hx-indicator

Show a loading indicator during the request.

```html
<button hx-get="/data" hx-indicator="#loading">Load</button>
<div id="loading" class="htmx-indicator">Loading...</div>

<!-- Use closest parent as indicator -->
<button hx-get="/data" hx-indicator="closest .card">Load</button>
```

HTMX adds `htmx-request` class to the indicator's parent, which shows `.htmx-indicator` elements.

### hx-confirm

Show a confirmation dialog before the request.

```html
<button hx-delete="/item/5" hx-confirm="Delete this item? This cannot be undone.">
    Delete
</button>
```

### hx-disabled-elt

Disable elements during the request.

```html
<!-- Disable self -->
<button hx-post="/save" hx-disabled-elt="this">Save</button>

<!-- Disable specific elements -->
<form hx-post="/save" hx-disabled-elt="find button, find input[type='submit']">

<!-- Disable closest form -->
<button hx-post="/save" hx-disabled-elt="closest form">
```

### hx-push-url / hx-replace-url

Update the browser URL bar.

```html
<!-- Add to browser history -->
<a hx-get="/page/2" hx-push-url="true">Page 2</a>
<a hx-get="/api/page/2" hx-push-url="/page/2">Custom URL</a>

<!-- Replace current history entry (no back button) -->
<a hx-get="/page/2" hx-replace-url="true">Page 2</a>
```

---

## Synchronization

### hx-sync

Control how requests from an element synchronize.

```html
<!-- Drop new requests while one is in flight -->
<input hx-get="/search" hx-trigger="keyup changed delay:300ms"
       hx-sync="this:drop">

<!-- Abort previous request, issue new one -->
<input hx-get="/search" hx-trigger="keyup changed delay:300ms"
       hx-sync="this:abort">

<!-- Queue requests, process one at a time -->
<form hx-post="/save" hx-sync="this:queue">

<!-- Replace queued request with latest -->
<input hx-get="/search" hx-sync="closest form:abort">
```

| Strategy | Behavior |
|----------|----------|
| `drop` | Ignore new request if one is in flight |
| `abort` | Abort current request, issue new one |
| `replace` | Abort current, replace with new |
| `queue` | Queue request, run when current finishes |
| `queue first` | Queue only first additional request |
| `queue last` | Queue only latest request (drop older queued) |
| `queue all` | Queue all requests |

---

## Boosting

### hx-boost

Progressively enhance links and forms to use AJAX.

```html
<!-- Boost all links and forms within -->
<body hx-boost="true">
    <a href="/about">About</a>           <!-- now AJAX, targets body -->
    <form action="/search" method="get">  <!-- now AJAX -->
        <input name="q">
        <button type="submit">Search</button>
    </form>
</body>

<!-- Opt out specific elements -->
<a href="/external" hx-boost="false">External Link</a>
```

Boosted requests target `<body>` by default and push URL to history.

---

## Extensions

### hx-ext

Load HTMX extensions.

```html
<!-- Load on body for page-wide availability -->
<body hx-ext="response-targets, head-support">

<!-- Load on specific element -->
<div hx-ext="loading-states">
    <button hx-get="/data" data-loading-text="Loading...">Load</button>
</div>

<!-- Ignore extension on specific element -->
<div hx-ext="ignore:response-targets">
```

**Common extensions:**
- `response-targets` — Target different elements based on HTTP status codes
- `head-support` — Merge `<head>` content from responses
- `loading-states` — Enhanced loading state management
- `preload` — Preload links on hover
- `sse` — Server-Sent Events
- `ws` — WebSocket support
- `path-deps` — Refresh elements based on URL path dependencies

---

## Miscellaneous

### hx-inherit

Control attribute inheritance.

```html
<!-- Only inherit specific attributes -->
<div hx-target="#results" hx-inherit="hx-target">
    <!-- children inherit hx-target but not other attributes -->
</div>

<!-- Disable inheritance -->
<div hx-target="#results" hx-inherit="none">
```

### hx-disinherit

Prevent specific attributes from being inherited.

```html
<div hx-target="#results" hx-disinherit="hx-target">
    <!-- children do NOT inherit hx-target -->
</div>
```

### hx-preserve

Keep an element unchanged during swaps.

```html
<!-- Preserve a video player during content swaps -->
<video id="player" hx-preserve>
    <source src="video.mp4">
</video>
```

### hx-history

Control history caching.

```html
<!-- Don't cache this page in history -->
<body hx-history="false">
```

### hx-history-elt

Specify which element's content to snapshot for history.

```html
<div hx-history-elt id="content">
    <!-- only this element's content is saved in history -->
</div>
```
