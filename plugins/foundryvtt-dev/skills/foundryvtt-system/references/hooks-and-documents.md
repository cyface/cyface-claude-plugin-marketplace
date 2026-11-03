# Hooks and Documents Reference

Reference for the FoundryVTT hooks lifecycle, the full document hierarchy, and core APIs. Targets **V14** (last-verified build: see the plugin README).

## Hooks Lifecycle

### Initialization Phase

```
init               → System initialization (register classes, data models, settings, sheets, templates)
i18nInit           → Translations loaded (fires from game.i18n.initialize(), right after init)
setup              → Game data available, UI about to render (document collections initialized)
ready              → Game fully loaded; canvas drawn and any scene transition finished
```

Order verified in `client/game.mjs`: `init`, then `i18n.initialize()` (fires `i18nInit`), then `setup`, then `ready`. Core UI apps (sidebar, chat, players) first render between `setup` and `ready`, which is why context-menu hooks must already be registered by `init`.

### Document Lifecycle Hooks

For each document type (Actor, Item, ChatMessage, etc.), these hooks fire in order:

```
pre{Action}{Type}    → Before the action (can cancel by returning false)
{action}{Type}       → After the action completes
```

**Actions**: `Create`, `Update`, `Delete`

```javascript
// Example: Actor creation lifecycle
Hooks.on('preCreateActor', (actor, data, options, userId) => {
  // Modify data before creation
  // Return false to cancel
})

Hooks.on('createActor', (actor, options, userId) => {
  // React to creation
})
```

### Render Hooks

ApplicationV2 fires `render{ClassName}` once per class in the inheritance chain, stopping at
`ApplicationV2`. So a `MyActorSheet extends HandlebarsApplicationMixin(ActorSheetV2)` render fires
`renderMyActorSheet`, `renderActorSheetV2`, `renderDocumentSheetV2`, and `renderApplicationV2`.
`renderApplication` is the **AppV1** hook and never fires for V2 apps.

```javascript
// Fires when any ApplicationV2 renders — note the signature: element, not html; context, not data
Hooks.on('renderApplicationV2', (app, element, context, options) => { })

// Fires for a specific application class (and each of its V2 ancestors)
Hooks.on('renderMyActorSheet', (app, element, context, options) => { })

// V14: fires before an ApplicationV2 renders, same per-class pattern (preRenderMyActorSheet … preRenderApplicationV2)
Hooks.on('preRenderApplicationV2', (app, context, options) => { })

// Chat message HTML (V13+ name; the V12 `renderChatMessage` is gone)
Hooks.on('renderChatMessageHTML', (message, html) => {
  // html is a DOM element (not jQuery); core passes no third argument
  const content = html.querySelector('.message-content')
})
```

### Context Menu Hooks

`get{DocumentName}ContextOptions` hooks fire **once, at the owning application's first
render** — not each time the menu opens. Core UI apps first render during boot, before
`ready`, so registering one of these from `ready` silently does nothing. Register at
import time or in `init`, and put per-open logic in `visible`.

```javascript
Hooks.on('getActorContextOptions', (application, entries) => {
  entries.push({
    label: 'MY_SYSTEM.QuickLevelUp',      // V14: raw i18n key, core localizes it
    icon: 'fa-solid fa-arrow-up',         // V14: class name, not <i> HTML
    visible: el => game.user.isGM,        // V14: was `condition`; evaluated per open
    onClick: (event, el) => levelUp(el.dataset.entryId)   // V14: was `callback`
  })
})
```

### Combat Hooks

```javascript
Hooks.on('updateCombat', (combat, change, options, userId) => {
  if (change.round) {
    // New round started
  }
  if (change.turn !== undefined) {
    // Turn changed
  }
})

Hooks.on('deleteCombat', (combat, options, userId) => {
  // Combat ended
})
```

### Canvas Hooks

```javascript
Hooks.on('canvasInit', (canvas) => { })
Hooks.on('canvasReady', (canvas) => { })
Hooks.on('canvasPan', (canvas, position) => { })
Hooks.on('targetToken', (user, token, targeted) => { })
Hooks.on('controlToken', (token, controlled) => { })
```

