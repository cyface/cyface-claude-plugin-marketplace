---
name: foundryvtt-system
description: >-
  This skill should be used when the user asks about "FoundryVTT system development",
  "FoundryVTT module", "Foundry hooks", "data model", "template.json",
  "Actor class", "Item class", "Roll class", "compendium packs",
  "game settings", "game.i18n", "localize", "i18n", "testing FoundryVTT",
  "Vitest with Foundry", "mocking Foundry", "system.json", "FoundryVTT project structure",
  "Foundry documents", "embedded documents", "settings registration",
  "Hooks.on", "Hooks.once", "game.settings.register", "game.actors",
  "game.items", "CONFIG object", "FoundryVTT canvas", "FoundryVTT API",
  "SCSS in Foundry", "language files", "translation files",
  "pack management", "LevelDB packs", "compendium JSON",
  or mentions building a game system or module for FoundryVTT.
version: 1.0.0
---

# FoundryVTT System Development Guide

This guide covers the fundamentals of building a game system or module for FoundryVTT v13. It provides patterns for project structure, data models, hooks, documents, settings, testing, and internationalization.

**Note**: This plugin is a community resource and is not affiliated with or endorsed by Foundry Gaming LLC.

## System File Structure

A typical FoundryVTT system:

```
my-system/
+-- module/               # JavaScript source
|   +-- __tests__/        # Test files (Vitest)
|   +-- __mocks__/        # Test mocks for Foundry API
|   +-- my-system.js      # Entry point (registered in system.json)
|   +-- actor.js           # Custom Actor class
|   +-- item.js            # Custom Item class
|   +-- config.js          # System constants and lookup tables
|   +-- ...
+-- templates/            # Handlebars templates (.html)
+-- styles/               # SCSS/CSS stylesheets
+-- lang/                 # Translation files (en.json, de.json, etc.)
+-- packs/                # Compendium packs
|   +-- creatures/
|   |   +-- src/           # JSON source files (tracked in git)
|   +-- items/
|       +-- src/
+-- docs/                 # Documentation
+-- system.json           # System manifest
+-- template.json         # Data model definition
```

## Data Model (template.json)

Defines the structure of Actor and Item data:

```json
{
  "Actor": {
    "types": ["character", "npc"],
    "character": {
      "hp": { "value": 10, "max": 10 },
      "level": 1,
      "abilities": {
        "str": { "value": 10 },
        "dex": { "value": 10 },
        "con": { "value": 10 },
        "int": { "value": 10 },
        "wis": { "value": 10 },
        "cha": { "value": 10 }
      },
      "biography": ""
    },
    "npc": {
      "hp": { "value": 10, "max": 10 },
      "cr": 1,
      "description": ""
    }
  },
  "Item": {
    "types": ["weapon", "armor", "spell", "equipment"],
    "weapon": {
      "damage": "1d6",
      "attackBonus": 0,
      "equipped": false
    },
    "armor": {
      "ac": 10,
      "equipped": false
    },
    "spell": {
      "level": 1,
      "description": ""
    },
    "equipment": {
      "quantity": 1,
      "weight": 0,
      "description": ""
    }
  }
}
```

Access in code: `actor.system.hp.value`, `item.system.damage`

## Document Types

### Actor
```javascript
class MyActor extends Actor {
  /** @override */
  prepareData() {
    super.prepareData()
    // Calculate derived values
    const system = this.system
    for (const [key, ability] of Object.entries(system.abilities)) {
      ability.mod = Math.floor((ability.value - 10) / 2)
    }
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
```

### Item
```javascript
class MyItem extends Item {
  /** @override */
  prepareData() {
    super.prepareData()
    // Calculate derived item values
  }

  async roll() {
    const speaker = ChatMessage.getSpeaker({ actor: this.actor })
    await ChatMessage.create({
      speaker,
      content: `<h3>${this.name}</h3><p>${this.system.description}</p>`
    })
  }
}
```

## Hooks System

### Lifecycle Hooks

```javascript
// System initialization — register classes, settings, templates
Hooks.once('init', () => {
  CONFIG.Actor.documentClass = MyActor
  CONFIG.Item.documentClass = MyItem

  // Register sheets (see ApplicationV2 skill for details)
  // Register settings
  // Load templates
})

// After all systems initialized, game data loaded
Hooks.once('ready', () => {
  // Access game.actors, game.items, etc.
  // Perform migrations
  // Display welcome messages
})
```

### Common Hooks

| Hook | When | Parameters |
|------|------|------------|
| `init` | System init, before game data | None |
| `ready` | Game fully loaded | None |
| `createActor` | Actor created | `(actor, options, userId)` |
| `updateActor` | Actor updated | `(actor, change, options, userId)` |
| `deleteActor` | Actor deleted | `(actor, options, userId)` |
| `createItem` | Item created | `(item, options, userId)` |
| `updateItem` | Item updated | `(item, change, options, userId)` |
| `deleteItem` | Item deleted | `(item, options, userId)` |
| `renderChatMessageHTML` | Chat message rendered (V13) | `(message, html, data)` |
| `preCreateChatMessage` | Before chat message created | `(message, data, options, userId)` |
| `hotbarDrop` | Macro dropped on hotbar | `(bar, data, slot)` |
| `getChatMessageContextOptions` | Context menu on chat (V13) | `(application, menuItems)` |

### Hook Patterns

