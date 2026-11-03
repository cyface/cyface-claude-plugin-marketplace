---
name: foundryvtt-system
description: >-
  This skill should be used when the user asks about "FoundryVTT system development",
  "FoundryVTT module", "Foundry hooks", "data model", "TypeDataModel", "defineSchema",
  "documentTypes", "template.json", "migrateData", "Active Effects", "effect changes",
  "Actor class", "Item class", "Roll class", "compendium packs", "Regions",
  "Scene Levels", "game settings", "game.i18n", "localize", "i18n",
  "testing FoundryVTT", "Vitest with Foundry", "mocking Foundry", "system.json",
  "FoundryVTT project structure", "Foundry documents", "embedded documents",
  "settings registration", "Hooks.on", "Hooks.once", "game.settings.register",
  "game.actors", "game.items", "CONFIG object", "FoundryVTT canvas",
  "FoundryVTT API", "SCSS in Foundry", "language files", "translation files",
  "pack management", "LevelDB packs", "compendium JSON", "V13 to V14 migration",
  or mentions building a game system or module for FoundryVTT.
---

# FoundryVTT System Development Guide

Building a game system or module for **FoundryVTT V14** (last-verified build: see the plugin README). Covers project structure, data models, documents, Active Effects, hooks, settings, packs, testing, and i18n.

**Note**: This plugin is a community resource and is not affiliated with or endorsed by Foundry Gaming LLC.

V14 requires **Node.js 24** (`>=24.13.1 <25`). Coming from V13? Start with **`references/v14-changes.md`**.

## System File Structure

```
my-system/
+-- module/               # JavaScript source
|   +-- __tests__/        # Test files (Vitest)
|   +-- __mocks__/        # Test mocks for Foundry API
|   +-- data/             # TypeDataModel classes
|   |   +-- fields/       # Reusable field classes
|   |   +-- actor/        # BaseActorData + per-type models
|   |   +-- item/         # BaseItemData + per-type models
|   +-- my-system.mjs     # Entry point (registered in system.json)
|   +-- actor.mjs         # Custom Actor document class
|   +-- item.mjs          # Custom Item document class
|   +-- active-effect.mjs # Custom ActiveEffect class (optional)
|   +-- config.mjs        # System constants and lookup tables
+-- templates/            # Handlebars templates (.hbs by convention; .html also works)
+-- styles/               # SCSS/CSS stylesheets
+-- lang/                 # Translation files (en.json, de.json, …)
+-- packs/                # Compendium packs
|   +-- creatures/src/    # JSON source files (tracked in git)
+-- docs/
+-- system.json           # System manifest — also declares document subtypes
```

`template.json` is **deprecated in V14** and will be removed in V16. New systems declare subtypes in `system.json` and back them with data models.

## Data Models (TypeDataModel)

Two pieces: declare the subtype names in the manifest, then register a schema class for each.

### 1. Declare subtypes in `system.json`

Type names must be present *before* `init` runs, or Foundry rejects documents with `"<type>" is not a valid type`.

```json
{
  "documentTypes": {
    "Actor": { "character": {}, "npc": {} },
    "Item":  { "weapon": {}, "armor": {}, "spell": {}, "equipment": {} }
  }
}
```

Per-type entries may carry `htmlFields`, `filePathFields`, and `gmOnlyFields`.

### 2. Define the schema

```javascript
const { SchemaField, StringField, NumberField, BooleanField, HTMLField } = foundry.data.fields

export class BaseActorData extends foundry.abstract.TypeDataModel {
  static defineSchema() {
    return {
      hp: new SchemaField({
        value: new NumberField({ required: true, integer: true, initial: 10 }),
        max: new NumberField({ required: true, integer: true, initial: 10 })
      }),
      biography: new HTMLField({ initial: '' })
    }
  }
}

export class CharacterData extends BaseActorData {
  static defineSchema() {
    const abilities = ['str', 'dex', 'con', 'int', 'wis', 'cha']
    return {
      ...super.defineSchema(),
      level: new NumberField({ required: true, integer: true, min: 1, initial: 1 }),
      abilities: new SchemaField(Object.fromEntries(abilities.map(a => [a, new SchemaField({
        value: new NumberField({ required: true, integer: true, initial: 10 })
      })])))
    }
  }

  /** Derived values — runs during the parent document's data preparation */
  prepareDerivedData() {
    for (const ability of Object.values(this.abilities)) {
      ability.mod = Math.floor((ability.value - 10) / 2)
    }
  }
}
```

