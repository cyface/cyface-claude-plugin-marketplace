---
name: htmx
description: >-
  htmx guidance covering both supported lines: htmx 2.x (npm "latest", supported
  indefinitely) and htmx 4 (stable since August 2026 with explicit :inherited
  attribute inheritance, colon event names, 4xx/5xx swapping, no hx-ext, no 286).
  Use this skill BEFORE writing or editing any htmx markup, even one attribute:
  the two lines differ in ways that silently break code, so the skill starts by
  establishing which one the project uses. Trigger on hx-get, hx-post,
  hx-target, hx-swap, hx-trigger, hx-boost, hx-vals, hx-swap-oob, <hx-partial>,
  HX-* headers, and on requests for AJAX or partial page updates without a
  framework, search-as-you-type, infinite scroll, polling, inline editing,
  server-rendered modals, form submission without reload, SSE/WebSocket
  streaming, or CSRF with htmx, including Django, Flask, Rails, Laravel, Go or
  Phoenix templates that already use htmx even when the user does not name it.
  Also use whenever htmx is paired with Alpine.js. Failing page: htmx-debug;
  2-to-4 migration: htmx-upgrade.
---

# htmx Development Guide

htmx lets any element issue an HTTP request and swap the **HTML** response into the page. The server renders fragments; the browser never sees JSON. htmx owns **server communication**: fetching content, submitting forms, sorting, filtering, polling, streaming. Pair it with Alpine.js for purely client-side UI state (see the `alpine-js` skill).

## Step 0: establish which htmx line the project uses

Two supported majors exist and they differ in ways that silently break code:

| | **htmx 2.x** (2.0.11) | **htmx 4** (4.0.0, stable 2026-08-28) |
|---|---|---|
| Status | npm `latest`; htmx.org quick start; "supported indefinitely" | npm `next` until 2027 so unpinned 2.x users are not force-upgraded; the team's docs and shipped AI guidance now target it |
| Transport | XMLHttpRequest | `fetch()`; streaming swaps; 60 s default timeout |
| Attribute inheritance | Implicit (parent `hx-target` applies to children) | **Explicit**: `hx-target:inherited="#out"` on the parent |
| Event names | `htmx:afterRequest`, also fired as `htmx:after-request` | `htmx:after:request` only (lowercase, colon-separated) |
| 4xx/5xx responses | Not swapped by default | **Swapped** by default; `hx-status:422="…"` per status |
| Extensions | Separate `htmx-ext-*` packages + `hx-ext="name"` | Ship in `htmx.org/dist/ext/*.js`; no `hx-ext`, including the script activates it |
| Morph swaps | `idiomorph` extension | Built in: `hx-swap="outerMorph"` / `innerMorph` |
| Stop polling | HTTP 286 response, or a trigger filter | Remove the polling element or use a filter (286 is gone) |
| Multi-region updates | `hx-swap-oob`; `<hx-partial>` (2.0.11+) | `<hx-partial>` preferred; `hx-swap-oob` simplified |
| Disable during request / ignore subtree | `hx-disabled-elt` / `hx-disable` | `hx-disable` / `hx-ignore` (**renamed, meanings shifted**) |
| CSRF header on `<body>` | `hx-headers='{…}'` | `hx-headers:inherited='{…}'` |

Find out before writing anything: look at the `<script src=…htmx.org@X…>` tag, `package.json`, or run `htmx.version` in the console. If the project is new and the user has no preference, recommend **htmx 4 pinned to an exact version** and say why (it is the current major and what the maintainers now document first); 2.x remains a sound choice for existing apps and for extension-heavy stacks that have not been ported. Never mix guidance: an `:inherited` suffix is ignored by 2.x and a bare parent `hx-target` is ignored by 4.

Install (pin exact versions; both docs recommend self-hosting rather than a CDN in production):

```html
<!-- htmx 2.x -->
<script src="https://cdn.jsdelivr.net/npm/htmx.org@2.0.11/dist/htmx.min.js" integrity="sha384-2OatzQy1H+Zd/IIrjr1TcuDGqLXeHhbooAyJY1KdQMKnr4LZ22k31GBLdYKHmVjg" crossorigin="anonymous"></script>

<!-- htmx 4 -->
<script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0" integrity="sha384-BvJpBiO8Kh31EqtJe5DRIeWrHWnCGkwytKs9NKFi86Hhw96dEqdEMzZDeK9iEGTc" crossorigin="anonymous"></script>
<!-- htmx 4 extensions live in the same package -->
<script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/ext/hx-preload.js"></script>
```