```javascript
// Listen for any actor update
Hooks.on('updateActor', (actor, change, options, userId) => {
  // Only run for the triggering user
  if (userId !== game.user.id) return
  // Check what changed
  if (change.system?.hp) {
    console.log(`${actor.name} HP changed`)
  }
})

// Modify chat message context menu
Hooks.on('getChatMessageContextOptions', (application, menuItems) => {
  menuItems.push({
    name: 'MY_SYSTEM.ApplyDamage',
    icon: '<i class="fas fa-heart-broken"></i>',
    condition: element => {
      const messageId = element.dataset.messageId
      return game.messages.get(messageId)?.isRoll
    },
    callback: element => {
      const messageId = element.dataset.messageId
      const message = game.messages.get(messageId)
      // Apply damage logic
    }
  })
})
```

## Settings Registration

```javascript
Hooks.once('init', () => {
  // World-level setting (GM only)
  game.settings.register('my-system', 'criticalHitRule', {
    name: 'MY_SYSTEM.Settings.CriticalHitRule',
    hint: 'MY_SYSTEM.Settings.CriticalHitRuleHint',
    scope: 'world',     // world = GM only, client = per-user
    config: true,        // Show in settings UI
    type: String,
    choices: {
      double: 'MY_SYSTEM.Settings.DoubleDamage',
      maxPlusRoll: 'MY_SYSTEM.Settings.MaxPlusRoll'
    },
    default: 'double'
  })

  // Client-level setting (per user)
  game.settings.register('my-system', 'showDamageOverlay', {
    name: 'MY_SYSTEM.Settings.ShowDamageOverlay',
    scope: 'client',
    config: true,
    type: Boolean,
    default: true
  })

  // Hidden setting (not shown in UI)
  game.settings.register('my-system', 'schemaVersion', {
    scope: 'world',
    config: false,
    type: Number,
    default: 0
  })
})

// Read settings
const rule = game.settings.get('my-system', 'criticalHitRule')

// Write settings
await game.settings.set('my-system', 'schemaVersion', 2)
```

## Roll System

```javascript
// Basic roll
const roll = new Roll('1d20 + @mod', { mod: 5 })
await roll.evaluate()
await roll.toMessage({ speaker: ChatMessage.getSpeaker({ actor }) })

// Roll with flavor text
const roll = new Roll('2d6 + @bonus', { bonus: actor.system.attackBonus })
await roll.evaluate()
await roll.toMessage({
  speaker: ChatMessage.getSpeaker({ actor }),
  flavor: game.i18n.localize('MY_SYSTEM.AttackRoll')
})

// Inline rolls in chat
await ChatMessage.create({
  content: `<p>Damage: [[/r 1d8 + 3]]</p>`,
  speaker: ChatMessage.getSpeaker({ actor })
})
```

## Compendium / Pack Management

FoundryVTT uses LevelDB for compendium storage. Maintain JSON source files in git:

```
packs/
+-- creatures/
|   +-- src/
|       +-- goblin.json
|       +-- dragon.json
+-- items/
    +-- src/
        +-- longsword.json
```

**Workflow:**
1. Edit JSON source files in `packs/*/src/`
2. Compile to LevelDB: `fvtt package pack <pack-name>`
3. Test in FoundryVTT
4. Commit JSON changes to git

**Git tracking:**
- DO commit: `packs/*/src/*.json`
- DO NOT commit: LevelDB files (`.db`)

## CSS/SCSS Patterns

Edit SCSS source files, compile to CSS:

```scss
.my-system {
  // Use CSS variables for theming
  color: var(--system-text-color);
  background: var(--system-background-color);

  .sheet-header {
    display: flex;
    align-items: center;
    gap: 0.5rem;

    .profile-img {
      width: 100px;
      height: 100px;
      object-fit: cover;
      border: 2px solid var(--system-border-color);
    }
  }

  .item-list {
    list-style: none;
    padding: 0;

    .item {
      display: flex;
      align-items: center;
      gap: 0.25rem;
      padding: 0.25rem;
      border-bottom: 1px solid var(--system-border-color);
    }
  }
}
```

## Internationalization (i18n)

All user-facing text must use the i18n system:

```javascript
// Simple localization
const label = game.i18n.localize('MY_SYSTEM.AbilityStr')

// With formatting
const message = game.i18n.format('MY_SYSTEM.RollResult', {
  actor: actorName,
  result: rollTotal
})
```

```handlebars
{{!-- In templates --}}
<label>{{localize "MY_SYSTEM.AbilityStr"}}</label>
```

**Language files** (`lang/en.json`):
```json
{
  "MY_SYSTEM": {
    "AbilityStr": "Strength",
    "AbilityDex": "Dexterity",
    "RollResult": "{actor} rolled {result}",
    "Settings": {
      "CriticalHitRule": "Critical Hit Rule"
    }
  }
}
```

## Testing Overview

Use Vitest with mocks for the FoundryVTT API:

```javascript
import { vi, describe, it, expect, beforeEach } from 'vitest'
import '../__mocks__/foundry.js'

describe('MyActor', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should calculate ability modifiers', () => {
    // Arrange
    const actor = createTestActor({ abilities: { str: { value: 16 } } })

    // Act
    actor.prepareData()

    // Assert
    expect(actor.system.abilities.str.mod).toBe(3)
  })
})
```

See **`references/testing-and-i18n.md`** for comprehensive testing and i18n patterns.

## Additional Resources

### Reference Files
- **`references/hooks-and-documents.md`** — Complete hooks lifecycle, document class hierarchy, embedded documents, canvas system, game object patterns, settings API, socket communication, Roll class
- **`references/testing-and-i18n.md`** — Vitest setup, mocking Foundry APIs, test patterns, coverage goals, language file structure, localization best practices, pack management workflow