### Hotbar Hook

```javascript
Hooks.on('hotbarDrop', (bar, data, slot) => {
  if (data.type === 'Item') {
    // Create a macro for the dropped item
    createItemMacro(data, slot)
    return false  // Prevent default behavior
  }
})
```

## Document Class Hierarchy

All 16 primary (world-level) document types in V14, with the embedded documents each one owns
(collection name in parentheses). Source: `CONST.PRIMARY_DOCUMENT_TYPES`, `CONST.EMBEDDED_DOCUMENT_TYPES`,
and each document's `metadata.embedded`.

```
Document (Base)
+-- Actor
|   +-- Item (items)
|   |   +-- ActiveEffect (effects)
|   +-- ActiveEffect (effects)
+-- Item
|   +-- ActiveEffect (effects)
+-- Adventure
+-- Cards
|   +-- Card (cards)
+-- ChatMessage
+-- Combat
|   +-- Combatant (combatants)
|   +-- CombatantGroup (groups)
+-- FogExploration
+-- Folder
+-- JournalEntry
|   +-- JournalEntryPage (pages)
|   +-- JournalEntryCategory (categories)
+-- Macro
+-- Playlist
|   +-- PlaylistSound (sounds)
+-- RollTable
|   +-- TableResult (results)
+-- Scene
|   +-- Token (tokens)
|   |   +-- ActorDelta (delta) — the synthetic actor's overrides; owns its own items and effects
|   +-- Level (levels) — Scene Levels, new in V14
|   +-- Region (regions) — replaces MeasuredTemplate in V14
|   |   +-- RegionBehavior (behaviors)
|   +-- Tile (tiles)
|   +-- Wall (walls)
|   +-- Drawing (drawings)
|   +-- Note (notes)
|   +-- AmbientLight (lights)
|   +-- AmbientSound (sounds)
+-- Setting
+-- User
```

`MeasuredTemplate` was **removed in V14** (`MeasuredTemplateDocument` and `Scene#templates` remain as
deprecated shells until V16); areas of effect are Regions with shapes
(`circle`, `rectangle`, `ellipse`, `polygon`, `cone`, `ring`, `line`, `emanation`, `token`, `grid`).

### Custom Document Classes

Register in `init` hook:

```javascript
Hooks.once('init', () => {
  CONFIG.Actor.documentClass = MyActor
  CONFIG.Item.documentClass = MyItem

  // V14: subtype schemas come from TypeDataModel classes, not template.json
  CONFIG.Actor.dataModels = { character: CharacterData, npc: NPCData }
  CONFIG.Item.dataModels = { weapon: WeaponData, armor: ArmorData }
})
```

Any `prepareBaseData()` override on a document class **must** call
`super.prepareBaseData()` — V14 resets Active Effect phase tracking there, and skipping
it throws *"phase has already completed"* on the second preparation cycle.

### Common Document Operations

```javascript
// Create
const actor = await Actor.create({
  name: 'New Character',
  type: 'character',
  system: { hp: { value: 10, max: 10 } }
})

// Read
const actor = game.actors.get(actorId)
const actor = game.actors.getName('Character Name')

// Update
await actor.update({ 'system.hp.value': 5 })

// Delete
await actor.delete()
```

### Embedded Documents

Items and ActiveEffects are embedded within Actors:

```javascript
// Create embedded item
await actor.createEmbeddedDocuments('Item', [{
  name: 'Longsword',
  type: 'weapon',
  system: { damage: '1d8', equipped: true }
}])

// Get embedded items
const weapons = actor.items.filter(i => i.type === 'weapon')
const item = actor.items.get(itemId)

// Update embedded item
await actor.updateEmbeddedDocuments('Item', [{
  _id: itemId,
  'system.equipped': true
}])

// Bulk update multiple items
await actor.updateEmbeddedDocuments('Item', [
  { _id: item1Id, 'system.quantity': 5 },
  { _id: item2Id, 'system.equipped': false }
])

// Delete embedded item
await actor.deleteEmbeddedDocuments('Item', [itemId])

// Active Effects — V14 shape: changes live in system data with string types
await actor.createEmbeddedDocuments('ActiveEffect', [{
  name: 'Blessed',
  img: 'icons/svg/aura.svg',
  system: {
    changes: [{
      key: 'system.abilities.str.value',
      type: 'add',          // was: mode: CONST.ACTIVE_EFFECT_MODES.ADD
      value: 2,
      phase: 'initial'      // 'initial' (base values) or 'final' (derived values)
    }]
  }
}])

// Reading effects
for (const effect of actor.allApplicableEffects()) {
  for (const change of effect.system?.changes ?? []) {
    if (change.type === 'add') { /* … */ }
  }
}
```

### Batched Modifications (V14)

When multiple writes must not be interleaved with network latency, or must succeed or
fail together:

```javascript
await foundry.documents.modifyBatch([
  { action: 'update', documentName: 'Actor', updates: [{ _id: actor.id, 'system.size': 'large' }] },
  { action: 'update', documentName: 'Token', updates: [{ _id: tokenId, width: 2, height: 2 }], parent: scene }
])
```

A batch cannot reference the result of an earlier operation within the same batch, and
any cancellation or exception rolls the whole batch back.

## Game Object

The global `game` object provides access to all game data:

```javascript
game.system.id          // System ID
game.system.version     // System version
game.user               // Current user
game.user.isGM          // Is current user a GM?

// Document collections
game.actors             // All actors
game.items              // All items (world-level)
game.scenes             // All scenes
game.macros             // All macros
game.journal            // All journal entries
game.tables             // All rollable tables
game.playlists          // All playlists
game.messages           // All chat messages
game.combats            // All combats
game.users              // All users
game.folders            // All folders
game.packs              // All compendium packs

// Utilities
game.i18n.localize('KEY')           // Translate a key
game.i18n.format('KEY', { data })   // Translate with interpolation
game.settings.get('my-system', 'key')  // Read a setting (namespace = your system/module id)
game.settings.set('my-system', 'key', value)  // Write a setting
```

## Settings API

### Registration

```javascript
Hooks.once('init', () => {
  // Boolean setting
  game.settings.register('my-system', 'autoRollDamage', {
    name: 'MY_SYSTEM.Settings.AutoRollDamage',
    hint: 'MY_SYSTEM.Settings.AutoRollDamageHint',
    scope: 'client',
    config: true,
    type: Boolean,
    default: false
  })

  // String with choices
  game.settings.register('my-system', 'initiativeFormula', {
    name: 'MY_SYSTEM.Settings.InitiativeFormula',
    scope: 'world',
    config: true,
    type: String,
    choices: {
      '1d20': '1d20',
      '2d6': '2d6',
      '1d20+@dex': '1d20 + Dex'
    },
    default: '1d20'
  })

  // Number with range
  game.settings.register('my-system', 'maxInventorySlots', {
    name: 'MY_SYSTEM.Settings.MaxInventory',
    scope: 'world',
    config: true,
    type: Number,
    range: { min: 5, max: 50, step: 1 },
    default: 20
  })

  // Hidden setting (programmatic only)
  game.settings.register('my-system', 'migrationVersion', {
    scope: 'world',
    config: false,
    type: Number,
    default: 0
  })

  // Settings menu (opens custom ApplicationV2)
  game.settings.registerMenu('my-system', 'advancedConfig', {
    name: 'MY_SYSTEM.Settings.AdvancedConfig',
    label: 'MY_SYSTEM.Settings.Configure',
    icon: 'fa-solid fa-gears',
    type: MyAdvancedConfigApp,
    restricted: true  // GM only
  })
})
```

### Access

```javascript
// Read
const autoRoll = game.settings.get('my-system', 'autoRollDamage')

// Write (async)
await game.settings.set('my-system', 'migrationVersion', 2)

// onChange callback
game.settings.register('my-system', 'theme', {
  // ...
  onChange: (value) => {
    // React to setting change
    document.body.classList.toggle('dark-mode', value === 'dark')
  }
})
```