### 3. Register in `init`

```javascript
Hooks.once('init', () => {
  CONFIG.Actor.dataModels = { character: CharacterData, npc: NPCData }
  CONFIG.Item.dataModels = { weapon: WeaponData, armor: ArmorData, spell: SpellData }
})
```

Access is unchanged: `actor.system.hp.value`, `item.system.damage`.

### 4. Migrate stored worlds with `migrateData`

Any schema change that is not backwards compatible with data already on disk needs a static migration. It runs on every load, so it must be idempotent and must not mutate partial-update diffs into full documents.

```javascript
static migrateData(source) {
  // Legacy: damage was a plain string, now a schema field
  if (typeof source.damage === 'string') {
    source.damage = { formula: source.damage, type: 'physical' }
  }
  return super.migrateData(source)
}
```

Prefer a shared field class in `module/data/fields/` whenever the same shape appears in more than one model.

## Document Classes

```javascript
class MyActor extends Actor {
  /** @override */
  prepareBaseData() {
    super.prepareBaseData()   // REQUIRED in V14 — see below
    // Base values that Active Effects may then modify
  }

  /** @override */
  prepareDerivedData() {
    super.prepareDerivedData()
    // Values computed after effects have applied
  }

  async rollAbilityCheck(abilityId) {
    const ability = this.system.abilities[abilityId]
    const roll = new Roll('1d20 + @mod', { mod: ability.mod })
    await roll.evaluate()
    await roll.toMessage({
      speaker: ChatMessage.getSpeaker({ actor: this }),
      flavor: game.i18n.localize(`MY_SYSTEM.Ability${abilityId.capitalize()}`)
    })
    return roll
  }
}

Hooks.once('init', () => {
  CONFIG.Actor.documentClass = MyActor
  CONFIG.Item.documentClass = MyItem
})
```

**The most common V14 breakage**: `Actor#prepareBaseData()` now calls `_clearData()`, which resets the Active Effect phase-tracking set. An override that skips `super.prepareBaseData()` leaves the set populated, and the second data-preparation cycle throws *"ActiveEffect application phase 'initial' has already completed"*. Always call super.

## Active Effects V2

V14 restructured Active Effects. Changes moved into the effect's system data, and numeric modes became string types.

```javascript
// V13
await actor.createEmbeddedDocuments('ActiveEffect', [{
  name: 'Blessed',
  icon: 'icons/svg/aura.svg',
  changes: [{ key: 'system.abilities.str.value', mode: CONST.ACTIVE_EFFECT_MODES.ADD, value: '2' }]
}])

// V14
await actor.createEmbeddedDocuments('ActiveEffect', [{
  name: 'Blessed',
  img: 'icons/svg/aura.svg',
  system: {
    changes: [{ key: 'system.abilities.str.value', type: 'add', value: 2 }]
  }
}])
```

| V13 `mode` | V14 `type` |
|------------|-----------|
| `CUSTOM` (0) | `'custom'` |
| `MULTIPLY` (1) | `'multiply'` |
| `ADD` (2) | `'add'` |
| `DOWNGRADE` (3) | `'downgrade'` |
| `UPGRADE` (4) | `'upgrade'` |
| `OVERRIDE` (5) | `'override'` |
| — | `'subtract'` (new) |

`CONST.ACTIVE_EFFECT_MODES` is deprecated; the current constant is `CONST.ACTIVE_EFFECT_CHANGE_TYPES`, and `ActiveEffect.CHANGE_TYPES` merges in anything systems register on `CONFIG.ActiveEffect.changeTypes`.

**Two-phase application.** Effects apply in an `initial` phase (during `prepareEmbeddedDocuments`) and a `final` phase (during `prepareDerivedData`), letting a change target a value that only exists after base derivation. Both phases are core; `CONFIG.ActiveEffect.phases` registers *additional* phases, and a package introducing one must call `actor.applyActiveEffects(phaseName)` at the right point itself. Do not override `applyActiveEffects` to re-run the whole set — you will double-apply.

