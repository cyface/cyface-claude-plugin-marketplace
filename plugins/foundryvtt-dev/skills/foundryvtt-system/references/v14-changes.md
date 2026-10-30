# V13 → V14 Changes (Data and Documents)

The data-side companion to the appv2 skill's `references/appv2-migration.md`, which covers the application layer. Last-verified build: see the plugin README.

## Environment

| Concern | V13 | V14 |
|---------|-----|-----|
| Node.js | `>=20.18.0 <23` | `>=24.13.1 <25` |
| Express (server) | 4 | 5 |
| `abstract-level` / `classic-level` | 2 | 3 |
| Rich text editor | TinyMCE + ProseMirror | ProseMirror only |

## Manifest

```json
{
  "compatibility": { "minimum": "14", "verified": "14.x" },
  "documentTypes": {
    "Actor": { "character": {}, "npc": {} },
    "Item":  { "weapon": {}, "armor": {}, "spell": {} }
  },
  "relationships": {
    "requires": [{ "id": "some-module", "type": "module", "compatibility": { "minimum": "2.0" } }]
  }
}
```

- `compatibility.maximum` is enforced: a package declaring `"maximum": "13"` refuses to load in V14. Raise it or leave it out.
- `minimumCoreVersion` / `compatibleCoreVersion` are legacy aliases for `compatibility.minimum` / `compatibility.verified`.
- `dependencies` is superseded by `relationships` (`requires`, `recommends`, `systems`, `conflicts`).
- System-only manifest fields: `documentTypes`, `initiative`, `grid`, `primaryTokenAttribute`, `secondaryTokenAttribute`, `background`.
- `styles` entries take an optional `layer`.

## `template.json` → Data Models

`template.json` still loads in V14 but logs a deprecation warning at startup and **will be removed in V16**. Foundry's own message points at the System Data Models article.

### Before (V13, `template.json`)

```json
{
  "Actor": {
    "types": ["character"],
    "character": { "hp": { "value": 10, "max": 10 }, "level": 1 }
  }
}
```

### After (V14)

Subtype names move to `system.json` under `documentTypes` — they must exist before `init` runs, or documents are rejected with `"<type>" is not a valid type`. The shape moves to a `TypeDataModel`:

```javascript
const { SchemaField, NumberField, StringField, HTMLField, BooleanField } = foundry.data.fields

export class CharacterData extends foundry.abstract.TypeDataModel {
  static defineSchema() {
    return {
      hp: new SchemaField({
        value: new NumberField({ required: true, integer: true, initial: 10 }),
        max: new NumberField({ required: true, integer: true, initial: 10 })
      }),
      level: new NumberField({ required: true, integer: true, min: 1, initial: 1 })
    }
  }

  prepareBaseData() { /* values effects may modify */ }
  prepareDerivedData() { /* values computed after effects */ }
}

Hooks.once('init', () => {
  CONFIG.Actor.dataModels = { character: CharacterData }
  CONFIG.Item.dataModels = { weapon: WeaponData }
})
```

### What you gain

- Validation and cleaning at the field level, with typed `initial` values
- `static migrateData(source)` for one-time-per-load shape migrations
- Schema fields exposed to sheets as `context.fields` — the `formGroup`/`formInput` Handlebars helpers build correct inputs from them
- `getFieldForProperty()` lookups, which is how Active Effects now resolve change targets

### Migration order that works

1. Add `documentTypes` to `system.json` with exactly the type names `template.json` declared
2. Write one `TypeDataModel` per type, mirroring the existing shape field for field
3. Register them on `CONFIG.<Document>.dataModels` in `init`
4. Delete `template.json`
5. Add `migrateData` for anything whose shape you took the opportunity to fix
6. Load a copy of a real world and watch the console for validation failures

Splitting shared shapes (`AbilityField`, `CurrencyField`, `DiceField`) into a `module/data/fields/` directory keeps the models readable and the migrations in one place.

## Active Effects V2

The largest single change in V14.

### Changes moved into system data

