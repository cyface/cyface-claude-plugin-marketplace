# HTMX — Common Server-Driven UI Patterns

## Active Search

Search-as-you-type with debouncing.

```html
<input type="search"
       name="q"
       placeholder="Search..."
       hx-get="/api/search"
       hx-trigger="keyup changed delay:300ms, search"
       hx-target="#search-results"
       hx-indicator="#search-spinner"
       hx-sync="this:replace">

<span id="search-spinner" class="htmx-indicator">Searching...</span>
<div id="search-results"></div>
```

**Server returns:** HTML fragment with search results. Empty query returns empty state or all results.

**Key details:**
- `delay:300ms` debounces to avoid excessive requests
- `changed` prevents requests when value hasn't actually changed
- `hx-sync="this:replace"` cancels in-flight request when new one starts
- `search` event catches the clear button (x) on search inputs

---

## Inline Editing

Edit-in-place with save on blur or Enter.

```html
<!-- Display mode -->
<span hx-get="/edit/title/5"
      hx-trigger="click"
      hx-target="this"
      hx-swap="outerHTML"
      class="editable"
      title="Click to edit">
    Current Title
</span>

<!-- Server returns this edit form when clicked -->
<form hx-put="/api/items/5/title"
      hx-target="this"
      hx-swap="outerHTML">
    <input name="title"
           value="Current Title"
           hx-trigger="blur changed, keyup[key=='Enter']"
           hx-put="/api/items/5/title"
           hx-target="closest form"
           hx-swap="outerHTML"
           autofocus>
    <button type="button"
            hx-get="/view/title/5"
            hx-target="closest form"
            hx-swap="outerHTML">Cancel</button>
</form>
```

### Fire-and-Forget Inline Edit

Simpler pattern for fields that auto-save:

```html
<input type="text"
       value="Current value"
       data-guid="abc123"
       data-field="title"
       hx-post="/api/update"
       hx-vals='js:{guid: event.target.dataset.guid, field: event.target.dataset.field, value: event.target.value.trim()}'
       hx-trigger="blur changed, keyup[key=='Enter']"
       hx-swap="none">
```

---

## Infinite Scroll

Load more content as user scrolls.

```html
<div id="item-list">
    <!-- Initial items rendered server-side -->
    <div class="item">Item 1</div>
    <div class="item">Item 2</div>
    <!-- ... -->

    <!-- Sentinel: triggers load when visible -->
    <div hx-get="/api/items?page=2"
         hx-trigger="intersect once"
         hx-swap="outerHTML"
         hx-indicator="#load-more-spinner">
        <span id="load-more-spinner" class="htmx-indicator">Loading more...</span>
    </div>
</div>
```

**Server returns:** Next batch of items + a new sentinel div pointing to page 3. When no more items, return nothing (or a "No more items" message) without a new sentinel.

---

## Click to Load (Pagination Alternative)

```html
<div id="items">
    <div class="item">Item 1</div>
    <div class="item">Item 2</div>
</div>

<button hx-get="/api/items?page=2"
        hx-target="#items"
        hx-swap="beforeend"
        hx-indicator="this">
    <span class="default-text">Load More</span>
    <span class="htmx-indicator">Loading...</span>
</button>
```

**Server returns:** Next batch of items. Update the button's `hx-get` to point to page 3 using OOB swap, or return a new button.

---

## Sortable Table Headers

Click column headers to sort, preserving other query parameters.

```html
<table>
    <thead>
        <tr hx-target="#table-body" hx-swap="innerHTML">
            <th hx-get="/api/items?sort=name&order=asc&page=1"
                hx-push-url="true"
                class="sortable">
                Name ▲
            </th>
            <th hx-get="/api/items?sort=date&order=desc&page=1"
                hx-push-url="true"
                class="sortable">
                Date
            </th>
        </tr>
    </thead>
    <tbody id="table-body">
        <!-- Server-rendered rows -->
    </tbody>
</table>
```

**Server returns:** New table body HTML with sorted data. Headers should update sort indicators.