Also new: duration units beyond seconds (`rounds`, `turns`, `minutes`, `hours`, `days`, `months`, `years`) with `duration.value` + `duration.units`, expiry events (`combatStart`, `roundStart`, `turnStart`), and `origin` as a real `DocumentUUIDField` supporting relative UUIDs.

`CONFIG.ActiveEffect.legacyTransferral` no longer exists in V14 — delete any assignment to it.

Full detail, including the compendium storage format: **`references/v14-changes.md`**.

## Hooks System

```javascript
Hooks.once('init', () => {
  CONFIG.Actor.documentClass = MyActor
  CONFIG.Actor.dataModels = { character: CharacterData }
  // Register settings, sheets, templates, context-menu hooks
})

Hooks.once('ready', () => {
  // game.actors etc. are populated; run world migrations here
})
```

### Common Hooks

| Hook | When | Parameters |
|------|------|------------|
| `init` | System init, before game data | none |
| `i18nInit` | Translations loaded | none |
| `setup` | After init, before ready | none |
| `ready` | Game fully loaded | none |
| `createActor` / `updateActor` / `deleteActor` | Document lifecycle | `(doc, …, options, userId)` |
| `createItem` / `updateItem` / `deleteItem` | Document lifecycle | `(doc, …, options, userId)` |
| `preRender{ClassName}` … `preRenderApplicationV2` | Before an AppV2 renders (V14); one hook per class in the chain | `(app, context, options)` |
| `render{ClassName}` … `renderApplicationV2` | After an AppV2 renders; `renderApplication` is AppV1-only | `(app, element, context, options)` |
| `renderChatMessageHTML` | Chat message rendered | `(message, html)` — core passes no third argument |
| `preCreateChatMessage` | Before chat message created | `(message, data, options, userId)` |
| `hotbarDrop` | Macro dropped on hotbar | `(bar, data, slot)` |
| `getChatMessageContextOptions` | Chat context menu | `(application, entries)` |

**Context-menu hooks fire once, at the owning app's first render.** Core UI apps first render before `ready`, so registering `get*ContextOptions` from `ready` silently does nothing. Register at import time or in `init`, and put per-open logic in the entry's `visible` predicate.

```javascript
Hooks.on('getChatMessageContextOptions', (application, entries) => {
  entries.push({
    label: 'MY_SYSTEM.ApplyDamage',        // V14: raw i18n key, core localizes
    icon: 'fa-solid fa-heart-crack',       // V14: class name, not <i> HTML
    visible: el => game.messages.get(el.dataset.messageId)?.isRoll,
    onClick: (event, el) => applyDamage(game.messages.get(el.dataset.messageId))
  })
})
```

## Settings Registration

```javascript
Hooks.once('init', () => {
  game.settings.register('my-system', 'criticalHitRule', {
    name: 'MY_SYSTEM.Settings.CriticalHitRule',
    hint: 'MY_SYSTEM.Settings.CriticalHitRuleHint',
    scope: 'world',          // world = GM only, client = per-user
    config: true,            // show in the settings UI
    type: String,
    choices: {
      double: 'MY_SYSTEM.Settings.DoubleDamage',
      maxPlusRoll: 'MY_SYSTEM.Settings.MaxPlusRoll'
    },
    default: 'double'
  })

  game.settings.register('my-system', 'schemaVersion', {
    scope: 'world', config: false, type: Number, default: 0
  })
})

const rule = game.settings.get('my-system', 'criticalHitRule')
await game.settings.set('my-system', 'schemaVersion', 2)
```

## Roll System

```javascript
const roll = new Roll('1d20 + @mod', { mod: 5 })
await roll.evaluate()
await roll.toMessage({ speaker: ChatMessage.getSpeaker({ actor }) })

// Visibility is a *message mode* in V14, not a roll mode
await roll.toMessage(
  { speaker: ChatMessage.getSpeaker({ actor }), flavor: game.i18n.localize('MY_SYSTEM.AttackRoll') },
  { messageMode: game.settings.get('core', 'messageMode') }
)
```

| V13 | V14 |
|-----|-----|
| `rollMode` option | `messageMode` option |
| `'publicroll'` / `'gmroll'` / `'blindroll'` / `'selfroll'` | `'public'` / `'gm'` / `'blind'` / `'self'` |
| `CONST.DICE_ROLL_MODES`, `CONFIG.Dice.rollModes` | `CONFIG.ChatMessage.modes` (adds `'ic'`) |
| `ChatMessage.applyRollMode()` | `ChatMessage.applyMode()` |
| `game.settings.get('core', 'rollMode')` | `game.settings.get('core', 'messageMode')` |