```javascript
// V13
effect.changes                                    // array on the effect itself
{ key: 'system.hp.max', mode: 2, value: '5' }     // numeric mode, string value

// V14
effect.system.changes                             // inside the type data model
{ key: 'system.hp.max', type: 'add', value: 5, phase: 'initial', priority: 20 }
```

Core migrates stored effects automatically (`changes` → `system.changes`, `mode` → `type`, JSON-ish string values parsed), but **code that reads or writes effects must be updated** — the compatibility shim covers stored data, not your accessors.

```javascript
// V13
for (const change of effect.changes) {
  if (change.mode === CONST.ACTIVE_EFFECT_MODES.ADD) { … }
}

// V14
for (const change of effect.system?.changes ?? []) {
  if (change.type === 'add') { … }
}
```

### Change types

| V13 mode | V14 type | Default priority |
|----------|----------|------------------|
| `CUSTOM` (0) | `'custom'` | 0 |
| `MULTIPLY` (1) | `'multiply'` | 10 |
| `ADD` (2) | `'add'` | 20 |
| — | `'subtract'` | 20 |
| `DOWNGRADE` (3) | `'downgrade'` | 30 |
| `UPGRADE` (4) | `'upgrade'` | 40 |
| `OVERRIDE` (5) | `'override'` | 50 |

`CONST.ACTIVE_EFFECT_MODES` is deprecated in favour of `CONST.ACTIVE_EFFECT_CHANGE_TYPES`. `ActiveEffect.CHANGE_TYPES` is the merged view of core types plus anything registered on `CONFIG.ActiveEffect.changeTypes`.

A change's `type` must be dot-delimited alphanumerics (`'diceChain'`, `'my-system.stepDie'`) or the literal form `custom.{number}`.

### The change schema

`CONFIG.ActiveEffect.dataModels.base` is `ActiveEffectTypeDataModel`, whose only field is `changes`:

```javascript
changes: ArrayField(SchemaField({
  key:      StringField({ required: true }),
  type:     StringField({ required: true, initial: 'add' }),
  value:    AnyField({ required: true, nullable: true, initial: '' }),
  phase:    StringField({ required: true, initial: 'initial' }),
  priority: NumberField()
}))
```

A system may replace the `changes` field with its own, but **must preserve `type`, `phase`, and `priority`**.

### Two-phase application

Effects apply twice per data-preparation cycle:

| Phase | Applied during | Use for |
|-------|----------------|---------|
| `initial` | `Actor#prepareEmbeddedDocuments` | modifying base values |
| `final` | `Actor#prepareDerivedData` | modifying values that only exist after derivation |

Both phases are core (`CONST.ACTIVE_EFFECT_CHANGE_PHASES`). `CONFIG.ActiveEffect.phases` registers *extra* phases, and whoever registers one is responsible for calling `actor.applyActiveEffects(phaseName)` at the right moment.

**The classic V14 bug**: `Actor#prepareBaseData()` calls `_clearData()`, which resets the completed-phase set. An override that forgets `super.prepareBaseData()` leaves it populated, and the next preparation cycle throws:

```
ActiveEffect application phase "initial" has already completed and cannot be run again
```

Do not override `applyActiveEffects` to re-run all effects — with two phases you will double-apply everything.

### Customising application

Rather than overriding `apply()` wholesale, V14 gives narrower seams:

| Need | Hook point |
|------|-----------|
| Skip a change under some condition | `shouldApplyChange(change, { phase })` on your ActiveEffect subclass |
| Handle a bespoke change type | register on `CONFIG.ActiveEffect.changeTypes` with a `handler` (and optional `render` for the config sheet) |
| Change how one arithmetic type behaves | override `static _applyChangeAdd` / `_applyChangeSubtract` / `_applyChangeMultiply` / `_applyChangeUpgrade` / `_applyChangeOverride` / `_applyChangeCustom` |
| Change field resolution | override `static applyChangeField(targetDoc, change, options)` |

The instance methods `apply`, `_applyAdd`, `_applyMultiply`, `_applyOverride`, `_applyUpgrade`, `_applyCustom`, `_applyLegacy` all moved to statics and warn until V16.

