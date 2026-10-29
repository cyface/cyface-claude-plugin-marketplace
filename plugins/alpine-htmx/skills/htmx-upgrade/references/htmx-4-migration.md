# Migrating from htmx 2.x to htmx 4

htmx 4 is a ground-up rewrite (fetch-based, explicit inheritance, new event names). This is the practical worklist, adapted from the upgrade guidance htmx ships in its own package (`htmx.org@4.0.0/dist/skills/htmx-upgrade-from-htmx2.md`) and https://four.htmx.org/docs#migrating-from-htmx-2x-to-4x.

## When to migrate

- htmx 2.x stays supported indefinitely and remains npm `latest` until 2027; there is no deadline.
- Migrate when you want built-in morphing, `<hx-partial>`, streaming, `hx-status`, stricter inheritance (a security win), or want to stay on the line the maintainers document first.
- Hold off if you depend on community 2.x extensions with no 4 port (`loading-states`, `path-deps`, `client-side-templates`, `json-enc`, `class-tools`): every extension needs a rewrite for 4.

## Workflow for Claude

1. Inventory: grep for `hx-`, `data-hx-`, `htmx:` listeners, `htmx.` API calls, `HX-` header handling in server code, and extension scripts.
2. Run the shipped checker to get a `file:line` worklist:
   ```bash
   npx htmx.org@4.0.0 upgrade-check -- ./templates
   npx htmx.org@4.0.0 upgrade-check --ext .vue -- ./src     # extra extensions (default: .html .php .js .ts .jinja .jinja2 .j2 .erb .hbs)
   ```
3. Work through the steps below file by file; it does not rewrite anything.
4. Do the `hx-disable` → `hx-ignore` rename **before** `hx-disabled-elt` → `hx-disable`.
5. For inheritance, analyze which parents actually feed children instead of adding `:inherited` everywhere.
6. Check server middleware for header changes and status-code behavior.
7. Decide on the compatibility bridges only for incremental migrations.

## Step 1: swap the script and pin the version

```html
<script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0" integrity="sha384-BvJpBiO8Kh31EqtJe5DRIeWrHWnCGkwytKs9NKFi86Hhw96dEqdEMzZDeK9iEGTc" crossorigin="anonymous"></script>
```

`npm install htmx.org@4.0.0` (the `latest` tag still resolves to 2.x). Extensions now come from `htmx.org/dist/ext/*.js`; delete `htmx-ext-*` packages.

## Step 2: attribute renames (order matters)

| Find | Replace with |
|------|--------------|
| `hx-disable` (stop processing a subtree) | `hx-ignore` — **do this first** |
| `hx-disabled-elt` | `hx-disable` |
| `hx-request='…'` | `hx-config='…'` (HCON, accepts the old JSON) |
| `hx-vars='…'` | `hx-vals='js:…'` |
| `hx-params="…"` | remove; filter in `htmx:config:request` (`ctx.request.body.delete('x')`) |
| `hx-prompt="…"` | keep, but load the `hx-prompt` extension |
| `hx-ext="…"` | remove; loading the extension script is enough |
| `hx-inherit`, `hx-disinherit`, `unset` values | remove; see Step 3 |
| `hx-history="false"` | remove unless you load `hx-history-cache` |

`data-hx-*` needs no change: `htmx.config.prefix` defaults to `data-hx-` and is additive.

## Step 3: make inheritance explicit

In 2.x every child inherited `hx-target`, `hx-swap`, `hx-include`, `hx-headers`, `hx-confirm`, `hx-indicator`, `hx-boost`, `hx-sync`, `hx-encoding`, `hx-push-url`, `hx-select`, `hx-vals`, `hx-request` (now `hx-config`), `hx-validate` from ancestors. In 4 the ancestor must say so:

```html
<!-- 2.x -->
<div hx-target="#out" hx-headers='{"X-Token": "abc"}'>
  <button hx-get="/a">A</button>
</div>

<!-- 4 -->
<div hx-target:inherited="#out" hx-headers:inherited='{"X-Token": "abc"}'>
  <button hx-get="/a">A</button>
</div>
```

