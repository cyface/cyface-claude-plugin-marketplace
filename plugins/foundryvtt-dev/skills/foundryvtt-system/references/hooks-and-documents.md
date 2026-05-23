# Hooks and Documents Reference

Complete reference for FoundryVTT hooks lifecycle, document classes, and core APIs.

## Hooks Lifecycle

### Initialization Phase

```
setup              → Early initialization (before init)
init               → System initialization (register classes, settings, templates)
i18nInit           → Localization system ready
ready              → Game fully loaded, all data available
```

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

### Render Hooks (V13)

```javascript
// Fires when any application renders
Hooks.on('renderApplication', (app, html, data) => { })

// Fires for specific application class
Hooks.on('renderMyActorSheet', (app, html, data) => { })

// Chat message HTML (V13 name)
Hooks.on('renderChatMessageHTML', (message, html, data) => {
  // html is a DOM element (not jQuery)
  const content = html.querySelector('.message-content')
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

```
Document (Base)
+-- Actor
+-- Item
+-- ChatMessage
+-- Combat
+-- Combatant
+-- Scene
+-- Token (embedded in Scene)
+-- JournalEntry
+-- JournalEntryPage
+-- Macro
+-- Playlist
+-- PlaylistSound
+-- RollTable
+-- TableResult
+-- ActiveEffect (embedded in Actor or Item)
+-- User
+-- Folder
```

### Custom Document Classes

Register in `init` hook:

```javascript
Hooks.once('init', () => {
  CONFIG.Actor.documentClass = MyActor
  CONFIG.Item.documentClass = MyItem
})
```

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

// Active Effects
await actor.createEmbeddedDocuments('ActiveEffect', [{
  name: 'Blessed',
  icon: 'icons/svg/aura.svg',
  changes: [{
    key: 'system.abilities.str.value',
    mode: CONST.ACTIVE_EFFECT_MODES.ADD,
    value: '2'
  }]
}])
```

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
game.settings.get('system', 'key')  // Read a setting
game.settings.set('system', 'key', value)  // Write a setting
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
    icon: 'fas fa-cogs',
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
  flavor: 'Attack Roll'
})
```

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

// Measure distance
const distance = canvas.grid.measurePath([
  { x: token1.x, y: token1.y },
  { x: token2.x, y: token2.y }
])

// Get controlled tokens
const controlled = canvas.tokens.controlled
```

## Template Loading

```javascript
Hooks.once('init', () => {
  // Preload partials
  foundry.applications.handlebars.loadTemplates([
    'systems/my-system/templates/partials/ability-score.html',
    'systems/my-system/templates/partials/item-row.html'
  ])
})
```

Use in templates:
```handlebars
{{> "systems/my-system/templates/partials/ability-score.html" ability=str}}
```

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
