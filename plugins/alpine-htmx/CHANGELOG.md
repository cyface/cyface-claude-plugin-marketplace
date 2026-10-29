# Changelog

## Unreleased

### Plugin packaging
- Removed `.claude-plugin/marketplace.json`. It was a single-plugin marketplace that was also named `cyface`, so it clashed with the [cyface marketplace](https://github.com/cyface/cyface-claude-plugin-marketplace). Install from that marketplace instead: `/plugin install alpine-htmx --marketplace cyface/cyface-claude-plugin-marketplace`. If you added `cyface/alpine-htmx-claude-plugin` as a marketplace, remove it with `/plugin marketplace remove cyface` before adding the cyface marketplace.

## 2.0.0 — 2026-10-29

Full audit against the current Claude Code plugin standards and the current state of both frameworks.

### Plugin packaging
- `plugin.json`: added `$schema`, `repository`, `license`, `author.url`, `icon`, `privacyPolicyUrl`, `supportUrl`.
- Added `.claude-plugin/marketplace.json` so the plugin installs in one step with `/plugin install alpine-htmx --marketplace cyface/alpine-htmx-claude-plugin`.
- Added a 1024px listing icon.
- Removed the undocumented `version` field from both `SKILL.md` frontmatters.
- Reviewer agent: replaced the `<example>` description blocks with plain "use proactively" wording, preloads both skills via `skills:`, and now detects which htmx line a project uses before reviewing.
- Added an `evals/` suite (six cases) for `claude plugin eval`; `evals/results/` is git-ignored.
- Added `versions.json` and three GitHub workflows: a weekly framework-version check that has Claude Code open an upgrade PR when Alpine or htmx release, a structural `validate --strict` CI with a pin-consistency check, and a manual eval runner.

### htmx skill
- Now covers **htmx 4.0.0** (stable 2026-08-28) alongside **htmx 2.0.11**, with a version-detection step and side-by-side tables: explicit `:inherited` inheritance, `htmx:phase:action` event names and `event.detail.ctx`, 4xx/5xx swapping by default and `hx-status`, built-in `innerMorph`/`outerMorph`, `<hx-partial>`, HCON, renamed attributes (`hx-disabled-elt`→`hx-disable`, `hx-disable`→`hx-ignore`, `hx-request`→`hx-config`), removed attributes, config renames, `HX-Source`/`HX-Request-Type` headers, the end of the 286 polling convention, and the extension model (`dist/ext/*.js`, no `hx-ext`).
- New task-shaped skills following htmx's own guidance split: `htmx-upgrade` (2.x to 4 migration workflow, `argument-hint` for the project path, with the rename tables in `references/htmx-4-migration.md`) and `htmx-debug` (lifecycle checklist and symptom-to-cause guide for both lines).
- 2.x coverage updated through 2.0.11: `<hx-partial>`, `inherit` keyword, sessionStorage history cache, `reportValidityOfForms`, current extension package names and versions, `responseHandling`.
- Patterns rewritten for both lines (search, inline edit, infinite scroll, polling/load polling, validation errors, SSE, WebSockets, CSRF, modals, optimistic UI).

### Alpine skill
- Updated to Alpine **3.17.x**: added `x-modelable`, the Anchor and Resize plugins, `x-model.change/.blur/.enter/.boolean`, `x-on.passive.false` and mouse-event key modifiers, `x-intersect.parent/.dwell`, `x-anchor.noflip/.fixed`, `x-resize.viewport`, `x-sort:ignore`, `$dispatch` options and cancellation, `Alpine.bind`, `Alpine.morphBetween`, `Alpine.setErrorHandler`, `Alpine.deferInit`/`interceptInit`.
- Rewrote CSP-build guidance for the new expression evaluator (operators, ternaries, assignments and method calls supported; arrow functions, template literals, globals and nested assignment not).
- New `references/alpine-plugins.md`; directive reference gained a table of contents, reactivity gotchas and globals.
- Patterns now follow the official Alpine dropdown/modal structure (`x-id`, `x-trap.inert.noscroll`, `@focusin.window`, `@click.outside`, `type="button"`), and add `x-modelable`, sortable list, and tabs with roving focus.
- Integration section distinguishes htmx 2 kebab-case events from htmx 4 colon events, and covers `alpine-morph` (2.x) vs `outerMorph` + `hx-alpine-compat` (4).

## 1.0.0 — 2026-03-02

Initial release: Alpine.js v3 and htmx 2.x skills with reference files, and the `alpine-htmx-reviewer` agent.