For a migration, use the **`htmx-upgrade`** skill (it wraps the shipped checker, `npx htmx.org@4.0.0 upgrade-check -- ./templates`); for a failure you cannot explain, use **`htmx-debug`**.

## The request/target/swap/trigger model (both versions)

```html
<button hx-get="/contacts?page=2"
        hx-target="#contacts"      <!-- where the response goes (default: the element itself) -->
        hx-swap="beforeend"        <!-- how it is inserted (default: innerHTML) -->
        hx-trigger="click"         <!-- when (default: click; change for inputs; submit for forms) -->
        hx-indicator="#spinner">   <!-- what shows while in flight -->
  Load more
</button>
<span id="spinner" class="htmx-indicator">Loading…</span>
<div id="contacts">…</div>
```

- **Verbs**: `hx-get` `hx-post` `hx-put` `hx-patch` `hx-delete` (4 adds `hx-query`, plus `hx-action` + `hx-method` for custom verbs).
- **Targets**: CSS selector or extended selector `this`, `closest tr`, `find .body`, `next .error`, `previous .row`. Relative selectors avoid inventing ids inside loops.
- **Swap styles**: `innerHTML` (default) `outerHTML` `textContent` `beforebegin` `afterbegin` `beforeend` `afterend` `delete` `none`. htmx 4 adds `outerSync`, `innerMorph`, `outerMorph` and the aliases `before`/`prepend`/`append`/`after`.
- **Swap modifiers**: `swap:200ms` `settle:…` `transition:true` `ignoreTitle:true` `scroll:top|bottom` `show:top|bottom|none`; 2.x `focus-scroll:true` and `show:#id:top`, 4 `focusScroll:true` plus separate `scrollTarget:`/`showTarget:` selectors, `strip:true`, `swapEmpty:true`.
- **Triggers**: events (`click`, `input`, `submit`, custom), `load`, `revealed`, `intersect [once] [root:<sel>] [threshold:0.5]`, `every 5s [filter]` (4.0.0: `every[filter] 5s`). Modifiers: `once` `changed` `delay:300ms` `throttle:1s` `from:<sel>` `target:<sel>` `consume`; 2.x also `queue:first|last|all|none`; 4 also `prevent` `stop` `halt` `capture` `passive`. Filters: `keyup[key=='Enter']`, `click[ctrlKey]`. Multi-word selectors: `from:(closest form)` in 2.x, `from:'closest form'` in 4.
- **Concurrency**: `hx-sync="this:replace"` (abort the in-flight request, issue the new one), `this:drop`, `this:abort`, `this:queue last`. Always use it on search inputs; `delay:` alone does not stop stale responses overwriting newer ones.

Full attribute, modifier, config and header tables for both lines: **`references/htmx-attributes.md`**.

## Sending data

```html
<form hx-post="/contacts" hx-target="#list" hx-swap="beforeend">…</form>  <!-- all fields sent -->
<button hx-post="/archive" hx-vals='{"id": 42}'>Archive</button>            <!-- extra static values -->
<input hx-post="/save" hx-vals='js:{value: event.target.value.trim()}'>    <!-- computed values -->
<button hx-post="/save" :hx-vals="JSON.stringify({ id })">                  <!-- from Alpine state -->
<button hx-get="/report" hx-include="#filters, closest form">               <!-- values from elsewhere -->
<form hx-post="/upload" hx-encoding="multipart/form-data">                  <!-- file uploads -->
```

- POST/PUT/PATCH include the enclosing form automatically. GET does not. In **htmx 4, DELETE no longer does either**; add `hx-include="closest form"`.
- `hx-headers` adds request headers (same `js:` prefix). `hx-params` (filter fields) exists only in 2.x; in 4 filter in `htmx:config:request`.
- htmx 4 values use HCON, a braces-free JSON (`hx-vals="id:42, draft"`); plain JSON still works.

## UX attributes

- `hx-indicator="#el"` toggles `htmx-request` on that element; `.htmx-indicator` children become visible. Put the indicator in the DOM before the request.
- `hx-confirm="Delete this?"` native confirm; 4 accepts `js:` async expressions. Alpine or `<dialog>` for styled confirms.
- **Prevent double submits**: `hx-disabled-elt="this"` (2.x) / `hx-disable="this"` (4) on the form or button, or `hx-sync="this:drop"`.
- `hx-push-url="true"` / `hx-replace-url` for navigation. Every pushed URL must also render a full page on direct load.
- `hx-boost="true"` upgrades links and forms to AJAX, targeting `<body>`. In 4 it must be `hx-boost:inherited="true"` on the container to affect descendants.
- `hx-preserve` keeps an element (video, map, editor) across swaps.

