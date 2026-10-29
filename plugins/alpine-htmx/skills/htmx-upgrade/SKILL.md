---
name: htmx-upgrade
description: >-
  Step-by-step migration of a codebase from htmx 2.x to htmx 4. Use this skill
  whenever the user asks to upgrade, migrate, port, convert or modernize htmx
  code, mentions htmx 4 or "the fetchening", pastes a template asking for the
  htmx 4 version, asks what would change or whether they should move to htmx 4
  at all, or asks why things broke after bumping to 4 and wants the whole
  codebase fixed rather than one symptom diagnosed. Covers the shipped
  upgrade-check CLI, attribute renames in the right order, explicit :inherited
  inheritance, event-name and event.detail changes, config and header renames,
  4xx/5xx swapping, extension rewrites, and the compatibility bridges. For
  writing new htmx markup use the htmx skill; for one failing page use htmx-debug.
argument-hint: "[path to templates or project root]"
---

# Upgrade htmx 2.x to htmx 4

htmx 4.0.0 (stable 2026-08-28) is a ground-up rewrite. htmx 2.x remains npm `latest` and supported indefinitely, so this is a deliberate migration, not a forced one. The full worklist with every rename table lives in **`references/htmx-4-migration.md`**; read it before touching files.

## Decide first

Recommend migrating when the project wants built-in morphing, `<hx-partial>`, streaming responses, `hx-status`, or stricter inheritance, and when its extensions have 4 ports. Recommend staying on 2.x when it depends on community extensions with no 4 port (`loading-states`, `path-deps`, `client-side-templates`, `json-enc`, `class-tools`) or when nobody can test every htmx interaction afterwards. Say which you recommend and why; do not start rewriting until the user agrees.

## Workflow

1. **Inventory.** Grep the project (`$ARGUMENTS` if given, else the templates directory) for `hx-`, `data-hx-`, `htmx:` listeners, `htmx.` API calls, `HX-` headers in server code, and extension `<script>` tags. Count files; report the scope.
2. **Run the shipped checker** and use its output as the worklist. It only reports, never rewrites:
   ```bash
   npx htmx.org@4.0.0 upgrade-check -- ./templates
   npx htmx.org@4.0.0 upgrade-check --ext .vue -- ./src   # add extensions it does not scan by default
   ```
3. **Swap the script** to a pinned 4.0.0 tag; move extensions to `htmx.org@4.0.0/dist/ext/*.js` and delete `htmx-ext-*` packages.
4. **Rename attributes in the right order**: `hx-disable` → `hx-ignore` *first*, then `hx-disabled-elt` → `hx-disable`; `hx-request` → `hx-config`; `hx-vars` → `hx-vals='js:…'`; drop `hx-ext`, `hx-inherit`, `hx-disinherit`, `hx-params`; load the `hx-prompt` extension for `hx-prompt`.
5. **Make inheritance explicit.** For each inheritable attribute (`hx-target`, `hx-swap`, `hx-include`, `hx-headers`, `hx-confirm`, `hx-indicator`, `hx-boost`, `hx-sync`, `hx-encoding`, `hx-push-url`, `hx-select`, `hx-vals`, `hx-config`), find elements that carry it but issue no request of their own: those are inheritance parents and need `:inherited`. CSRF headers on `<body>` are the one everyone misses.
6. **Rename events** in JS, `hx-on:`, and `hx-trigger="… from:body"`: `htmx:afterRequest` → `htmx:after:request`, `configRequest` → `config:request`, `beforeSwap`/`afterSwap`/`afterSettle` → `before:swap`/`after:swap`/`after:settle`, `load` → `after:init`, `responseError` → `response:error`, send/swap/target/timeout errors → `htmx:error`. Alpine listeners move from `@htmx:after-request` to `@htmx:after:request`.
7. **Rewrite handler bodies** to `evt.detail.ctx`: `ctx.request.headers`, `ctx.request.body` (FormData), `ctx.request.action`, `ctx.response.status` (no `successful` flag; no `.ok`).
8. **Config and server**: rename config keys (`defaultSwapStyle` → `defaultSwap`, `timeout` → `defaultTimeout`, `globalViewTransitions` → `transitions`, `historyEnabled` → `history`, `selfRequestsOnly` → `mode`); read `HX-Source` instead of `HX-Trigger` (now `tag#id`); drop `HX-Trigger-After-*`; replace 286 polling stops with load polling; decide how 4xx/5xx should swap (`noSwap` or `hx-status`); add `hx-include="closest form"` to delete buttons that relied on form fields; check OOB ordering assumptions.
9. **Extensions**: 2.x extensions do not load in 4. Replace `response-targets` with `hx-status`, `idiomorph`/`alpine-morph` with `outerMorph` (+ `hx-alpine-compat`), `sse`/`ws` attributes with `hx-sse:*`/`hx-ws:*`. Custom extensions need a rewrite against `htmx.registerExtension`.
10. **Verify**: re-run `upgrade-check` until clean, set `htmx.config.logAll = true`, exercise each interaction, confirm CSRF headers arrive and error responses render as intended.

## Compatibility bridges

For a large codebase, land the script swap behind bridges and remove them step by step:

```html
<meta name="htmx-config" content='{"implicitInheritance": true, "noSwap": [204, 304, "4xx", "5xx"]}'>
<script src="https://cdn.jsdelivr.net/npm/htmx.org@4.0.0/dist/ext/htmx-2-compat.js"></script>
```

`htmx-2-compat` re-fires the old event names and logs where implicit inheritance was relied on, but does not restore removed attributes such as `hx-ext` or `hx-params`.

## Output

Deliver, in this order: the recommendation, the inventory with counts, the checker output, the file-by-file changes (as diffs or edited files), the server-side changes, and a verification checklist. Keep 2.x and 4 syntax from mixing in the result: an `:inherited` suffix is ignored by 2.x and a bare parent attribute is ignored by 4.
