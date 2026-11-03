# Changelog

## 2.1.0 — 2026-10-30

Audit against the current Claude Code plugin standards and the FoundryVTT 14.369 source.

### Plugin packaging
- README install instructions now use the real commands (`/plugin install foundryvtt-dev --marketplace cyface/cyface-claude-plugin-marketplace`); the previous `/install` and `claude plugin add --git` forms did not exist.
- `plugin.json` gained `$schema`, `repository`, `license`, `privacyPolicyUrl`, `supportUrl`, and a `metadata.foundryVerified` field.
- The verified Foundry build is recorded only in the README and `plugin.json`; skills and references now say "V14" and defer there.
- Removed the undocumented `version` key from both SKILL.md frontmatters.
- Added `.gitignore` and this changelog.

### Content corrections (verified against Foundry 14.369 source)
- Detached windows: the render option is `window.detached: true`, not `detach: true`.
- Hook order is `init`, `i18nInit`, `setup`, `ready`; the hooks reference had `setup` before `init`.
- ApplicationV2 render hooks are `render{ClassName}` down to `renderApplicationV2` with `(app, element, context, options)`; `renderApplication` is AppV1-only. Same pattern for `preRender{ClassName}`; the literal `preRenderApplication` never fires.
- `renderChatMessageHTML` receives only `(message, html)`.
- Region shape types also include `token` and `grid`.
- ApplicationV1 has been deprecated since V13 (removal still V16), not since V14.
- ActiveEffect `start` also has `combatant` and `initiative`; `game.i18n.localize` accepts interpolation data and `format` is an alias.
- `canvas.grid.measurePath` returns a result object; read `.distance`.
- Document hierarchy now lists all 16 primary and 20 embedded document types with their owning collections.

### Code examples
- Inline item editing: `_processFormData` returns an expanded object; the example now removes `items` from it before the actor update and passes the four-argument `_processSubmitData` signature through.
- Hybrid drag-drop: ActorSheetV2 already binds `.draggable` to the subclass's `_onDragStart`/`_onDrop`; the example now overrides those instead of registering a second `DragDrop` (which handled every drop twice).
- Manual drag-drop: `_onRender` overrides now call `super._onRender`.
- Detached-window example declares its private `#observer` and `#syncLayout` members.
- `DialogV2.confirm` example dropped the redundant yes/no callbacks; the config dialog no longer shadows the global `document`.
- All template paths use `.hbs` (with a note that `.html` works identically); all icons use the Font Awesome 7 `fa-solid` form.

### Reviewer agent
- States that it has no shell access and must be given file paths.
- `event.preventDefault()` check narrowed to anchors and submit buttons.

## 2.0.0 — 2026-09-09

Retargeted the plugin to FoundryVTT v14: data models and `documentTypes` replace `template.json`, Active Effects V2, Regions replacing MeasuredTemplate, Scene Levels, message modes, detached windows, batched updates, and a V13-to-V14 migration reference.

## 1.0.0 — 2026-03-02

Initial release targeting FoundryVTT v13: ApplicationV2 and system-development skills with reference files, and the `foundryvtt-reviewer` agent.