## Updating several regions from one response

1. **Widen the target** so one fragment covers both regions. Simplest.
2. **`<hx-partial>`** (4, and 2.0.11+): server-sent swap commands; the wrapper never lands in the page.
   ```html
   <li id="note-42">Updated note</li>                      <!-- main swap -->
   <hx-partial hx-target="#count" hx-swap="innerHTML">7</hx-partial>
   <hx-partial hx-target="#toasts" hx-swap="beforeend"><div class="toast">Saved</div></hx-partial>
   ```
3. **`hx-swap-oob`** on elements in the response: `<span id="count" hx-swap-oob="true">7</span>`. Ids must exist in the page. Order differs: 2.x applies OOB *before* the main swap, 4 applies it *after*; 4 no longer performs an empty main swap for OOB-only responses (`swapEmpty:true` to restore).
4. **`HX-Trigger` response header** to fire a DOM event that other elements listen to with `hx-trigger="contactsChanged from:body"`. Decoupled, good for "refresh the list after any mutation".

## Events, scripting and Alpine

Lifecycle (2.x name → 4 name): `htmx:configRequest` → `htmx:config:request` · `htmx:beforeRequest` → `htmx:before:request` · `htmx:afterRequest` → `htmx:after:request` · `htmx:beforeSwap` → `htmx:before:swap` · `htmx:afterSwap` → `htmx:after:swap` · `htmx:afterSettle` → `htmx:after:settle` · `htmx:responseError` → `htmx:response:error` · `htmx:sendError`/`timeout` → `htmx:error` · `htmx:load` → `htmx:after:init`.

Where to listen:

| Need | 2.x | 4 |
|------|-----|---|
| Inline on the element | `hx-on::after-request="…"` (`::` = `htmx:`); kebab-case only, attributes are case-insensitive | `hx-on::after:request="…"`, or the trigger-grammar form `hx-on="htmx:after:request -> …; click once -> …"` |
| Global JS | `document.body.addEventListener('htmx:afterRequest', e => e.detail.successful …)` | `… ('htmx:after:request', e => e.detail.ctx.response.status …)` |
| Alpine listener | `@htmx:after-request` (**kebab-case; `@htmx:afterRequest` never fires**) | `@htmx:after:request` verbatim (names are already lowercase); only `htmx:before:viewTransition` / `after:viewTransition` need `.camel` |
| Request mutation | `e.detail.headers['X']=…; e.detail.parameters.k=…; e.detail.path=…` | `e.detail.ctx.request.headers['X']=…; ctx.request.body.set('k', v); ctx.request.action=…` |
| Success check | `e.detail.successful` | `e.detail.ctx.response.status` (2xx/3xx) or handle `htmx:response:error` |

```html
<!-- Alpine + htmx 2.x -->
<form x-data="{ open: true }" hx-post="/notes" hx-target="#notes" hx-swap="beforeend"
      @htmx:after-request="if ($event.detail.successful) open = false"
      @htmx:response-error="$store.toasts.add('Save failed', 'error')">

<!-- Alpine + htmx 4 -->
<form x-data="{ open: true }" hx-post="/notes" hx-target="#notes" hx-swap="beforeend"
      @htmx:after:request="if ($event.detail.ctx.response.status < 400) open = false"
      @htmx:response:error="$store.toasts.add('Save failed', 'error')">
```

Division of labour with Alpine (both versions):

| Task | Use |
|------|-----|
| Open/close, tabs, client-only filtering, optimistic toggles | Alpine |
| Fetch, submit, sort, paginate, poll, stream | htmx |
| Loading state | `hx-indicator` first; Alpine `@htmx:before-request` only for custom UI |
| Pass Alpine data to the server | `:hx-vals="JSON.stringify({…})"` or `hx-vals='js:…'` |
| Keep Alpine state across a swap | Put `x-data` on an ancestor of the `hx-target`, or morph: 2.x `hx-ext="alpine-morph" hx-swap="morph"`, 4 `hx-swap="outerMorph"` + the `hx-alpine-compat` extension |
| Alpine inserts markup containing `hx-*` | Call `htmx.process(el)` after insertion |

htmx 4 also ships `hx-live`, its own small reactive scripting layer; prefer Alpine when it is already on the page.

