---
name: htmx-debug
description: >-
  Diagnose htmx problems. Use this skill whenever a user reports htmx behaving
  unexpectedly, even when the cause looks obvious, because the checklist
  separates htmx 2.x from htmx 4 symptoms (inheritance, event names, error
  swapping, polling) that are easy to misattribute. Trigger on: a request that
  never fires, a swap that does not happen or lands in the wrong element, content
  that swaps but loses Alpine state or event handlers, an htmx: listener that
  never runs, a toast or callback that stopped working, polling that will not
  stop, CSRF 403s, an extension that seems inactive, back-button oddities, or
  anything that "worked on htmx 2 and broke on htmx 4" or "broke after bumping
  the script tag". Also use when the user pastes an htmx snippet asking why it
  does not work or asks how to see what htmx is doing. For writing new markup use
  the htmx skill; for a planned migration use htmx-upgrade.
argument-hint: "[description of the problem]"
---

# Debugging htmx

Most htmx bugs are one of five things: the wrong htmx line for the syntax used, a trigger that never fires, a target selector that matches nothing, a response the browser cannot swap, or inheritance that is not happening. Work the checklist in order before theorizing.

## 1. Establish facts before guessing

Ask for, or find in the project, these in this order:

1. **Which htmx line?** Script tag (`htmx.org@2…` vs `@4…`) or `htmx.version` in the console. 2.x and 4 differ in event names, inheritance, error handling and attribute names, so a 2.x answer applied to a 4 project (or vice versa) is the single most common cause of "nothing happens". Mixed-version symptoms: `:inherited` suffixes in a 2.x project (ignored), bare parent `hx-target` in a 4 project (ignored), `hx-on::after-request` on 4 or `hx-on::after:request` on 2.x (never fires).
2. **Is htmx loaded and did it process the element?** `typeof htmx` in the console; 2.x marks processed elements with `el['htmx-internal-data']`, 4 with `el._htmx`. Content inserted by other JavaScript (Alpine `x-html`, templates, frameworks) needs `htmx.process(el)`.
3. **The exact markup** of the triggering element and its ancestors (inheritance lives there), plus the target element.
4. **The Network tab**: was a request made at all? Request headers should include `HX-Request: true`. What status and `Content-Type` came back, and is the body HTML (not JSON, not a full page when a fragment was expected)?
5. **Turn on event logging** and reproduce:
   ```js
   // 2.x
   htmx.logAll()
   // 4
   htmx.config.logAll = true        // or <meta name="htmx-config" content="logAll:true">
   ```
   Or watch the lifecycle explicitly:
   ```js
   // 2.x
   ['htmx:configRequest','htmx:beforeRequest','htmx:afterRequest','htmx:beforeSwap','htmx:afterSwap','htmx:responseError','htmx:sendError','htmx:targetError','htmx:swapError']
     .forEach(n => document.body.addEventListener(n, e => console.log(n, e.detail)))
   // 4
   ['htmx:config:request','htmx:before:request','htmx:after:request','htmx:before:swap','htmx:after:swap','htmx:finally:swap','htmx:error','htmx:finally:request']
     .forEach(n => document.body.addEventListener(n, e => console.log(n, e.detail?.ctx?.request?.action, e.detail?.ctx?.response?.status, e.detail)))
   ```
   `monitorEvents(htmx.find('#el'))` in Chrome DevTools shows every DOM event the element receives.

## 2. Symptom → likely cause

### Request never fires
- Wrong default trigger: inputs/selects/textareas fire on `change`, forms on `submit`, everything else on `click`. A `<div>` with `hx-get` and no `hx-trigger` needs a click.
- `hx-trigger="load"` on an element added after page load: it fires on processing, so if the element was inserted without `htmx.process()` nothing happens.
- `hx-sync` on the element or an ancestor is dropping or queuing it; 4.0.0 also queues repeat requests from the same element by default.
- `hx-confirm` (or an `htmx:confirm` listener that called `preventDefault()` without `issueRequest()`) is blocking.
- An ancestor has `hx-disable` (2.x) / `hx-ignore` (4), or 2.x `htmx.config.disableSelector` matches.
- Trigger syntax: multi-word selectors need `from:(closest form)` in 2.x and `from:'closest form'` in 4; 4.0.0 parses polling filters only as `every[cond] 5s`, not `every 5s [cond]`.
- Filters like `click[ctrlKey]` and `hx-on` need `eval`; a strict CSP without `'unsafe-eval'` silently disables them (2.x `allowEval=false` too).
- Event name in `hx-trigger="myEvent from:body"` is camelCase but the attribute was lowercased by the HTML parser, so it listens for `myevent`.

