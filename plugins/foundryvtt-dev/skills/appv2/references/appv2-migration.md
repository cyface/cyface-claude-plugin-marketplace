# ApplicationV2 Migration Reference

Two migrations in one file:

- **[Part 1: V13 → V14](#part-1-v13--v14)** — current generation. Last-verified build: see the plugin README.
- **[Part 2: V12 → V13](#part-2-v12--v13)** — the original Application → ApplicationV2 rewrite, kept for packages still making that jump.

---

# Part 1: V13 → V14

V14 is mostly *additive* for ApplicationV2 code: a V13 sheet usually runs unmodified. The breakage comes from things around it — Active Effects, MeasuredTemplates, chat roll modes, and a handful of removed helpers.

## Environment and Manifest

| Concern | V13 | V14 |
|---------|-----|-----|
| Node.js | `>=20.18.0 <23` | `>=24.13.1 <25` |
| Bundled editor | TinyMCE + ProseMirror | ProseMirror only (TinyMCE removed) |
| Manifest compatibility | `compatibility` object preferred | `compatibility` object; `minimumCoreVersion`/`compatibleCoreVersion` are legacy aliases |

```json
{
  "compatibility": { "minimum": "14", "verified": "14.x" }
}
```

`compatibility.maximum` is a hard boundary: a package declaring `"maximum": "13"` refuses to load under V14. Bump it (or drop it) as part of the migration. Prefer `relationships.requires` / `relationships.systems` over the older `dependencies` field.

## ApplicationV1 Status

`Application`, `FormApplication`, `Dialog`, and `DocumentSheet` still exist in V14 but are deprecated with removal targeted at **V16**. `FormApplication#filepickers` had its deprecation extended to V16 as well. V14 renders no core AppV1 windows — see the CSS consequence in the appv2 skill's *CSS Theming* section.

## ApplicationV2 API Changes

| V13 | V14 | Notes |
|-----|-----|-------|
| `app.bringToTop()` | `app.bringToFront()` | `bringToTop` removed |
| `_insertElement(element)` | `async _insertElement(element, options={})` | now async, takes options |
| — | `async _postRender(context, options)` | new lifecycle step after render completes |
| — | `attachWindow()` / `detachWindow()` / `renderChild(app)` | pop-out window support |
| — | `_canAttach()` / `_canDetach()` / `_onAttach()` / `_onDetach()` | opt out of, or react to, detaching |
| — | `_getFrameButtons(options)` | frame buttons distinct from `_getHeaderControls()` |
| — | `preRender{ClassName}` hooks | fire before render with `(app, context, options)`, once per class in the chain down to `preRenderApplicationV2` (the literal name `preRenderApplication` never fires) |

`static emittedEvents` is `["prerender", "render", "close", "position"]`.

Default `window.controls` now contains Detach and Attach entries. Replacing `window.controls` wholesale drops them; append via `_getHeaderControls()` instead.

### Detached windows

```javascript
app.render({ window: { detached: true } })
```

A detached app lives in a different `document`. Anything cached against the global `document` or `window` during render must be re-derived from `this.element.ownerDocument`. Open child apps with `this.renderChild(childApp)` so they follow the parent.

## Removed Handlebars Helpers

| Removed in V14 | Replacement |
|----------------|-------------|
| `{{select}}` | `{{selectOptions}}` |
| `{{colorPicker}}` | `<color-picker>` element |

## Namespace and Utility Changes

| V13 | V14 |
|-----|-----|
| `TextEditor.implementation.enrichHTML()` | `TextEditor.enrichHTML()` (re-exported on the class) |
| `foundry.prosemirror.defaultPlugins` | `foundry.applications.ux.ProseMirrorEditor.buildDefaultPlugins()` |
| `foundry.utils.objectsEqual()` | `foundry.utils.equals()` (handles more than objects) |
| `foundry.utils.applySpecialKeys()` | `foundry.utils.applyDataOperators()` |
| `mergeObject(…, { performDeletions: true })` | `mergeObject(…, { applyOperators: true })` |
| `{ '-=key': null }` / `{ '==key': v }` in `updateSource` | `foundry.data.operators.ForcedDeletion` / `ForcedReplacement` |
| `ContextMenu.eventListeners()` | `ContextMenu.activateListeners()` |
| `ProseMirrorMenu.eventListeners()` | `ProseMirrorMenu.activateListeners()` |
| `TooltipManager#activateEventListeners()` | `TooltipManager#activateListeners()` |
| `ClientDocument#getRelativeUUID()` | `foundry.utils.buildRelativeUuid()` |
| `TextureLoader.fetchResource()` | `foundry.utils.fetchResource()` |
| `TextureLoader.getCacheBustURL()` | `foundry.utils.getCacheBustURL()` |
| `foundry.canvas.srcExists()` | `foundry.utils.srcExists()` |
| `Combat#getCombatantByActor/ByToken` | `Combat#getCombatantsByActor/ByToken` (plural, returns arrays) |
| `ClientKeybindings#moveKeys` | `game.keyboard.moveKeys` |

New global: **`_loc`** is `game.i18n.localize` pre-bound, available once `game` is constructed. `_loc("MY_SYSTEM.Key")` is equivalent to `game.i18n.localize("MY_SYSTEM.Key")`.

## Context Menus

Two separate changes, and the timing one is the silent killer.

### Entry shape

| V12/V13 field | V14 field |
|---------------|-----------|
| `name` (pre-localized string) | `label` (raw i18n key — core localizes it) |
| `icon` (`<i>` HTML string) | `icon` (class name, e.g. `'fa-solid fa-scale-balanced'`; HTML strings still parse) |
| `condition: el => …` | `visible: el => …` |
| `callback: el => …` | `onClick: (event, el) => …` |

The old field names still work but log deprecation warnings until V16.

### Registration timing

ApplicationV2 apps build their context menus through `_createContextMenu`, which fires the corresponding `get*ContextOptions` hook **once, at the app's first render** — not on every menu open. Core UI apps (Players list, sidebar tabs) first render during boot, *before* `ready`. Registering these hooks from `ready` therefore does nothing at all, silently.

```javascript
// WRONG in V14 — the Players list already rendered
Hooks.once('ready', () => {
  Hooks.on('getUserContextOptions', (app, entries) => entries.push(…))
})

// CORRECT — register at import time or in init; put dynamic checks in visible()
Hooks.on('getUserContextOptions', (app, entries) => {
  entries.push({
    label: 'MY_SYSTEM.AwardLuck',
    icon: 'fa-solid fa-clover',
    visible: li => game.user.isGM,          // evaluated per menu open
    onClick: (event, li) => awardLuck(li.dataset.userId)
  })
})
```

## Chat Roll Modes → Message Modes

Roll modes became chat *message* modes, configured on `CONFIG.ChatMessage.modes` (`public`, `gm`, `blind`, `self`, `ic`) with new string values.

| V13 | V14 |
|-----|-----|
| `CONST.DICE_ROLL_MODES` / `CONFIG.Dice.rollModes` | `CONFIG.ChatMessage.modes` |
| `game.settings.get('core', 'rollMode')` | `game.settings.get('core', 'messageMode')` |
| `ChatMessage.applyRollMode(data, mode)` | `ChatMessage.applyMode(data, mode)` |
| `roll.toMessage({}, { rollMode })` | `roll.toMessage({}, { messageMode })` |
| `'publicroll'` | `'public'` |
| `'gmroll'` | `'gm'` |
| `'blindroll'` | `'blind'` |
| `'selfroll'` | `'self'` |

## MeasuredTemplate Removed

The first core document type Foundry has ever removed. `MeasuredTemplate`, `MeasuredTemplateDocument`, `MeasuredTemplateConfig`, `Scene#templates`, and `CONST.MEASURED_TEMPLATE_TYPES` are all deprecated shells; the functionality merged into **Region**.

```javascript
// V13
await canvas.scene.createEmbeddedDocuments('MeasuredTemplate', [
  { t: 'circle', x, y, distance: 30 }
])

// V14
await canvas.scene.createEmbeddedDocuments('Region', [{
  name: 'Spell Area',
  shapes: [{ type: 'circle', x, y, radius: 90 }],
  behaviors: []
}])
```

- `canvas.scene.templates.get(id)` → `canvas.scene.regions.get(id)`
- `RegionDocument#regionShapes` → `RegionDocument#shapes`
- `RegionDocument#attachedToken` → `RegionDocument#attachment.token`
- `RegionShape` → the `BaseShapeData` subclasses: `Circle`, `Rectangle`, `Ellipse`, `Polygon`, `Cone`, `Ring`, `Line`, `Emanation`, `Token`, `Grid`
- MeasuredTemplate `t: "ray"` → Region shape `type: "line"`
- `template.document.direction` → `region.document.shapes[0].rotation`
- `MeasuredTemplate.getCircleShape/getConeShape/getRayShape/getRectShape` → `CircleShapeData` / `ConeShapeData` / `LineShapeData` / `RectangleShapeData`
- `RegionDocument#hidden` is new

Regions gain what templates never had: token attachment, multiple teleport destinations, and behaviors.

## Canvas and Scene

| V13 | V14 |
|-----|-----|
| `CONST.WALL_DIRECTIONS` / `WALL_SENSE_TYPES` | `CONST.EDGE_DIRECTIONS` / `EDGE_SENSE_TYPES` |
| `ClockwiseSweepPolygon#wallDirectionMode` | `#edgeDirectionMode` (`CONST.EDGE_DIRECTION_MODES`) |
| `config.edgeOptions` | `config.edgeTypes` |
| `Scene#background` / `#backgroundColor` / `#foreground` / `#foregroundElevation` | `Level#background`, `Level#background.color`, `Level#foreground.src`, `Level#elevation.top` |
| `BaseScene#fog.exploration` | `BaseScene#fog.mode` |
| `CanvasEdges#initialize` | `Scene#initializeEdges` |
| `PlaceablesLayer.SORT_ORDER` / `CREATION_STATES` | removed |
| `ControlIcon#iconSrc` / `#rect` / `#borderColor` / `#tintColor` | `#texture` / `#size` / `#border.tint` / `#icon.tint` |
| `ParticleEffect` API | `foundry.canvas.animation.ParticleGenerator` |

`game.activeTool` and `SceneControls#tool` can be `null` in V14 when the active layer has no tools. Null-check before use.

**Scene Levels** are new: a Scene owns embedded `Level` documents with elevation ranges, and tiles, lights, walls, and sounds can be restricted to a level. Tokens gain `depth`, `level`, and `subpathId`; `MOVEMENT_FIELDS` is now `["x", "y", "elevation", "width", "height", "depth", "shape", "level"]`.

**Token `detectionModes`** changed from an array of objects to a `TypedObjectField` keyed by mode id:

```javascript
// V13
token.detectionModes = [{ id: 'seeInvisibility', enabled: true, range: 30 }]

// V14
token.detectionModes = { seeInvisibility: { enabled: true, range: 30 } }
```

## Active Effects V2

The largest data-side change; covered in full in the **foundryvtt-system** skill's `references/v14-changes.md`. The one-line version: `effect.changes` moved to `effect.system.changes`, and numeric `change.mode` became string `change.type`.

## V13 → V14 Checklist

### Manifest and environment
1. [ ] Node 24 in CI, `engines`, and any local toolchain
2. [ ] `compatibility` → `{ minimum: "14", verified: "14.x" }`; remove or raise `maximum`
3. [ ] `dependencies` → `relationships`

### Data
4. [ ] Migrate Active Effect `changes` → `system.changes`, `mode` → `type`
5. [ ] Every `prepareBaseData()` override calls `super.prepareBaseData()`
6. [ ] Replace MeasuredTemplate creation/queries with Regions
7. [ ] `detectionModes` array access → keyed object
8. [ ] `template.json` → `TypeDataModel` + `documentTypes` (deprecated, removed in V16)

### Application layer
9. [ ] `bringToTop` → `bringToFront`
10. [ ] `_insertElement` overrides made async with the options parameter
11. [ ] Header-control overrides append to `super._getHeaderControls()`
12. [ ] `{{select}}` → `{{selectOptions}}`; `{{colorPicker}}` → `<color-picker>`
13. [ ] `TextEditor.implementation.enrichHTML` → `TextEditor.enrichHTML`
14. [ ] `foundry.prosemirror.defaultPlugins` → `ProseMirrorEditor.buildDefaultPlugins()`

### Hooks and chat
15. [ ] Context-menu entries: `name`→`label`, `condition`→`visible`, `callback`→`onClick`, icon class strings
16. [ ] Context-menu hooks registered at import time or `init`, never `ready`
17. [ ] `rollMode` → `messageMode`; roll-mode string values updated
18. [ ] `ChatMessage.applyRollMode` → `applyMode`

### Utilities
19. [ ] `objectsEqual` → `equals`; `performDeletions` → `applyOperators`
20. [ ] `-=key` / `==key` operators → `ForcedDeletion` / `ForcedReplacement`

### Validation
21. [ ] Boot a world with a browser console open and fix every deprecation warning
22. [ ] Verify CSS: no rule depends on a `body.game .app` variable
23. [ ] Test a detached sheet if you override render internals
24. [ ] Run the test suite and any E2E specs

---

# Part 2: V12 → V13

The Application → ApplicationV2 rewrite. If a package still has AppV1 sheets, this is the work; everything in Part 1 applies afterwards.

## Breaking Changes Summary

### jQuery Removed

**V12**: `html` parameters in hooks and `activateListeners()` are jQuery objects. **V13**: plain DOM elements.

```javascript
// V12 jQuery (breaks)
html.find('.my-button').click(handler)
html.addClass('active')

// V13 DOM
html.querySelector('.my-button').addEventListener('click', handler)
html.classList.add('active')
```

### Document Data Path

```javascript
this.object.update({ data: { results } })     // V12 — breaks
this.document.update({ system: { results } }) // V13
```

### Namespace Deprecations

```javascript
// V12                            // V13
TextEditor.enrichHTML(c)          foundry.applications.ux.TextEditor.implementation.enrichHTML(c)
FilePicker.browse()               foundry.applications.apps.FilePicker.browse()
renderTemplate(path, data)        foundry.applications.handlebars.renderTemplate(path, data)
new Ray(origin, direction)        new foundry.geometry.Ray(origin, direction)
NotesLayer.TOGGLE_SETTING         foundry.canvas.layers.NotesLayer.TOGGLE_SETTING
```

(In V14, `TextEditor.enrichHTML` is callable directly — `.implementation` is no longer required.)

## Method-by-Method Migration

| V12 | V13 | Notes |
|-----|-----|-------|
| `static get defaultOptions()` | `static DEFAULT_OPTIONS = {}` | Static property, not getter |
| `getData()` | `async _prepareContext(options)` | Now async |
| `activateListeners(html)` | `DEFAULT_OPTIONS.actions` | Declarative actions |
| `_updateObject(event, formData)` | `static #onSubmitForm(event, form, formData)` | Static form handler |
| `this.object` | `this.document` / `this.actor` | Depends on base class |
| `template: 'path.hbs'` | `static PARTS = { … }` | Template parts |
| `tabs: [{ navSelector }]` | `static TABS = { … }` | New tab configuration |
| `new MyApp(document, options)` | `new MyApp({ document, …options })` | Single options object |
| `mergeObject(super.defaultOptions, {})` | N/A | DEFAULT_OPTIONS auto-merges |

## Class Inheritance

```javascript
// V12                                    // V13
class S extends ActorSheet { }            class S extends HandlebarsApplicationMixin(ActorSheetV2) { }
class S extends ItemSheet { }             class S extends HandlebarsApplicationMixin(ItemSheetV2) { }
class D extends FormApplication { }       class D extends HandlebarsApplicationMixin(ApplicationV2) { }
```

## DEFAULT_OPTIONS Migration

```javascript
// V12
static get defaultOptions() {
  return foundry.utils.mergeObject(super.defaultOptions, {
    classes: ['my-system', 'sheet', 'actor'],
    template: 'systems/my-system/templates/actor-sheet.hbs',
    width: 600, height: 600, resizable: true,
    tabs: [{ navSelector: '.tabs', contentSelector: '.tab-content', initial: 'character' }]
  })
}

// V13+
static DEFAULT_OPTIONS = {
  classes: ['my-system', 'sheet', 'actor'],
  position: { width: 600, height: 600 },
  window: { resizable: true, title: 'MY_SYSTEM.ActorSheet' },
  tag: 'form',
  form: { submitOnChange: true },
  actions: { rollAbilityCheck: this.#rollAbilityCheck }
}
```

## Hook Renames

```javascript
Hooks.on('renderChatMessage', …)      // V12 — html is jQuery
Hooks.on('renderChatMessageHTML', …)  // V13+ — html is an HTMLElement
```

Context menu hooks all became `get{DocumentName}ContextOptions`:

| V12 Hook | V13+ Hook |
|----------|-----------|
| `getChatLogEntryContext` | `getChatMessageContextOptions` |
| `getActorDirectoryEntryContext` | `getActorContextOptions` |
| `getSceneNavigationContext` | `getSceneContextOptions` |
| `getCombatTrackerEntryContext` | `getCombatContextOptions` |
| `getCombatantEntryContext` | `getCombatantContextOptions` |
| `getMacroDirectoryEntryContext` | `getMacroContextOptions` |
| `getPlaylistDirectoryEntryContext` | `getPlaylistContextOptions` |
| `getPlaylistSoundContext` | `getPlaylistSoundContextOptions` |
| `getFolderContext` | `getFolderContextOptions` |

The signature changed from `(html, options)` to `(application, entries)`, and the entry callbacks receive `HTMLElement` rather than jQuery. **V14 then changed the entry field names again** — see Part 1.

## Other V12 → V13 Changes

```javascript
result.text        // V12  ->  result.description   (TableResult)
table.compendium   // V12  ->  table.collection     (RollTable)
```

Sheet registration became mandatory: every system must `unregisterSheet('core', …)` and `registerSheet(…)` in `init`.

CSS Layers arrived, checkboxes became FontAwesome-based (style `::before`/`::after`), and `{{editor}}` gave way to the `<prose-mirror>` element.

## V12 → V13 Checklist

1. [ ] Register all actor and item sheets explicitly
2. [ ] Choose base classes (ActorSheetV2 / ItemSheetV2 / ApplicationV2 / DialogV2)
3. [ ] Wrap in `HandlebarsApplicationMixin`
4. [ ] `defaultOptions` → `DEFAULT_OPTIONS`; dimensions to `position`, window props to `window`
5. [ ] Add `tag: 'form'` for forms and dialogs
6. [ ] `getData()` → `_prepareContext()`
7. [ ] Define `PARTS`; split monolithic templates per tab
8. [ ] `activateListeners` → `actions` + `data-action` attributes
9. [ ] Define `TABS`; `_getTabsConfig()` for dynamic tabs
10. [ ] Drag/drop: automatic for ActorSheetV2, manual `DragDrop` for ApplicationV2
11. [ ] `{{editor}}` → `<prose-mirror>`; inherited `editImage` for portraits
12. [ ] Replace jQuery in hooks; update hook names and namespaces
13. [ ] `variables.css` with `system-` prefixed light and dark values, `"layer": "variables"`
14. [ ] Test everything end-to-end, including drag/drop and theme switching

## Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Dialog not opening | Wrong constructor pattern | `new MyDialog({ document: actor })` |
| All tabs visible at once | `display: grid/flex` on a tab ancestor | Move layout styles to inner elements |
| Tabs do nothing on click | Nav links missing `data-action="tab"` | Tab switching is a framework action |
| Actions not firing | `data-action` value mismatch | Must match the `actions` key exactly |
| Form not submitting | Missing `tag: 'form'` | Add it to DEFAULT_OPTIONS |
| CONFIG undefined | CONFIG used in a static initializer | Hard-code template paths |
| Drag/drop broken | No setup for plain AppV2 | `.draggable` on ActorSheetV2, manual `DragDrop` otherwise |
| Items not saving | Nested item data stripped by validation | Override `_processFormData` and `_processSubmitData` |
| Borders/focus rings invisible (V14) | Rule uses a `body.game .app` variable | Use your own `--system-*` token |
| Context menu entry never appears (V14) | Hook registered in `ready` | Register at import time or in `init` |