---

## Bulk Operations with Checkboxes

Select multiple items and perform batch actions.

```html
<div x-data="{ selectedIds: [] }">
    <!-- Select all -->
    <label>
        <input type="checkbox"
               @change="selectedIds = $event.target.checked
                   ? [...document.querySelectorAll('.item-checkbox')].map(el => el.value)
                   : []">
        Select All
    </label>

    <!-- Item checkboxes -->
    <template x-for="item in items">
        <label>
            <input type="checkbox"
                   class="item-checkbox"
                   :value="item.id"
                   x-model="selectedIds">
            <span x-text="item.name"></span>
        </label>
    </template>

    <!-- Bulk action -->
    <button hx-post="/api/items/bulk-delete"
            :hx-vals="JSON.stringify({ ids: selectedIds })"
            hx-target="#item-list"
            hx-confirm="Delete selected items?"
            x-show="selectedIds.length > 0">
        Delete <span x-text="selectedIds.length"></span> items
    </button>
</div>
```

---

## Cascading Selects

Second dropdown depends on first dropdown's value.

```html
<select name="country"
        hx-get="/api/states"
        hx-target="#state-select"
        hx-trigger="change"
        hx-indicator="#states-loading">
    <option value="">Select Country</option>
    <option value="us">United States</option>
    <option value="ca">Canada</option>
</select>

<span id="states-loading" class="htmx-indicator">Loading...</span>

<select name="state" id="state-select" disabled>
    <option>Select country first</option>
</select>
```

**Server returns:** New `<select>` element with options for the chosen country (replaces the target).

---

## Form with Response Feedback

Show success/error messages after form submission.

```html
<form hx-post="/api/contact"
      hx-target="#form-feedback"
      hx-swap="innerHTML"
      hx-indicator="#submit-indicator"
      hx-disabled-elt="find button[type='submit']">

    <input name="email" type="email" required>
    <textarea name="message" required></textarea>

    <button type="submit">
        Send
        <span id="submit-indicator" class="htmx-indicator">Sending...</span>
    </button>

    <div id="form-feedback"></div>
</form>
```

**Server returns:**
- Success: `<div class="alert-success">Message sent!</div>`
- Error: `<div class="alert-error">Please fix errors.</div>` plus optionally re-render form with validation errors

---

## Polling for Updates

Periodically refresh content.

```html
<!-- Simple polling -->
<div hx-get="/api/status"
     hx-trigger="every 5s"
     hx-target="this"
     hx-swap="innerHTML">
    Status: Active
</div>

<!-- Conditional polling (stop when condition met) -->
<div hx-get="/api/job/123/status"
     hx-trigger="every 2s [!document.querySelector('.job-complete')]">
    Processing...
</div>

<!-- Server can stop polling by returning 286 status code -->
<!-- 286 response = content is swapped but polling stops -->
```

---

## Optimistic UI with Alpine + HTMX

Show immediate feedback while server processes.

```html
<div x-data="{ likeCount: 42, liked: false }">
    <button @click="liked = !liked; likeCount += liked ? 1 : -1"
            hx-post="/api/posts/5/like"
            hx-swap="none"
            @htmx:response-error="liked = !liked; likeCount += liked ? 1 : -1"
            :class="{ 'liked': liked }">
        <span x-text="likeCount"></span> Likes
    </button>
</div>
```

**Pattern:** Update UI immediately with Alpine, send request with HTMX, revert on error.

---

## Delete Row with Animation

Remove a table row with a fade-out effect.

```html
<tr id="row-5">
    <td>Item Name</td>
    <td>
        <button hx-delete="/api/items/5"
                hx-target="closest tr"
                hx-swap="outerHTML swap:500ms"
                hx-confirm="Delete this item?">
            Delete
        </button>
    </td>
</tr>

<style>
    tr.htmx-swapping { opacity: 0; transition: opacity 500ms ease-out; }
</style>
```

---

## Tabs with URL Updates

Server-rendered tabs with history support.