## Errors and validation responses

- **2.x**: 4xx/5xx are not swapped. Render validation errors with a 200 and the re-rendered form, or use the `response-targets` extension (`hx-target-422="#errors"`), or opt in via `htmx.config.responseHandling` / an `htmx:beforeSwap` listener that sets `e.detail.shouldSwap = true` for 422.
- **4**: everything except 204/304 swaps, so a 422 that returns the form lands in the target automatically. Route by status with `hx-status:422="target:#errors select:#errors"` and `hx-status:5xx="swap:none"`. Restore 2.x behavior with `htmx.config.noSwap = [204, 304, '4xx', '5xx']`.
- Return **204** when there is nothing to swap, **422** for validation failures with the form re-rendered, `HX-Redirect`/`HX-Location` for navigation after a POST.

## Security

- Escape user content server-side; htmx inserts whatever HTML it receives. Scrub `hx-*` attributes and `<script>` from third-party HTML.
- **CSRF**: send the token on every mutating request. 2.x: `<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>` (inherited). 4: `<body hx-headers:inherited='{"X-CSRFToken": "…"}'>` (the suffix is required or children send nothing). Or set it once in `htmx:configRequest` / `htmx:config:request`. Frameworks with cookie-based tokens (Django, Rails, Laravel) still need the header.
- Same-origin only by default: 2.x `htmx.config.selfRequestsOnly=true`, 4 `htmx.config.mode='same-origin'`.
- CSP: `hx-on`, trigger filters and `js:` values use `new Function`, so they need `'unsafe-eval'`; avoid them under strict CSP (2.x `allowEval=false`; 4 `hx-csp` extension with `safeEval:true` and per-element `hx-nonce`). Scripts in swapped content run (2.x `allowScriptTags=false` to stop; 4 always, with `inlineScriptNonce`).
- Keep secrets out of `hx-vals`/`hx-headers`; they are visible in the DOM.
- History: 2.x snapshots pages into `sessionStorage` (`hx-history="false"` to exclude sensitive pages); 4 re-requests on back/forward unless the `hx-history-cache` extension is loaded.

## Server-side checklist

- Detect htmx requests with the `HX-Request: true` header and return a fragment; otherwise return the full page (progressive enhancement, and required for `hx-push-url`). Add `Vary: HX-Request` (4: also `Vary: HX-Request-Type`) when caching.
- Request headers: `HX-Target`, `HX-Current-URL`, `HX-Boosted`, `HX-History-Restore-Request`; 2.x `HX-Trigger`/`HX-Trigger-Name`/`HX-Prompt` (element id); 4 `HX-Source` (`tag#id`), `HX-Request-Type` (`partial`|`full`).
- Response headers: `HX-Trigger`, `HX-Retarget`, `HX-Reswap`, `HX-Reselect`, `HX-Push-Url`, `HX-Replace-Url`, `HX-Redirect`, `HX-Location`, `HX-Refresh`; 2.x only: `HX-Trigger-After-Swap`, `HX-Trigger-After-Settle`.
- Polling: 2.x stops on a **286** response; 4 stops only when the polling element is removed or replaced (return a fragment without the `hx-trigger="every …"` element) or a filter is false (4.0.0 parses it only as `every[!done] 2s`, not the documented `every 2s [!done]`).

## Reference files

- **`references/htmx-attributes.md`** — every attribute, modifier, config option, event, header and extension for 2.x and 4 side by side.
- **`references/htmx-patterns.md`** — active search, inline edit, infinite scroll, sortable tables, bulk actions, cascading selects, polling, optimistic UI, server-rendered modals, file upload, SSE/WebSockets, each shown for both lines where they differ.

Companion skills in this plugin: **`htmx-upgrade`** (2.x to 4 migration workflow and rename tables) and **`htmx-debug`** (lifecycle checklist and symptom-to-cause guide).

When a question goes beyond these files, fetch the official docs rather than guessing: htmx 4 serves every page as Markdown (`https://four.htmx.org/docs.md`, `/reference/attributes/hx-swap.md`, …) with an index at `https://four.htmx.org/llms.txt`; the `htmx.org@4.0.0` npm package also ships maintainer-written guidance in `dist/skills/` (`htmx-guidance.md`, `htmx-debugging.md`, `htmx-upgrade-from-htmx2.md`, `htmx-extension-authoring.md`). htmx 2 docs are at `https://htmx.org/docs/` and `https://htmx.org/attributes/<name>/` (no llms.txt).
