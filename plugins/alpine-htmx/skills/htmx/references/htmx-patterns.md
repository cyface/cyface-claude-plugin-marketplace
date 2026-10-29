# htmx — Server-Driven UI Patterns

Each pattern works on htmx 2.x and htmx 4 unless a **2.x** / **4** note says otherwise. The usual differences: `:inherited` on shared parent attributes, event names, `hx-disabled-elt` vs `hx-disable`, and how polling stops.

## Contents

- [Active search](#active-search)
- [Inline editing](#inline-editing)
- [Infinite scroll](#infinite-scroll)
- [Click to load](#click-to-load)
- [Sortable table headers](#sortable-table-headers)
- [Bulk actions with checkboxes](#bulk-actions-with-checkboxes)
- [Cascading selects](#cascading-selects)
- [Form with validation errors](#form-with-validation-errors)
- [Polling and load polling](#polling-and-load-polling)
- [Optimistic UI with Alpine](#optimistic-ui-with-alpine)
- [Delete row with exit animation](#delete-row-with-exit-animation)
- [Tabs with URL updates](#tabs-with-url-updates)
- [Modal loaded from the server](#modal-loaded-from-the-server)
- [Edit-mode toggle with Alpine](#edit-mode-toggle-with-alpine)
- [Refresh other regions after a mutation](#refresh-other-regions-after-a-mutation)
- [File upload](#file-upload)
- [Server-Sent Events](#server-sent-events)
- [WebSockets](#websockets)
- [CSRF and global headers](#csrf-and-global-headers)
- [Progressive enhancement checklist](#progressive-enhancement-checklist)

---

## Active search

```html
<label for="q">Search</label>
<input id="q" type="search" name="q"
       hx-get="/customers/search"
       hx-trigger="input changed delay:300ms, search"
       hx-target="#results"
       hx-indicator="#searching"
       hx-sync="this:replace"
       autocomplete="off">
<span id="searching" class="htmx-indicator" aria-live="polite">Searching…</span>
<div id="results" aria-live="polite"></div>
```

- `input` fires for typing, paste and the clear button; `search` catches Enter on `type="search"`.
- `changed` skips requests when the value is unchanged, `delay:300ms` debounces, and `hx-sync="this:replace"` aborts the stale in-flight request so an older response can never overwrite a newer one.
- The server returns the rendered results fragment; an empty query returns the default state.

---

## Inline editing

Click-to-edit with the server returning both views.

```html
<!-- Display view -->
<div id="title-42" hx-target="this" hx-swap="outerHTML">
  <span>Current title</span>
  <button type="button" hx-get="/items/42/title/edit" aria-label="Edit title">Edit</button>
</div>

<!-- Server returns this edit view when clicked (hx-target/hx-swap repeated: 4 does not inherit) -->
<form id="title-42" hx-put="/items/42/title" hx-target="this" hx-swap="outerHTML">
  <label for="title-42-input" class="sr-only">Title</label>
  <input id="title-42-input" name="title" value="Current title" autofocus>
  <button type="submit">Save</button>
  <button type="button" hx-get="/items/42/title" hx-target="closest form" hx-swap="outerHTML">Cancel</button>
</form>
```

Fire-and-forget field (saves on blur or Enter, no swap):

```html
<input name="title" value="Current title"
       hx-post="/items/42/field"
       hx-vals='{"field": "title"}'
       hx-trigger="change, keyup[key=='Enter']"
       hx-swap="none"
       hx-indicator="closest .field">
```

---

## Infinite scroll

```html
<ul id="items">
  <li>…</li>
  <!-- sentinel rendered at the end of every page -->
  <li hx-get="/items?page=2" hx-trigger="intersect once" hx-swap="outerHTML" hx-indicator="this">
    <span class="htmx-indicator">Loading more…</span>
  </li>
</ul>
```

The server returns the next page's items plus a new sentinel pointing at page 3, or no sentinel on the last page. `revealed` is an alternative trigger that fires when the element scrolls into view.

---

## Click to load

```html
<div id="items">…</div>
<button hx-get="/items?page=2" hx-target="#items" hx-swap="beforeend" hx-indicator="this">
  <span>Load more</span><span class="htmx-indicator">Loading…</span>
</button>
```

Have the server also return an updated button (via `hx-swap-oob`/`<hx-partial>` with the next page number) or render the button inside the fragment with `hx-swap="outerHTML"` on the button itself.

---

## Sortable table headers

```html
<table>
  <thead>
    <!-- 2.x: hx-target/hx-swap/hx-push-url on <tr> are inherited by the <a>s -->
    <!-- 4: add :inherited -->
    <tr hx-target:inherited="#rows" hx-swap:inherited="innerHTML" hx-push-url:inherited="true">
      <th><a href="/items?sort=name&dir=asc" hx-get="/items?sort=name&dir=asc" hx-select="#rows > *">Name</a></th>
      <th><a href="/items?sort=date&dir=desc" hx-get="/items?sort=date&dir=desc" hx-select="#rows > *">Date</a></th>
    </tr>
  </thead>
  <tbody id="rows">…</tbody>
</table>
```

Keeping real `href`s means the page works without JavaScript and the pushed URL renders fully on reload. With `hx-select` the server can return the whole page; without it, return only the rows (check `HX-Request`).

---

## Bulk actions with checkboxes

```html
<form id="bulk" hx-post="/items/bulk-delete" hx-target="#items" hx-confirm="Delete the selected items?"
      x-data="{ selected: [] }">
  <label><input type="checkbox" @change="selected = $event.target.checked ? [...$el.form.querySelectorAll('input[name=id]')].map(i => i.value) : []"> Select all</label>

  <ul id="items">
    <li><label><input type="checkbox" name="id" value="1" x-model="selected"> Item 1</label></li>
    <li><label><input type="checkbox" name="id" value="2" x-model="selected"> Item 2</label></li>
  </ul>

  <button type="submit" :disabled="selected.length === 0">
    Delete <span x-text="selected.length"></span> selected
  </button>
</form>
```

The checkboxes are real form fields, so htmx submits `id=1&id=2` with no JSON bridging. Alpine only tracks the count for the button state. If the list itself is the swap target, the `x-data` stays on the form so the count survives the swap (reset it in `@htmx:after-swap` / `@htmx:after:swap`).

---

## Cascading selects

```html
<label for="country">Country</label>
<select id="country" name="country" hx-get="/states" hx-target="#state" hx-swap="outerHTML" hx-indicator="#state-loading">
  <option value="">Choose…</option>
  <option value="us">United States</option>
</select>
<span id="state-loading" class="htmx-indicator">Loading…</span>

<label for="state">State</label>
<select id="state" name="state" disabled><option>Select a country first</option></select>
```

The server returns a complete `<select id="state" name="state">` with options. The default `change` trigger is right for selects.

---

## Form with validation errors

```html
<form hx-post="/contact" hx-target="this" hx-swap="outerHTML" hx-disabled-elt="find button[type=submit]">
  <!-- 4: hx-disable="find button[type=submit]" -->
  <label for="email">Email</label>
  <input id="email" name="email" type="email" required aria-describedby="email-error">
  <p id="email-error" class="error" role="alert"><!-- server renders the message here --></p>
  <button type="submit">Send <span class="htmx-indicator">Sending…</span></button>
</form>
```

Server behavior:
- Success: return the success fragment, or `HX-Redirect`/`HX-Location`.
- Validation failure: re-render the form with messages and status **422**.
  - **4**: swaps automatically (only 204/304 are skipped). Optionally `hx-status:422="target:this"`.
  - **2.x**: 4xx is not swapped by default. Either return 200 for the re-rendered form, add the `response-targets` extension (`hx-target-422="this"`), or enable it globally:
    ```js
    document.body.addEventListener('htmx:beforeSwap', e => { if (e.detail.xhr.status === 422) e.detail.shouldSwap = true })
    // or htmx.config.responseHandling = [{code: '204', swap: false}, {code: '[23]..', swap: true}, {code: '422', swap: true, error: false}, …]
    ```

---

## Polling and load polling

```html
<!-- Fixed interval; stops when the tab is hidden -->
<div hx-get="/status" hx-trigger="every 5s [!document.hidden]" hx-swap="innerHTML">Status: active</div>
<!-- 4.0.0 parses the filter only on the event token: hx-trigger="every[!document.hidden] 5s" -->

<!-- Load polling: the fragment re-requests itself until the server stops rendering the trigger -->
<div hx-get="/jobs/123" hx-trigger="load delay:2s" hx-swap="outerHTML">
  Processing… <progress></progress>
</div>
<!-- When the job is done the server returns the final markup WITHOUT hx-trigger, and polling ends. -->
```

Stopping an `every` poll: **2.x** responds with status **286** (content swapped, polling stopped). **4** has no 286; use load polling, a filter (`every[!document.querySelector('.done')] 2s`), or replace the polling element. The `hx-ptag` extension (4) lets the server skip unchanged responses.

---

## Optimistic UI with Alpine

```html
<div x-data="{ liked: false, count: 42 }">
  <button type="button" hx-post="/posts/5/like" hx-swap="none" hx-sync="this:drop"
          @click="liked = !liked; count += liked ? 1 : -1"
          @htmx:response-error="liked = !liked; count += liked ? 1 : -1"
          :aria-pressed="liked">
    <!-- 4: @htmx:response:error (and @htmx:error for network failures) -->
    <span x-text="count"></span> likes
  </button>
</div>
```

Alpine updates immediately; htmx sends the request; the error handler reverts. Keep `x-data` off the swap target (here `hx-swap="none"` makes that moot).

---

## Delete row with exit animation

```html
<tr id="row-5">
  <td>Item</td>
  <td><button type="button" hx-delete="/items/5" hx-target="closest tr" hx-swap="outerHTML swap:400ms" hx-confirm="Delete this item?">Delete</button></td>
</tr>
```

- **2.x**: the `htmx-swapping` class is applied during the delay, so `tr.htmx-swapping { opacity: 0; transition: opacity 400ms }` fades the row out. Return 200 with an empty body.
- **4**: works the same (`htmx-swapping` is applied before the `swap:` delay); the class names are no longer configurable. `hx-swap="outerHTML transition:true"` with a View Transition is the alternative.

---

## Tabs with URL updates

```html
<nav hx-target:inherited="#panel" hx-push-url:inherited="true" role="tablist">   <!-- 2.x: no :inherited needed -->
  <a href="/settings/general"  hx-get="/settings/general"  role="tab" aria-selected="true">General</a>
  <a href="/settings/advanced" hx-get="/settings/advanced" role="tab" aria-selected="false">Advanced</a>
</nav>
<div id="panel" role="tabpanel">…</div>
```

Each tab URL renders the full page on direct load and the panel fragment for `HX-Request`. Have the server return the updated `<nav>` as an OOB swap/partial so `aria-selected` stays correct, or let Alpine track the active tab.

---

## Modal loaded from the server

```html
<button type="button" hx-get="/items/5/edit" hx-target="#modal" hx-swap="innerHTML">Edit</button>
<div id="modal"></div>
```

Server response (Alpine owns the open/close state; focus plugin for the trap):

```html
<div x-data="{ open: true }" x-init="$nextTick(() => $el.querySelector('[autofocus]')?.focus())"
     @keydown.escape.prevent.stop="open = false">
  <div x-show="open" class="fixed inset-0 bg-black/50" aria-hidden="true"></div>
  <div x-show="open" x-trap.inert.noscroll="open" role="dialog" aria-modal="true" aria-labelledby="edit-title"
       @click.outside="open = false" class="…">
    <h2 id="edit-title">Edit item</h2>
    <form hx-put="/items/5" hx-target="#item-5" hx-swap="outerHTML"
          @htmx:after-request="if ($event.detail.successful) open = false">
      <!-- 4: @htmx:after:request="if ($event.detail.ctx.response.status < 400) open = false" -->
      <input name="name" value="Current name" autofocus>
      <button type="submit">Save</button>
      <button type="button" @click="open = false">Cancel</button>
    </form>
  </div>
</div>
```

On a 422 the server re-renders the form; with **4** it swaps automatically into `#item-5` unless you add `hx-status:422="target:'closest form'"` (or `hx-target="closest form"` on the form and let success use `HX-Retarget: #item-5`). With **2.x** use `response-targets` or return 200 for the error form. Clear `#modal` after closing (`@htmx:after-request` can also empty it, or swap the response into `#modal` with `hx-swap="innerHTML"` and return nothing).

---

## Edit-mode toggle with Alpine

```html
<div x-data="{ editing: false }">
  <div x-show="!editing">
    <span>Current value</span>
    <button type="button" @click="editing = true">Edit</button>
  </div>
  <form x-show="editing" x-cloak hx-post="/items/5" hx-target="#item-5-value" hx-swap="innerHTML"
        @htmx:after-request="if ($event.detail.successful) editing = false">
    <!-- 4: @htmx:after:request -->
    <input name="value" value="Current value">
    <button type="submit">Save</button>
    <button type="button" @click="editing = false">Cancel</button>
  </form>
</div>
```

`x-data` sits above the target (`#item-5-value` is inside the `x-show="!editing"` block), so the `editing` flag survives the swap.

---

## Refresh other regions after a mutation

Respond to the mutation with `HX-Trigger: contactsChanged` and let interested elements re-fetch themselves:

```html
<div hx-get="/contacts/count" hx-trigger="contactsChanged from:body" hx-swap="innerHTML">12</div>
<table hx-get="/contacts/table" hx-trigger="contactsChanged from:body" hx-select="tbody" hx-target="find tbody">…</table>
```

This keeps the mutation endpoint ignorant of what else is on the page. For data you already have at hand, `<hx-partial>` or `hx-swap-oob` avoids the extra round trips.

---

## File upload

```html
<form hx-post="/upload" hx-encoding="multipart/form-data" hx-target="#upload-result" hx-indicator="#uploading">
  <label for="doc">Document</label>
  <input id="doc" type="file" name="document" accept=".pdf,.docx" required>
  <button type="submit">Upload</button>
  <progress id="uploading" class="htmx-indicator"></progress>
</form>
<div id="upload-result" aria-live="polite"></div>
```

Upload progress: **2.x** exposes `htmx:xhr:progress` (`e.detail.loaded / e.detail.total`). **4** uses `fetch`, which has no upload progress events; show an indeterminate indicator or upload via a small script with `XMLHttpRequest` if a percentage is required.

---

## Server-Sent Events

```html
<!-- 2.x: htmx-ext-sse package + hx-ext -->
<div hx-ext="sse" sse-connect="/events" sse-swap="message" hx-target="#feed" hx-swap="beforeend"></div>

<!-- 4: hx-sse extension script, no hx-ext -->
<div hx-sse:connect="/events" hx-trigger="message from:body" hx-get="/feed/latest" hx-target="#feed" hx-swap="beforeend"></div>
<!-- or stream straight into a target: any hx-get whose response is text/event-stream streams -->
```

Named events become DOM events in 4 (`hx-trigger="progress from:body"`), and `hx-sse:close="done"` ends the connection on a named event.

---

## WebSockets

```html
<!-- 2.x -->
<div hx-ext="ws" ws-connect="/chat">
  <div id="messages"></div>
  <form ws-send><input name="text"></form>
</div>

<!-- 4 -->
<div hx-ws:connect="/chat" hx-target="#messages" hx-swap="beforeend">
  <div id="messages"></div>
  <form hx-ws:send><input name="text"></form>
</div>
```

In 2.x server messages are treated as OOB swaps by id; in 4 they swap into the connect element's target (use `<hx-partial>` in messages for multiple regions).

---

## CSRF and global headers

```html
<!-- 2.x: inherited by every descendant -->
<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>

<!-- 4: the suffix is required, otherwise children send no header and get 403 -->
<body hx-headers:inherited='{"X-CSRFToken": "{{ csrf_token }}"}'>
```

Or once in JavaScript:

```js
// 2.x
document.body.addEventListener('htmx:configRequest', e => {
  e.detail.headers['X-CSRFToken'] = document.querySelector('meta[name=csrf-token]').content
})
// 4
document.body.addEventListener('htmx:config:request', e => {
  e.detail.ctx.request.headers['X-CSRFToken'] = document.querySelector('meta[name=csrf-token]').content
})
```

With `hx-boost` and a `<body>` swap target, place the attribute on `<html>` or inside the swapped region so it survives navigation.

---

## Progressive enhancement checklist

- Links keep real `href`s and forms keep `action`/`method`; htmx attributes enhance them.
- Every `hx-push-url` destination renders a full page without `HX-Request`.
- Return fragments only when `HX-Request: true`; send `Vary: HX-Request`.
- Use real form fields instead of `hx-vals` where possible so the form works without JavaScript.
- Keep ids stable across swaps so focus, scroll position, CSS transitions and `hx-preserve` keep working.