### Other effect changes

- `origin` is a `DocumentUUIDField` with `relative: true` — a plain non-UUID string is moved to `flags.core.originText` on migration
- Duration: `duration.seconds` / `.rounds` / `.turns` → `duration.value` + `duration.units`, with units `seconds`, `minutes`, `hours`, `days`, `months`, `years`, `rounds`, `turns`
- Start data: `duration.startTime` / `startRound` / `startTurn` / `combat` → `start.time` / `start.round` / `start.turn` / `start.combat`, plus new `start.combatant` and `start.initiative`
- Expiry events: `combatStart`, `roundStart`, `turnStart`; extend via `CONFIG.ActiveEffect.expiryEvents` (and call `ActiveEffect.registry.refresh` yourself)
- `showIcon` (`CONST.ACTIVE_EFFECT_SHOW_ICON`: `NEVER` / `CONDITIONAL` / `ALWAYS`) replaces ad-hoc icon suppression
- `CONFIG.statusEffects[].icon` → `.img`
- `CONFIG.ActiveEffect.legacyTransferral` **no longer exists** — remove any assignment

### Effects in compendium packs

Pack JSON sources store the new shape directly:

```json
{
  "_id": "aBcDeFgHiJkLmNoP",
  "_key": "!effects!aBcDeFgHiJkLmNoP",
  "name": "Blessed",
  "img": "icons/svg/aura.svg",
  "system": {
    "changes": [{ "key": "system.abilities.str.value", "type": "add", "value": 2 }]
  }
}
```

`_id` must be exactly 16 alphanumeric characters and `_key` must match `!effects!{_id}`. Use lowercase string types, never numeric modes.

## MeasuredTemplate → Region

`MeasuredTemplate` is the first core document type Foundry has removed. `MeasuredTemplate`, `MeasuredTemplateDocument`, `MeasuredTemplateConfig`, `Scene#templates`, `RegionShape`, and `CONST.MEASURED_TEMPLATE_TYPES` are deprecated shells.

```javascript
// V13
await canvas.scene.createEmbeddedDocuments('MeasuredTemplate', [{ t: 'circle', x, y, distance: 30 }])
const template = canvas.scene.templates.get(id)

// V14
await canvas.scene.createEmbeddedDocuments('Region', [{
  name: 'Spell Area',
  shapes: [{ type: 'circle', x, y, radius: 90 }],
  behaviors: []
}])
const region = canvas.scene.regions.get(id)
```

| V13 | V14 |
|-----|-----|
| `t: 'circle' / 'rect' / 'cone' / 'ray'` | shape `type: 'circle' / 'rectangle' / 'cone' / 'line'` |
| — | also `ellipse`, `polygon`, `ring`, `emanation`, `token`, `grid` |
| `MeasuredTemplate.getCircleShape()` etc. | `CircleShapeData`, `RectangleShapeData`, `ConeShapeData`, `LineShapeData`, … |
| `RegionDocument#regionShapes` | `RegionDocument#shapes` |
| `RegionDocument#attachedToken` | `RegionDocument#attachment.token` |
| `template.document.direction` | `region.document.shapes[0].rotation` |

New: `RegionDocument#hidden`, token attachment, region behaviors, and multiple teleport destinations (`TeleportTokenRegionBehaviorType#destinations`, replacing the singular `#destination`).

## Chat and Rolls

| V13 | V14 |
|-----|-----|
| `game.settings.get('core', 'rollMode')` | `game.settings.get('core', 'messageMode')` |
| `ChatMessage.applyRollMode()` | `ChatMessage.applyMode()` |
| `roll.toMessage({}, { rollMode })` | `roll.toMessage({}, { messageMode })` |
| `CONST.DICE_ROLL_MODES`, `CONFIG.Dice.rollModes` | `CONFIG.ChatMessage.modes` |
| `'publicroll'` / `'gmroll'` / `'blindroll'` / `'selfroll'` | `'public'` / `'gm'` / `'blind'` / `'self'` |
| — | `'ic'` (in-character) is a new mode |
| `ChatLog.MESSAGE_PATTERNS` | `ChatLog.CHAT_COMMANDS` |
| `ChatLog.MULTILINE_COMMANDS` | `isMultiline: true` on the `CHAT_COMMANDS` entry |