How to find them: for each inheritable attribute, look for elements that carry it but have no `hx-get/post/put/patch/delete` of their own. Those are inheritance parents. `hx-boost="true"` on anything that is not a link or form is always meant for descendants (`hx-boost:inherited="true"`). Children override inherited values; use `:append` to extend (`hx-include:inherited:append="[name=extra]"`).

Escape hatch for large codebases: `htmx.config.implicitInheritance = true`.

## Step 4: event names

JavaScript, `hx-on:`, and `hx-trigger="… from:body"` references all change:

| 2.x | 4 |
|-----|---|
| `htmx:configRequest` | `htmx:config:request` |
| `htmx:beforeRequest`, `htmx:beforeSend` | `htmx:before:request` |
| `htmx:afterRequest` | `htmx:after:request` |
| `htmx:beforeSwap`, `htmx:oobBeforeSwap` | `htmx:before:swap` |
| `htmx:afterSwap`, `htmx:oobAfterSwap` | `htmx:after:swap` |
| `htmx:afterSettle` | `htmx:after:settle` |
| `htmx:load`, `htmx:afterOnLoad` | `htmx:after:init` |
| `htmx:beforeOnLoad` | `htmx:before:init` |
| `htmx:beforeProcessNode` / `afterProcessNode` | `htmx:before:process` / `htmx:after:process` |
| `htmx:beforeCleanupElement` | `htmx:before:cleanup` |
| `htmx:beforeHistorySave`, `htmx:beforeHistoryUpdate` | `htmx:before:history:update` |
| `htmx:historyCacheMiss`, `htmx:historyRestore` | `htmx:before:history:restore` |
| `htmx:pushedIntoHistory` / `replacedInHistory` | `htmx:after:history:push` / `htmx:after:history:replace` |
| `htmx:beforeTransition` | `htmx:before:viewTransition` |
| `htmx:responseError` | `htmx:response:error` |
| `htmx:sendError`, `sendAbort`, `swapError`, `targetError`, `timeout` | `htmx:error` |
| `htmx:validation:*`, `htmx:xhr:*`, `htmx:validateUrl` | removed |

Alpine listeners move from kebab-case (`@htmx:after-request`) to the colon names verbatim (`@htmx:after:request`). The 2.x kebab aliases are not dispatched by 4.

## Step 5: event handler code

```js
// 2.x
document.addEventListener('htmx:configRequest', evt => {
  evt.detail.headers['X-Custom'] = 'v'
  evt.detail.parameters['key'] = 'v'
  evt.detail.path = '/other'
})
document.addEventListener('htmx:afterRequest', evt => { if (evt.detail.successful) … })

// 4
document.addEventListener('htmx:config:request', evt => {
  const ctx = evt.detail.ctx
  ctx.request.headers['X-Custom'] = 'v'
  ctx.request.body.set('key', 'v')        // FormData
  ctx.request.action = '/other'
})
document.addEventListener('htmx:after:request', evt => { if (evt.detail.ctx.response.status < 400) … })
```

`ctx` also exposes `sourceElement`, `target`, `swap`, `select`, `push`, `replace`, `response.{status,headers}`, `text`, `title`.

## Step 6: configuration

| 2.x | 4 |
|-----|---|
| `defaultSwapStyle` | `defaultSwap` |
| `globalViewTransitions` | `transitions` |
| `historyEnabled` | `history` (`true` \| `"reload"` \| `false`) |
| `includeIndicatorStyles` | `includeIndicatorCSS` |
| `timeout` (0) | `defaultTimeout` (60000) |
| `selfRequestsOnly` | `mode: "same-origin"` |
| `responseHandling` | `noSwap: [204, 304]` |
| `disableInheritance` | `implicitInheritance` |

Removed with no equivalent: `refreshOnHistoryMiss`, `historyCacheSize`, `defaultSwapDelay`, `addedClass`, `settlingClass`, `swappingClass`, `allowEval`, `allowScriptTags`, `attributesToSettle`, `useTemplateFragments`, `wsReconnectDelay`, `wsBinaryType`, `disableSelector`, `withCredentials`, `scrollBehavior`, `getCacheBusterParam`, `methodsThatUseUrlParams`, `ignoreTitle`, `scrollIntoViewOnBoost`, `triggerSpecsCache`, `historyRestoreAsHxRequest`, `reportValidityOfForms`.