### Swap does not happen
- Status code: 2.x does not swap 4xx/5xx unless `response-targets`, `responseHandling`, or a `beforeSwap` handler sets `shouldSwap`; 4 swaps everything except 204/304 (`noSwap`). A 204 never swaps in either.
- `hx-target` matches nothing: run `document.querySelector(sel)` in the console. Extended selectors (`closest`, `find`, `next`, `previous`) resolve relative to the triggering element, not the document.
- `hx-swap="none"` or `delete`; `hx-select` matching nothing in the response; a listener cancelling `htmx:beforeSwap` / `htmx:before:swap`.
- Response is JSON, or a full page where a fragment was expected (check the server's `HX-Request` branch).
- `HX-Retarget`/`HX-Reswap` response headers, or 4 `hx-status:*` attributes, redirecting the swap.
- 4: `<hx-partial>`-only or OOB-only responses skip the main swap unless `swapEmpty:true`.

### Swapped into the wrong place
- Missing `hx-target` (defaults to the element itself, so a button replaces itself with the response).
- 2.x: `hx-target` inherited from an ancestor you forgot about; 4: the opposite, a parent `hx-target` without `:inherited` so the child falls back to itself.
- `innerHTML` vs `outerHTML` mismatch: a response containing the target element itself, swapped with `innerHTML`, nests it.
- OOB elements with ids that do not exist in the page; `<tr>`/`<li>` OOB fragments without a `<template>` wrapper get dropped by the HTML parser. In 4, OOB runs after the main swap, so OOB targets inside the just-replaced content refer to the new content.

### Swapped content is dead
- Alpine state reset: `x-data` was on (or inside) the swapped element. Move it to an ancestor or morph (`alpine-morph` on 2.x, `outerMorph` + `hx-alpine-compat` on 4).
- Event handlers attached with `addEventListener` to the old nodes are gone; use `hx-on`, delegated listeners on `body`, or `htmx.onLoad(el => …)` to rebind.
- `<script>` tags in swapped content: run by default in both lines (2.x `allowScriptTags`), but need a nonce under CSP (`inlineScriptNonce`).
- `hx-preserve` elements keep the *old* node, including stale attributes.

### Listener never runs
- camelCase in attributes: `hx-on:htmx:afterRequest` and Alpine `@htmx:afterRequest` are lowercased by the parser. Use `hx-on::after-request` / `@htmx:after-request` on 2.x, `hx-on::after:request` / `@htmx:after:request` on 4.
- Listening for a 2.x name on 4 (`htmx:afterRequest` is never dispatched by 4) or a 4 name on 2.x.
- Listening on an element that gets swapped out, or on a child when the event fires on the triggering element; prefer `document.body`.
- `e.detail.successful` only exists in 2.x; in 4 read `e.detail.ctx.response.status`.

### Form data missing
- GET never includes the enclosing form; in 4, DELETE does not either. Add `hx-include="closest form"`.
- `hx-params` (2.x) filtering it out; 4 removed `hx-params`.
- `hx-vals` JSON with single quotes inside the attribute, or a `js:` expression throwing (check the console).
- File inputs without `hx-encoding="multipart/form-data"`.

### 403 / CSRF
- 2.x: `hx-headers` on `<body>` is inherited; check that the token is rendered and not stale after a boosted navigation (put it on `<html>` or inside the swapped region).
- 4: `hx-headers` without `:inherited` on the ancestor sends no header for children. This is the most common post-upgrade 403.
- `htmx:configRequest` / `htmx:config:request` handler registered after the first request, or on the wrong element.

### Polling will not stop
- 2.x: return status 286. 4: 286 does nothing; the interval ends only when the element is removed or replaced (load polling) or its filter is false (`every[!done] 2s` in 4.0.0).
- Polling element re-rendered by its own response with the `hx-trigger` still present.

### Extension seems inactive
- 2.x: script loaded but no `hx-ext="name"` on the element or an ancestor; `hx-ext="ignore:name"` upstream.
- 4: `hx-ext` is gone and ignored; the script must load *after* core; if `htmx.config.extensions` is set it is an allow-list of registration names (`sse`, `preload`, `compat`, not file names); a 2.x `htmx-ext-*` package will not register on 4.

### History / back button
- 2.x restores from a sessionStorage snapshot (`hx-history="false"` excludes a page; `htmx:historyCacheMiss` re-requests). 4 re-requests the page with `HX-History-Restore-Request: true` unless `hx-history-cache` is loaded; `history: "reload"` forces full reloads.
- Pushed URLs must render a full page on direct load; otherwise refresh shows a fragment.
- Alpine state on restored snapshots: 4's `hx-alpine-compat` with `hx-history-cache` serializes it; 2.x needs `Alpine.destroyTree`/`initTree` on `htmx:historyRestore`.

## 3. Report format

1. htmx line detected and how.
2. The failing step in the lifecycle (trigger → request → response → swap → settle), with the evidence (console/network output).
3. Root cause in one or two sentences.
4. The fix as corrected markup or code, and anything to change on the server.
5. One sentence on how to confirm it (which event to watch, which header to check).

If the version is unknown and the fix differs between lines, give both and say so. The `htmx` skill has the full attribute, event and config tables for both lines; `htmx-upgrade` covers planned migrations.