`Roll._mapLegacyRollMode` exists to translate old strings and is itself deprecated. Booleans in dice formulas now evaluate to `0`/`1` with no manual coercion.

## Scene Levels

Scenes own embedded `Level` documents describing vertically stacked images at defined elevations. Tiles, lights, walls, and sounds can be restricted to a level.

| V13 | V14 |
|-----|-----|
| `Scene#background` | `Level#background` / `Level#textures` |
| `Scene#backgroundColor` | `Level#background.color` |
| `Scene#foreground` | `Level#foreground.src` |
| `Scene#foregroundElevation` | `Level#elevation.top` |

Tokens gain `depth`, `level`, and `subpathId`; `CONST.TOKEN_MOVEMENT_FIELDS` is now `["x", "y", "elevation", "width", "height", "depth", "shape", "level"]`.

`TokenDocument#detectionModes` changed from an array of objects to a `TypedObjectField` keyed by mode id:

```javascript
token.detectionModes = [{ id: 'seeInvisibility', enabled: true, range: 30 }]  // V13
token.detectionModes = { seeInvisibility: { enabled: true, range: 30 } }      // V14
```

## Batched Document Updates

```javascript
await foundry.documents.modifyBatch([
  { action: 'update', documentName: 'Actor', updates: [{ _id: actor.id, 'system.size': 'large' }] },
  { action: 'update', documentName: 'Token', updates: [{ _id: t1, width: 2, height: 2 }], parent: sceneA },
  { action: 'update', documentName: 'Token', updates: [{ _id: t2, width: 2, height: 2 }], parent: sceneB }
])
```

Operations run in sequence with no network delay between them, and a cancellation or exception anywhere rolls back the whole batch. A batched operation cannot reference the result of an earlier one. Note the parameter is `documentName` (renamed from `documentType`).

## Update Operators

The special update keys are gone from `updateSource`:

```javascript
// V13
model.updateSource({ '-=obsolete': null, '==replaceMe': { … } })

// V14
const { ForcedDeletion, ForcedReplacement } = foundry.data.operators
model.updateSource({ obsolete: new ForcedDeletion(), replaceMe: ForcedReplacement.create({ … }) })
```

`mergeObject`'s `performDeletions` option is renamed `applyOperators`, and `foundry.utils.applySpecialKeys` is now `applyDataOperators`.

## Full Deprecation Table

Everything marked `{since: 14, until: 16}` that a system or module is likely to touch:

| Deprecated | Replacement |
|------------|-------------|
| `CONST.ACTIVE_EFFECT_MODES` | `CONST.ACTIVE_EFFECT_CHANGE_TYPES` (string `change.type`) |
| `effect.changes` | `effect.system.changes` |
| `ActiveEffect#apply` / `#_applyAdd` / `#_applyMultiply` / `#_applyOverride` / `#_applyUpgrade` / `#_applyCustom` / `#_applyLegacy` | the `static _applyChange*` / `applyChangeField` equivalents |
| `ActiveEffect.getInitialDuration` | `ActiveEffect.getEffectStart` |
| `ActiveEffectDuration#duration` / `#type` | `#seconds` / `#units` |
| `CONFIG.statusEffects[].icon` | `.img` |
| `CONST.DICE_ROLL_MODES`, `CONFIG.Dice.rollModes` | `CONFIG.ChatMessage.modes` |
| `ChatMessage#applyRollMode` | `#applyMode` |
| `rollMode` option | `messageMode` option |
| `CONST.MEASURED_TEMPLATE_TYPES`, `Scene#templates` | Region shapes |
| `RegionDocument#regionShapes` | `#shapes` |
| `CONST.WALL_DIRECTIONS` / `WALL_SENSE_TYPES` | `CONST.EDGE_DIRECTIONS` / `EDGE_SENSE_TYPES` |
| `Scene#background` / `#backgroundColor` / `#foreground` / `#foregroundElevation` | `Level#…` equivalents |
| `BaseScene#fog.exploration` | `BaseScene#fog.mode` |
| `foundry.utils.objectsEqual` | `foundry.utils.equals` |
| `foundry.utils.applySpecialKeys` | `foundry.utils.applyDataOperators` |
| `mergeObject({ performDeletions })` | `mergeObject({ applyOperators })` |
| `ClientDocument#getRelativeUUID` | `foundry.utils.buildRelativeUuid` |
| `Combat#getCombatantByActor` / `ByToken` | `getCombatantsByActor` / `ByToken` (plural) |
| `ContextMenuEntry#name` / `#condition` / `#callback` | `#label` / `#visible` / `#onClick` |
| `ContextMenu.eventListeners` | `ContextMenu.activateListeners` |
| `foundry.prosemirror.defaultPlugins` | `ProseMirrorEditor.buildDefaultPlugins()` |
| `TextureLoader.fetchResource` / `.getCacheBustURL` | `foundry.utils.fetchResource` / `.getCacheBustURL` |
| `ChatLog.MESSAGE_PATTERNS` | `ChatLog.CHAT_COMMANDS` |
| `DocumentIndex#_addLeaf` | `#_addLeaves` |
| `foundry.documents.modifyBatch({documentType})` | `{documentName}` |
| `template.json` | `documentTypes` + `TypeDataModel` |
| `Application` / `FormApplication` / `Dialog` / `DocumentSheet` (deprecated since **V13**, same V16 removal) | ApplicationV2 classes |

Removed outright (no shim): `ApplicationV2#bringToTop` (use `bringToFront`), the `{{select}}` and `{{colorPicker}}` Handlebars helpers, `PlaceablesLayer.SORT_ORDER` and `CREATION_STATES`, TinyMCE.

## Additions Worth Adopting

- **`_loc`** — a global bound to `game.i18n.localize`: `_loc('MY_SYSTEM.Key')`. `localize()` now also takes interpolation data; `game.i18n.format` is kept as an alias of it
- **Detached windows** — any ApplicationV2 can pop out into its own browser window
- **`foundry.documents.modifyBatch`** — atomic multi-document writes
- **Scene Levels** — native multi-level maps
- **Relative UUIDs** — `DocumentUUIDField({ relative: true })` for portable intra-document references
- **`IntegerSortField`, `SceneLevelsSetField`, `TypedObjectField`** — new schema field types
- **ProseMirror** — image captions, custom CSS classes, collapsible sections, table sections, HTML template insertion
- **Font Awesome 7.2.0**

## Migration Checklist

### Blocking (V14 will not work without these)
1. [ ] Node 24 everywhere: local, CI, `engines`
2. [ ] `compatibility` → `{ minimum: "14", verified: "14.x" }`; remove or raise `maximum`
3. [ ] Every `prepareBaseData()` override calls `super.prepareBaseData()`
4. [ ] Effect accessors read `effect.system.changes` and `change.type`
5. [ ] Effect writers create `{ system: { changes: [{ key, type, value }] } }`
6. [ ] Remove `CONFIG.ActiveEffect.legacyTransferral`
7. [ ] Replace MeasuredTemplate creation and lookup with Regions
8. [ ] `rollMode` → `messageMode`, including the stored string values
9. [ ] Compendium effect sources rewritten to the new shape and recompiled

### Should do now (removed in V16)
10. [ ] `template.json` → `documentTypes` + `TypeDataModel`
11. [ ] AppV1 sheets → ApplicationV2
12. [ ] Context-menu entries to `label` / `visible` / `onClick`, registered in `init` not `ready`
13. [ ] `objectsEqual` → `equals`; `performDeletions` → `applyOperators`; `-=`/`==` → operator classes
14. [ ] `detectionModes` array access → keyed object

### Validation
15. [ ] Boot a copy of a real world with the console open; fix every deprecation warning
16. [ ] Confirm no CSS rule depends on a `body.game .app` variable
17. [ ] Run unit tests and E2E specs; update mocks that still expose `ACTIVE_EFFECT_MODES`
