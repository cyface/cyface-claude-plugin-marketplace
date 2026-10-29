# htmx — Attribute, Config, Event and Header Reference (2.x and 4)

Columns marked **2.x** describe htmx 2.0.11; **4** describes htmx 4.0.0. Unmarked text applies to both.

## Contents

- [Request attributes](#request-attributes)
- [Targeting](#targeting)
- [hx-swap](#hx-swap)
- [hx-trigger](#hx-trigger)
- [Data: hx-vals, hx-include, hx-headers, hx-params, hx-encoding](#data-attributes)
- [UX: indicator, confirm, disable, push-url, boost, preserve](#ux-attributes)
- [hx-sync](#hx-sync)
- [Inheritance](#inheritance)
- [Multi-region: hx-swap-oob, hx-select-oob, hx-partial](#multi-region-updates)
- [hx-select and hx-status](#hx-select-and-hx-status)
- [hx-on](#hx-on)
- [Renamed and removed attributes](#renamed-and-removed-attributes)
- [Events](#events)
- [Configuration](#configuration)
- [Headers](#headers)
- [JavaScript API](#javascript-api)
- [Extensions](#extensions)

---

## Request attributes

| Attribute | Notes |
|-----------|-------|
| `hx-get` `hx-post` `hx-put` `hx-patch` `hx-delete` | Issue the request to the URL. Default trigger: `click`; `change` for `input`/`select`/`textarea`; `submit` for `form`. |
| `hx-query` | **4** only. HTTP QUERY. |
| `hx-action` + `hx-method` | **4** only. Generic URL + verb pair for custom methods. |

Form inclusion: POST/PUT/PATCH include the enclosing form's fields. GET never does. **2.x** DELETE includes them; **4** DELETE does not (add `hx-include="closest form"`). Elements with `name` and `value` submit their own value.

---

## Targeting

`hx-target` accepts a CSS selector or an extended selector:

| Form | Meaning |
|------|---------|
| `#id`, `.class`, `form > div` | Standard selector |
| `this` | The element carrying the attribute |
| `closest <sel>` | Nearest ancestor (or self) matching |
| `find <sel>` | First descendant matching |
| `next [sel]` / `previous [sel]` | Next/previous sibling, optionally matching (scans forward/back through the document) |

Default target is the element itself. **2.x** inherits `hx-target` from ancestors automatically; **4** requires `hx-target:inherited` on the ancestor.

---

## hx-swap

| Style | Effect |
|-------|--------|
| `innerHTML` | Replace children (default; config `defaultSwapStyle` in 2.x, `defaultSwap` in 4) |
| `outerHTML` | Replace the element (2.x downgrades to `innerHTML` on `<body>`; 4 treats `outerHTML` on body as `outerSync`) |
| `textContent` | Set text only |
| `beforebegin` / `afterbegin` / `beforeend` / `afterend` | Insert around or inside; **4** aliases `before` / `prepend` / `append` / `after` |
| `delete` | Remove the target regardless of response |
| `none` | No main swap; OOB, partials and headers still apply |
| `outerSync` | **4**. Morph the target's attributes, replace its children, keep the node (used for boosted `<body>`) |
| `innerMorph` / `outerMorph` | **4**. Built-in idiomorph: preserves focus, input values, video state, Alpine state (with `hx-alpine-compat`) |
| `morph` | **2.x** with the `idiomorph` extension (`hx-ext="morph"`) |

Modifiers (space-separated after the style):

| Modifier | 2.x | 4 |
|----------|-----|---|
| `swap:<time>` | Delay before swap | Same |
| `settle:<time>` | Delay before settle (default 20ms) | Default 1ms |
| `transition:true` | View Transitions API | Same (global: `globalViewTransitions` → `transitions`) |
| `ignoreTitle:true` | Keep the page `<title>` | Same |
| `scroll:top|bottom` | Scroll the target; `scroll:#el:bottom` for another element | `scroll:top|bottom` plus `scrollTarget:<sel>` (the documented `scroll:window:top` is not honored by 4.0.0) |
| `show:top|bottom|none` | Scroll target into view; `show:#el:top`, `show:window:top` | `show:…` plus `showTarget:<sel>` |
| `focus-scroll:true|false` | Scroll to the focused element | Renamed `focusScroll:true` |
| `strip:true|false` | — | Drop (or keep) the response's outer wrapper element |
| `swapEmpty:true` | — | Perform the main swap even when the response was OOB/partial-only |
| `target:<sel>` | — | Retarget inside the swap spec (used by `hx-status`, `hx-boost` overrides) |

**4** morph controls: `hx-morph-skip`, `hx-morph-skip-children` attributes; config `morphIgnore` (default `["data-htmx-powered"]`), `morphSkip`, `morphSkipChildren`, `morphScanLimit`.

The classes `htmx-swapping` (during the `swap:` delay), `htmx-added` and `htmx-settling` exist in both lines and drive CSS exit/enter animations with `swap:500ms`; only the **2.x** config keys that rename them (`swappingClass`, `addedClass`, `settlingClass`, `attributesToSettle`) were removed in 4. `htmx-request` and `htmx-indicator` exist in both.

---

## hx-trigger

```html
hx-trigger="click"
hx-trigger="input changed delay:300ms"
hx-trigger="submit, keyup[key=='Enter']"
hx-trigger="load"
hx-trigger="revealed"
hx-trigger="intersect once root:#scroller threshold:0.5"   <!-- 4 adds rootMargin: -->
hx-trigger="every 10s [!document.hidden]"      <!-- 2.x form; in 4.0.0 write every[!document.hidden] 10s, see below -->
hx-trigger="contactsChanged from:body"          <!-- paired with the HX-Trigger response header -->
```

| Modifier | 2.x | 4 |
|----------|-----|---|
| `once` | ✓ | ✓ |
| `changed` | ✓ | ✓ |
| `delay:<t>` (debounce) | ✓ | ✓ |
| `throttle:<t>` | ✓ | ✓ |
| `from:<sel>` (`document`, `window`, `closest …`, `find …`, `next`, `previous`) | ✓ | ✓ plus `self`, `outside` |
| `target:<sel>` (only when `event.target` matches) | ✓ | ✓ |
| `consume` (stop propagation) | ✓ | ✓, alias `stop` |
| `queue:first|last|all|none` | ✓ (default `last`) | Removed: use `hx-sync` |
| `prevent`, `halt` (= prevent + stop), `capture`, `passive` | — | ✓ |

Selectors containing spaces or commas: **2.x** wraps them in parentheses or braces, `from:(closest form)`; **4** uses single quotes, `from:'closest form'`, `target:'.a, .b'`.

Filters are JavaScript in brackets (`click[ctrlKey && !shiftKey]`) and need `eval` (see CSP under Security in SKILL.md).

Polling: **2.x** `every 5s [filter]`; **4.0.0** parses the filter only on the event token, `every[filter] 5s` (the documented `every 5s [filter]` form is silently ignored). **2.x** stops when the server answers **286**. **4** stops only when the polling element leaves the DOM or the filter is false; `htmx:abort` cancels the in-flight fetch but not the interval, so load polling (re-render without the trigger) is the reliable stop.

---

## Data attributes

### hx-vals

```html
<button hx-post="/api" hx-vals='{"type": "draft"}'>                 <!-- JSON (both) -->
<button hx-post="/api" hx-vals="type:draft, priority:1">            <!-- HCON, 4 only -->
<input hx-post="/api" hx-vals='js:{value: event.target.value}'>     <!-- computed; 4 may return a Promise -->
<button hx-post="/api" :hx-vals="JSON.stringify({ id: selectedId })"> <!-- Alpine -->
```

**4**: `hx-vals:append` merges with an inherited value instead of overriding. `hx-vars` (2.x, deprecated) is removed in 4.

### hx-include

`hx-include="#token"`, `hx-include="closest form"`, `hx-include="[name='q'], #filters"`. **2.x** (2.0.5+) `hx-include="inherit, #extra"` extends a parent's value; **4** `hx-include:inherited:append="…"`.

### hx-headers

Same shapes as `hx-vals`. Put auth or CSRF headers on `<body>`: **2.x** `hx-headers='{…}'`, **4** `hx-headers:inherited='{…}'`.

### hx-params

**2.x** only: `*`, `none`, `name,email`, `not password`. In **4** filter the `FormData` in `htmx:config:request` (`evt.detail.ctx.request.body.delete('password')`).

### hx-encoding

`hx-encoding="multipart/form-data"` for file uploads. Forms with `<input type="file">` are detected in both lines, but set it explicitly.

### hx-validate

Run HTML5 validation before a non-form element's request. **2.x** also fires `htmx:validation:*` events; **4** uses native validation only.

---

## UX attributes

| Attribute | 2.x | 4 |
|-----------|-----|---|
| `hx-indicator="<sel>"` | Adds `htmx-request` to the matched element(s); `.htmx-indicator` inside become visible. `hx-indicator="inherit, #x"` to extend | Same, `:inherited` to share |
| `hx-confirm="text"` | `window.confirm`; intercept with the `htmx:confirm` event | Also `js:` async expressions; `htmx:confirm` detail has `issueRequest`/`dropRequest` |
| Disable elements during a request | `hx-disabled-elt="this"`, `"find button"`, `"closest form"`; `inherit` keyword | **`hx-disable="this"`** (renamed) |
| Stop htmx processing a subtree | `hx-disable` | **`hx-ignore`** (renamed) |
| `hx-push-url="true|<url>|false"` | ✓ | ✓ |
| `hx-replace-url` | ✓ | ✓ |
| `hx-boost="true"` | Boosts descendants automatically; `hx-boost="false"` opts out | Needs `hx-boost:inherited="true"` for descendants; per-element overrides `hx-boost="swap:beforeend target:#modals select:#main"`; responses replace the `<body>` content (docs describe this as `outerSync`) |
| `hx-preserve` | Keep an element across swaps (by id) | Same; `hx-preserve="true"` also survives boosted navigations |
| `hx-prompt="text"` | Sends the answer as `HX-Prompt` | Moved to the `hx-prompt` extension |
| `hx-history="false"` | Exclude the page from the history cache | Only meaningful with the `hx-history-cache` extension |
| `hx-history-elt` | Element snapshotted for history | ✓ |
| `hx-request='{"timeout":5000}'` | Per-element request options | Renamed `hx-config` (HCON): `timeout`, `credentials`, `cache`, `redirect`, `referrer`, `integrity`, `validate` |

Not boosted in either version: cross-origin links, `#` anchors, `target="_blank"`; 4 also skips `download` links.

---

## hx-sync

`hx-sync="<selector>:<strategy>"`; the selector is usually `this` or `closest form`.

| Strategy | Behavior |
|----------|----------|
| `drop` (default) | Ignore the new request while one is in flight |
| `abort` | Abort the in-flight request if a new one arrives |
| `replace` | Abort the in-flight request and issue the new one |
| `queue first` / `queue last` / `queue all` | Queue requests |

Same syntax in both lines; `hx-sync:inherited` in **4** to apply to descendants. Note that 4.0.0 queues repeat requests from the same element (`queue first`) when no strategy is given, where 2.x runs them concurrently, so set the strategy explicitly when it matters.

---

## Inheritance

- **2.x**: most attributes (`hx-target`, `hx-swap`, `hx-include`, `hx-headers`, `hx-confirm`, `hx-indicator`, `hx-boost`, `hx-sync`, `hx-encoding`, `hx-push-url`, `hx-select`, `hx-vals`…) inherit from ancestors; `hx-on` and `hx-trigger` do not. Control with `hx-disinherit="hx-target hx-swap"` / `hx-disinherit="*"` on the parent, or opt in globally with `htmx.config.disableInheritance=true` + `hx-inherit="hx-target"`. `unset` as a value cancels inheritance for one attribute.
- **4**: nothing inherits unless the ancestor's attribute carries `:inherited`. The child's own value wins; `:append` merges instead (`hx-include:inherited:append`). `hx-inherit`, `hx-disinherit`, `unset` and `disableInheritance` are gone. `htmx.config.implicitInheritance=true` restores 2.x behavior for migration.

---

## Multi-region updates

### hx-swap-oob (in the response)

```html
<div id="main">Primary content</div>
<span id="count" hx-swap-oob="true">7</span>                 <!-- outerHTML by id -->
<ul id="log" hx-swap-oob="beforeend"><li>Appended</li></ul>  <!-- 2.x: swap style; children appended -->
<tbody hx-swap-oob="beforeend:#rows"><tr>…</tr></tbody>      <!-- 4: style:selector; wrapper stripped -->
```

- The target id must already exist in the page.
- Wrap `<tr>`, `<td>`, `<li>` and similar in `<template>` so the HTML parser does not drop them.
- Order: **2.x** OOB swaps run *before* the main swap; **4** runs the main swap first, then `hx-select-oob` and `hx-swap-oob` elements, then `<hx-partial>`s. **4** skips the (empty) main swap when the response is OOB-only unless `swapEmpty:true` / `allowEmptySwapAfterOOB`.

### hx-select-oob (on the requesting element)

Pick elements out of the response and OOB-swap them: `hx-select-oob="#count, #toasts:afterbegin"`.

### `<hx-partial>` (4, and 2.0.11+)

```html
<hx-partial hx-target="#messages" hx-swap="beforeend">…</hx-partial>
<hx-partial id="count">7</hx-partial>                     <!-- id= is shorthand for hx-target="#count" -->
<template hx type="partial" hx-target="closest li">…</template>   <!-- table/list-safe fallback (the source matches template[hx][type=partial]; docs write hx-type) -->
```

`hx-target` resolves relative to the triggering element, so `closest tr` and `next .error` work. Default swap `innerHTML`. A partial-only response skips the main swap unless `swapEmpty:true` is set. **2.x** processes partials before the main swap and fires `htmx:partialBeforeSwap` / `htmx:partialAfterSwap` / `htmx:partialErrorNoTarget`.

---

## hx-select and hx-status

- `hx-select="#results"` swaps only the matching part of the response (useful with full-page responses and `hx-boost`).
- **4** `hx-status:<code>="swap:… target:… select:… push:… replace:… transition:…"` per status, with `50x` and `5xx` wildcards (exact code wins, then `NNx`, then `Nxx`). Replaces the 2.x `response-targets` extension (`hx-target-422`, `hx-target-5*`, `hx-target-error`).

---

## hx-on

```html
<!-- 2.x: attribute names are case-insensitive, so htmx events must be kebab-case -->
<button hx-on:click="…" hx-on::after-request="…" hx-on:htmx:after-request="…">
<!-- legacy dash forms also work in 2.x: hx-on-htmx-after-request, hx-on--after-request -->

<!-- 4: colon names are already lowercase -->
<button hx-on:click="…" hx-on::after:request="…">
<!-- 4 trigger-grammar form: needed for camelCase custom events and modifiers -->
<button hx-on="click[shiftKey] once -> doThing(); myCustomEvent -> other()">
```

Scope inside handlers: `this` (the element), `event`; **4** also unpacks `event.detail` (so `ctx` is in scope), exposes htmx API functions without the prefix (`find()`, `trigger()`), and allows top-level `await`. `hx-on` is never inherited.

---

## Renamed and removed attributes

| 2.x | 4 |
|-----|---|
| `hx-disable` (ignore subtree) | `hx-ignore` |
| `hx-disabled-elt` | `hx-disable` |
| `hx-request` | `hx-config` |
| `hx-vars` | `hx-vals='js:…'` |
| `hx-params` | removed (filter in `htmx:config:request`) |
| `hx-prompt` | `hx-prompt` extension |
| `hx-ext` | removed (loading the script activates the extension) |
| `hx-inherit`, `hx-disinherit` | removed (`:inherited` suffix) |
| `hx-history` | only with `hx-history-cache` extension |

Rename `hx-disable` → `hx-ignore` **before** `hx-disabled-elt` → `hx-disable` when migrating.

---

## Events

**2.x** names are camelCase and each is also dispatched kebab-case (`htmx:afterRequest` and `htmx:after-request`). **4** names are `htmx:<phase>:<action>` and dispatched once.

| Purpose | 2.x | 4 |
|---------|-----|---|
| Confirm hook | `htmx:confirm` | `htmx:confirm` (`detail.issueRequest()` / `dropRequest()`) |
| Configure request | `htmx:configRequest` (`detail.headers`, `detail.parameters`, `detail.path`) | `htmx:config:request` (`detail.ctx.request.{headers,body,action,method}`) |
| Before send | `htmx:beforeRequest`, `htmx:beforeSend` | `htmx:before:request` |
| Response received | — | `htmx:before:response` |
| After request | `htmx:afterRequest` (`detail.successful`, `detail.xhr`) | `htmx:after:request` (`detail.ctx.response.{status,headers}`, `ctx.text`) |
| Always after | — | `htmx:finally:request` |
| HTTP error | `htmx:responseError` | `htmx:response:error` |
| Network/abort/timeout/swap/target errors | `htmx:sendError`, `htmx:sendAbort`, `htmx:timeout`, `htmx:swapError`, `htmx:targetError` | `htmx:error` |
| Before swap | `htmx:beforeSwap` (`detail.shouldSwap`, `detail.target`), `htmx:oobBeforeSwap` | `htmx:before:swap` (`detail.tasks`) |
| After swap | `htmx:afterSwap`, `htmx:oobAfterSwap` | `htmx:after:swap`, then `htmx:finally:swap` |
| Settle | `htmx:afterSettle` | `htmx:before:settle`, `htmx:after:settle` |
| New content initialized | `htmx:load`, `htmx:afterOnLoad` | `htmx:after:init` (`htmx.onLoad()` listens to `htmx:after:process`) |
| Node processing | `htmx:beforeProcessNode`, `htmx:afterProcessNode` | `htmx:before:process`, `htmx:after:process` |
| Cleanup | `htmx:beforeCleanupElement` | `htmx:before:cleanup`, `htmx:after:cleanup` |
| History | `htmx:beforeHistorySave`, `htmx:pushedIntoHistory`, `htmx:replacedInHistory`, `htmx:historyRestore`, `htmx:historyCacheMiss` | `htmx:before:history:update`, `htmx:after:history:update`, `htmx:after:history:push`, `htmx:after:history:replace`, `htmx:before:history:restore` |
| View transitions | `htmx:beforeTransition` | `htmx:before:viewTransition`, `htmx:after:viewTransition` (the only camelCase names) |
| Partials (2.0.11+) | `htmx:partialBeforeSwap`, `htmx:partialAfterSwap`, `htmx:partialErrorNoTarget` | folded into swap events |
| Abort a request | dispatch `htmx:abort` on the element | same |
| Removed in 4 | `htmx:validation:*`, `htmx:xhr:*`, `htmx:validateUrl`, `htmx:prompt` | — |

---

## Configuration

Set via `<meta name="htmx-config" content='{…}'>` (4 also accepts HCON: `content="defaultSwap:outerHTML, logAll:true"`) or `htmx.config.x = …` before use.

| 2.x | 4 | Notes |
|-----|---|-------|
| `defaultSwapStyle` `innerHTML` | `defaultSwap` `innerHTML` | |
| `defaultSwapDelay` 0, `defaultSettleDelay` 20 | `defaultSettleDelay` 1 | |
| `timeout` 0 | `defaultTimeout` 60000 | 4 times out requests after a minute by default |
| `globalViewTransitions` false | `transitions` false | |
| `historyEnabled` true, `historyCacheSize` 10, `refreshOnHistoryMiss` false | `history` true \| `"reload"` \| false | 4 has no snapshot cache unless `hx-history-cache` is loaded |
| `includeIndicatorStyles` | `includeIndicatorCSS` | |
| `selfRequestsOnly` true | `mode` `"same-origin"` | fetch mode; `"cors"` for cross-origin |
| `allowEval` true, `allowScriptTags` true | removed | 4 always evals `hx-on`/filters/`js:`; use the `hx-csp` extension to avoid `unsafe-eval` |
| `inlineScriptNonce`, `inlineStyleNonce` | `inlineScriptNonce` | |
| `disableInheritance` false, `disableSelector` | `implicitInheritance` false | |
| `responseHandling` array | `noSwap` `[204, 304]` | add `'4xx','5xx'` to restore 2.x |
| `attributesToSettle`, `addedClass`, `settlingClass`, `swappingClass` | removed | |
| `withCredentials`, `getCacheBusterParam`, `methodsThatUseUrlParams`, `scrollBehavior`, `scrollIntoViewOnBoost`, `ignoreTitle`, `triggerSpecsCache`, `useTemplateFragments`, `wsReconnectDelay`, `wsBinaryType`, `historyRestoreAsHxRequest`, `reportValidityOfForms` | removed | |
| `indicatorClass`, `requestClass`, `defaultFocusScroll` | same | |
| `allowNestedOobSwaps` true | removed | |
| — | `prefix` `"data-hx-"` (additive), `metaCharacter`, `extensions` (whitelist), `logAll`, `allowEmptySwapAfterOOB`, `morph*` | |

---

## Headers

Request (browser → server):

| Header | 2.x | 4 |
|--------|-----|---|
| `HX-Request: true` | ✓ | ✓ |
| `HX-Current-URL` | ✓ | ✓ |
| `HX-Target` | element id | `tag#id` |
| `HX-Trigger` / `HX-Trigger-Name` | id / name of the triggering element | replaced by `HX-Source` (`tag#id`) |
| `HX-Request-Type` | — | `partial` or `full` (body target or `hx-select`) |
| `HX-Boosted` | ✓ | ✓ |
| `HX-History-Restore-Request` | ✓ | ✓ |
| `HX-Prompt` | ✓ | via `hx-prompt` extension |

Response (server → browser): `HX-Trigger` (event name or JSON `{"evt": detail}`), `HX-Retarget`, `HX-Reswap`, `HX-Reselect`, `HX-Push-Url`, `HX-Replace-Url`, `HX-Redirect` (full page), `HX-Location` (AJAX navigation; JSON `{"path":…, "target":…, "swap":…}`), `HX-Refresh`. **2.x** only: `HX-Trigger-After-Swap`, `HX-Trigger-After-Settle`. **2.x** only: status **286** stops polling.

---

## JavaScript API

| 2.x | 4 |
|-----|---|
| `htmx.ajax('GET', '/url', { target, swap, values })` returns a Promise | same |
| `htmx.process(el)` | same (needed for markup inserted by Alpine or other JS) |
| `htmx.on/off`, `htmx.trigger`, `htmx.find/findAll`, `htmx.onLoad` | `htmx.on`, `htmx.trigger`, `htmx.find/findAll`, `htmx.onLoad` (`off` removed: use `removeEventListener`) |
| `htmx.addClass/removeClass/toggleClass/takeClass`, `htmx.closest`, `htmx.remove`, `htmx.values` | removed: use `classList`, `el.closest`, `el.remove()`, `new FormData(form)` |
| `htmx.defineExtension` | `htmx.registerExtension` |
| `htmx.logger`, `htmx.logAll()` | `htmx.config.logAll = true` |
| `htmx.parseInterval` | same, plus `htmx.swap(ctx)`, `htmx.timeout(ms)`, `htmx.initialize()` |

---

## Extensions

### 2.x

Separate packages, loaded after core and enabled with `hx-ext` (inherited; `hx-ext="ignore:name"` disables in a subtree):

```html
<script src="https://cdn.jsdelivr.net/npm/htmx-ext-sse@2.2.4"></script>
<body hx-ext="sse">
```

Core (maintained by the htmx team): `head-support`, `htmx-1-compat`, `idiomorph` (`hx-ext="morph"`, `hx-swap="morph"`), `preload`, `response-targets`, `sse`, `ws`.
Community (notable): `alpine-morph`, `class-tools`, `json-enc`, `loading-states`, `path-deps`, `remove-me`, `multi-swap`, `client-side-templates`, `restored`, `safe-nonce`. `loading-states` and `path-deps` have no htmx 4 port; core `hx-disabled-elt`/`hx-indicator` and `HX-Trigger` + `hx-trigger="evt from:body"` cover the same needs portably.

### 4

All official extensions ship inside `htmx.org@4.0.0/dist/ext/<name>.js`; including the script activates it. Optional allow-list: `<meta name="htmx-config" content='{"extensions": "sse, preload"}'>` using registration names (`hx-sse.js` → `sse`, `hx-preload.js` → `preload`, `htmx-2-compat.js` → `compat`). The `htmax.js` bundle packs core plus the most common extensions.

| Extension | Purpose |
|-----------|---------|
| `hx-sse` | `hx-sse:connect="/events"`, `hx-sse:close="done"`; named events become DOM events (`hx-trigger="progress from:body"`). Any `hx-get` whose response is `text/event-stream` streams |
| `hx-ws` | `hx-ws:connect`, `hx-ws:send`; messages swap into the connect element's target |
| `hx-multipart` | `multipart/mixed` streaming responses |
| `hx-preload` | `hx-preload="mousedown|mouseover|<event>"`, `timeout:2s`; sends `HX-Preloaded: true` |
| `hx-ptag` | Skip unchanged polls via `HX-PTag` |
| `hx-history-cache` | 2.x-style sessionStorage snapshots; `hx-history="false"` to exclude |
| `hx-pending`, `hx-browser-indicator`, `hx-live` | Pending-state attributes, browser-native loading indicator, reactive scripting layer |
| `hx-head` | Merge `<head>` from responses (was `head-support`) |
| `hx-upsert`, `hx-targets`, `hx-download` | Update-or-insert by id, multi-target swaps, file download swap |
| `hx-prompt` | Restores `hx-prompt` and the `HX-Prompt` header |
| `hx-alpine-compat` | Defers Alpine initialization until settle, carries `x-data` state through morphs, serializes Alpine state into history snapshots |
| `hx-csp` | Per-element `hx-nonce`, blocks `javascript:` URLs, Trusted Types, `safeEval:true` to drop `unsafe-eval` |
| `htmx-2-compat` | Implicit inheritance, no-swap on 4xx/5xx, re-fires old event names during migration |

2.x extensions do not load in 4; the authoring API is hook-based (`htmx.registerExtension('name', { init(api) {}, htmx_config_request(elt, detail) {}, handle_swap(…) {} })`).