Booleans inside dice formulas now evaluate to `0`/`1` automatically — no manual coercion needed.

## Regions Replace Measured Templates

`MeasuredTemplate` was removed in V14 — the first core document type Foundry has ever dropped. Areas of effect are Regions:

```javascript
await canvas.scene.createEmbeddedDocuments('Region', [{
  name: game.i18n.localize('MY_SYSTEM.SpellArea'),
  shapes: [{ type: 'circle', x, y, radius: 90 }],
  behaviors: []
}])
```

Shape types: `circle`, `rectangle`, `ellipse`, `polygon`, `cone`, `ring`, `line`, `emanation`, `token`, `grid`. Regions can attach to a token, carry behaviors, and define multiple teleport destinations — none of which templates could do.

## Batched Document Updates

When several writes must not be interleaved with network latency, or must all-or-nothing:

```javascript
await foundry.documents.modifyBatch([
  { action: 'update', documentName: 'Actor', updates: [{ _id: actor.id, 'system.size': 'large' }] },
  { action: 'update', documentName: 'Token', updates: [{ _id: tokenId, width: 2, height: 2 }], parent: scene }
])
```

A batch cannot reference the result of an earlier operation in the same batch, and any cancellation or exception rolls back the whole batch.

## Compendium / Pack Management

FoundryVTT stores compendia in LevelDB. Keep JSON sources in git:

```
packs/creatures/src/goblin.json
packs/items/src/longsword.json
```

1. Edit the JSON sources
2. Compile: `fvtt package pack <pack-name>` (Foundry must be shut down)
3. Test in Foundry
4. Commit the JSON, never the LevelDB files

## CSS/SCSS Patterns

```scss
.my-system {
  color: var(--system-text-color);
  background: var(--system-background-color);

  .sheet-header {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
}
```

Declare `--system-*` tokens yourself in light and dark. **Do not build on core's `--color-text-dark-*` / `--color-border-light-*` family**: those are declared only under `body.game .app`, and V14 has no AppV1 windows, so they resolve to nothing everywhere. An invalid `var()` does not fall back down the cascade — borders and outlines simply fail to render, silently. See the appv2 skill's *CSS Theming* section.

## Internationalization (i18n)

```javascript
const label = game.i18n.localize('MY_SYSTEM.AbilityStr')
const message = game.i18n.format('MY_SYSTEM.RollResult', { actor: actorName, result: rollTotal })

// V14 adds a bound global shorthand for localize:
const label2 = _loc('MY_SYSTEM.AbilityStr')
// Also in V14, localize() accepts interpolation data and format() is an alias of it:
const message2 = game.i18n.localize('MY_SYSTEM.RollResult', { actor: actorName, result: rollTotal })
```

```handlebars
<label>{{localize "MY_SYSTEM.AbilityStr"}}</label>
```

```json
{
  "MY_SYSTEM": {
    "AbilityStr": "Strength",
    "RollResult": "{actor} rolled {result}",
    "Settings": { "CriticalHitRule": "Critical Hit Rule" }
  }
}
```

All user-facing text goes through i18n — no hardcoded strings in JS or templates.

## Testing Overview

Vitest with mocked Foundry globals:

```javascript
import { vi, describe, it, expect, beforeEach } from 'vitest'
import '../__mocks__/foundry.js'

describe('CharacterData', () => {
  beforeEach(() => vi.clearAllMocks())

  it('derives ability modifiers', () => {
    const actor = createTestActor({ abilities: { str: { value: 16 } } })
    actor.prepareData()
    expect(actor.system.abilities.str.mod).toBe(3)
  })
})
```

See **`references/testing-and-i18n.md`** for the full mock harness and i18n practices.

## Additional Resources

- **`references/v14-changes.md`** — V13→V14 for the data side: data models, Active Effects V2, Regions, chat modes, Scene Levels, full deprecation table, migration checklist
- **`references/hooks-and-documents.md`** — hooks lifecycle, document class hierarchy, embedded documents, canvas, settings API, sockets, Roll class
- **`references/testing-and-i18n.md`** — Vitest setup, mocking Foundry APIs, coverage goals, language file structure, pack workflow