## Socket Communication

For multi-user synchronization beyond document updates:

```javascript
// Register socket handler in init
Hooks.once('init', () => {
  game.socket.on('system.my-system', handleSocketMessage)
})

function handleSocketMessage(data) {
  switch (data.action) {
    case 'requestRoll':
      // Handle roll request from another user
      break
    case 'applyDamage':
      if (game.user.isGM) {
        // Only GM processes damage
        applyDamageToToken(data.tokenId, data.amount)
      }
      break
  }
}

// Send message
game.socket.emit('system.my-system', {
  action: 'applyDamage',
  tokenId: token.id,
  amount: 15
})
```

## Roll Class

### Basic Rolls

```javascript
// Simple roll
const roll = new Roll('1d20')
await roll.evaluate()
console.log(roll.total)  // e.g., 15

// Roll with data
const roll = new Roll('1d20 + @mod + @bonus', {
  mod: 3,
  bonus: 2
})
await roll.evaluate()

// Send to chat
await roll.toMessage({
  speaker: ChatMessage.getSpeaker({ actor }),
  flavor: game.i18n.localize('MY_SYSTEM.AttackRoll')
})

// V14: visibility is a *message mode*, not a roll mode
await roll.toMessage(
  { speaker: ChatMessage.getSpeaker({ actor }) },
  { messageMode: game.settings.get('core', 'messageMode') }   // 'public' | 'gm' | 'blind' | 'self' | 'ic'
)
```

Booleans inside dice formulas evaluate to `0`/`1` automatically in V14.

### Roll Formulas

```javascript
'1d20'              // Single die
'2d6 + 3'           // Multiple dice + modifier
'1d20 + @mod'       // With data reference
'4d6kh3'            // Keep highest 3
'2d20kl1'           // Keep lowest 1
'1d6!'              // Exploding dice
'1d6!!'             // Compounding exploding
'(1d6 + 2) * 2'     // Math expressions
'{2d20, 3d10}kh'    // Dice pools
```

### Custom Roll Classes

```javascript
class MySystemRoll extends Roll {
  /** @override */
  async evaluate(options = {}) {
    const result = await super.evaluate(options)
    // Add custom logic (critical detection, etc.)
    return result
  }
}

// Register in init
Hooks.once('init', () => {
  CONFIG.Dice.rolls.push(MySystemRoll)
})
```

## Canvas System Overview

```javascript
// Access the canvas
canvas.scene          // Current scene
canvas.tokens         // Token layer
canvas.tiles          // Tile layer
canvas.lighting       // Lighting layer
canvas.grid           // Grid configuration

// Token operations
const token = canvas.tokens.get(tokenId)
token.document.update({ x: 100, y: 200 })

// Measure distance — measurePath returns a GridMeasurePathResult, not a number
const result = canvas.grid.measurePath([
  { x: token1.x, y: token1.y },
  { x: token2.x, y: token2.y }
])
const distance = result.distance      // in scene units; also .spaces, .cost, .diagonals

// Get controlled tokens
const controlled = canvas.tokens.controlled
```

## Template Loading

```javascript
Hooks.once('init', () => {
  // Preload partials
  foundry.applications.handlebars.loadTemplates([
    'systems/my-system/templates/partials/ability-score.hbs',
    'systems/my-system/templates/partials/item-row.hbs'
  ])
})
```

Use in templates:
```handlebars
{{> "systems/my-system/templates/partials/ability-score.hbs" ability=str}}
```

V14 removed the `{{select}}` and `{{colorPicker}}` helpers — use `{{selectOptions}}` and
the `<color-picker>` element instead.

## Compendium Access

```javascript
// Get a pack
const pack = game.packs.get('my-system.creatures')

// Get index (lightweight)
const index = await pack.getIndex()

// Get a specific document
const doc = await pack.getDocument(documentId)

// Search by name
const entry = index.find(e => e.name === 'Goblin')
const goblin = await pack.getDocument(entry._id)

// Import to world
const worldActor = await Actor.create(goblin.toObject())
```