## Step 7: server-side changes

- `HX-Trigger` request header → `HX-Source` and now carries `tag#id` (`button#save`); `HX-Trigger-Name` removed; `HX-Target` is also `tag#id`.
- New `HX-Request-Type: partial|full`; add it to `Vary` when caching.
- `HX-Trigger-After-Swap` and `HX-Trigger-After-Settle` response headers removed; use `HX-Trigger`.
- `HX-Prompt` only arrives with the `hx-prompt` extension.
- **286 no longer stops polling.** Switch to load polling (render the next poll trigger only while work continues) or a trigger filter.
- **4xx/5xx now swap.** If your error pages are full HTML, either set `noSwap: [204, 304, '4xx', '5xx']`, add `hx-status:5xx="swap:none"`, or return proper fragments (422 with the re-rendered form is now the easy path).
- `hx-delete` no longer includes the enclosing form; add `hx-include="closest form"` where delete buttons relied on hidden inputs.
- OOB swaps now run after the main swap, and OOB-only responses no longer clear the main target (`allowEmptySwapAfterOOB` or `swapEmpty:true`).

## Step 8: JavaScript API

| 2.x | 4 |
|-----|---|
| `htmx.defineExtension` | `htmx.registerExtension` |
| `htmx.addClass/removeClass/toggleClass` | `el.classList.*` |
| `htmx.closest`, `htmx.remove`, `htmx.off`, `htmx.values` | `el.closest`, `el.remove()`, `removeEventListener`, `new FormData(form)` |
| `htmx.logger = …`, `htmx.logAll()` | `htmx.config.logAll = true` |

## Step 9: extensions

Core 4 extensions (same package, `dist/ext/`): `hx-sse`, `hx-ws`, `hx-multipart`, `hx-preload`, `hx-ptag`, `hx-history-cache`, `hx-head` (was `head-support`), `hx-prompt`, `hx-pending`, `hx-browser-indicator`, `hx-live`, `hx-upsert`, `hx-targets`, `hx-download`, `hx-alpine-compat`, `hx-csp`, `htmx-2-compat`. Morphing is built in (`hx-swap="outerMorph"`), so drop `idiomorph`/`alpine-morph` (load `hx-alpine-compat` to carry Alpine state through morphs). `response-targets` becomes `hx-status:*`. `sse-connect`/`sse-close`/`ws-connect`/`ws-send` become `hx-sse:connect`/`hx-sse:close`/`hx-ws:connect`/`hx-ws:send` (the old names still work with a warning); `sse-swap` is removed (it warns and does nothing) and becomes `hx-trigger="<event> from:body"` plus a request, or a streaming `hx-get`.

Custom extensions must be rewritten against the hook API:

```js
htmx.registerExtension('my-ext', {
  init(api) {},
  htmx_config_request(elt, detail) { /* detail.ctx */ },
  htmx_after_request(elt, detail) { /* detail.ctx.text */ },
})
```

Optional allow-list: `<meta name="htmx-config" content='{"extensions": "sse, my-ext"}'>` (registration names, not file names).

## Compatibility bridges (temporary)

```html
<meta name="htmx-config" content='{"implicitInheritance": true, "noSwap": [204, 304, "4xx", "5xx"]}'>
<script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/htmx.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/ext/htmx-2-compat.js"></script>
```

`htmx-2-compat` turns on implicit inheritance, restores no-swap on 4xx/5xx, logs where implicit inheritance was relied on, and re-fires the old camelCase event names alongside the new ones (`htmx.config.compat.doNotTriggerOldEvents`, `suppressInheritanceLogs` to tune). It does not restore removed attributes such as `hx-ext` or `hx-params`. Treat it as scaffolding to remove once the steps above are done.

## Verification

- Re-run `upgrade-check` until it is clean.
- `htmx.config.logAll = true` in the console and exercise each interaction; check `htmx:error` events.
- Confirm CSRF headers still arrive (the most common post-migration 403 is a missing `:inherited`).
- Confirm error responses render as intended now that 4xx/5xx swap.
- Confirm any `every` polling stops the way you expect, and that filters use the `every[filter] 5s` form 4.0.0 actually parses.