```html
<div class="tabs">
    <nav hx-target="#tab-content" hx-swap="innerHTML" hx-push-url="true">
        <a hx-get="/tabs/general" class="active">General</a>
        <a hx-get="/tabs/advanced">Advanced</a>
        <a hx-get="/tabs/danger">Danger Zone</a>
    </nav>

    <div id="tab-content">
        <!-- Server-rendered content for active tab -->
    </div>
</div>
```

---

## Modal from Server

Fetch modal content from the server.

```html
<button hx-get="/modals/edit-item/5"
        hx-target="#modal-container"
        hx-swap="innerHTML">
    Edit
</button>

<div id="modal-container"></div>
```

**Server returns:** Complete modal HTML including Alpine.js state for open/close behavior.

```html
<!-- Server response -->
<div x-data="{ open: true }"
     x-show="open"
     @keydown.escape.window="open = false"
     role="dialog"
     aria-modal="true"
     class="modal-overlay">
    <div class="modal-content" @click.stop>
        <h2>Edit Item</h2>
        <form hx-put="/api/items/5"
              hx-target="#item-5"
              hx-swap="outerHTML"
              @htmx:after-request="if($event.detail.successful) open = false">
            <input name="name" value="Current Name">
            <button type="submit">Save</button>
            <button type="button" @click="open = false">Cancel</button>
        </form>
    </div>
</div>
```

---

## File Upload with Progress

```html
<form hx-post="/api/upload"
      hx-encoding="multipart/form-data"
      hx-target="#upload-result"
      hx-indicator="#upload-progress">

    <input type="file" name="document" accept=".pdf,.doc,.docx">
    <button type="submit">Upload</button>

    <div id="upload-progress" class="htmx-indicator">
        <div class="progress-bar">Uploading...</div>
    </div>
</form>

<div id="upload-result"></div>
```

---

## Edit Mode Toggle (Alpine + HTMX)

Switch between display and edit modes, save to server.

```html
<div x-data="{ editing: false }">
    <!-- Display mode -->
    <div x-show="!editing">
        <span>Current Value</span>
        <button @click="editing = true" type="button">Edit</button>
    </div>

    <!-- Edit mode -->
    <form x-show="editing"
          hx-post="/api/update"
          hx-target="#list"
          hx-swap="innerHTML"
          @htmx:after-request="editing = false">
        <input type="hidden" name="id" value="5">
        <input name="value" value="Current Value">
        <button type="submit">Save</button>
        <button type="button" @click="editing = false">Cancel</button>
    </form>
</div>
```

---

## Response Targets by Status Code

Handle different HTTP statuses differently (requires `response-targets` extension).

```html
<body hx-ext="response-targets">
    <form hx-post="/api/save"
          hx-target="#success-container"
          hx-target-422="#form-errors"
          hx-target-500="#server-error"
          hx-target-error="#generic-error">
        <!-- form fields -->
    </form>

    <div id="success-container"></div>
    <div id="form-errors"></div>
    <div id="server-error"></div>
    <div id="generic-error"></div>
</body>
```

---

## Preloading on Hover

Fetch content before user clicks (requires `preload` extension).

```html
<body hx-ext="preload">
    <a href="/about" hx-get="/about" hx-target="#content" preload="mousedown">
        About
    </a>
    <a href="/contact" hx-get="/contact" hx-target="#content" preload>
        Contact (preloads on hover)
    </a>
</body>
```

---

## Request Headers Pattern

Send timezone or other context with every request.

```html
<!-- On a parent element (inherited by all children) -->
<body hx-headers='js:{"X-Timezone": Intl.DateTimeFormat().resolvedOptions().timeZone}'>
    <!-- All HTMX requests within body include the timezone header -->
</body>
```

Or configure globally:

```javascript
document.body.addEventListener('htmx:configRequest', (event) => {
    event.detail.headers['X-Timezone'] = Intl.DateTimeFormat().resolvedOptions().timeZone
    event.detail.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]')?.content
})
```
