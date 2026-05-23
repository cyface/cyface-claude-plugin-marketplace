# Testing and Internationalization Reference

Complete reference for testing FoundryVTT systems with Vitest and implementing internationalization.

## Testing with Vitest

### Setup

**`vitest.config.js`:**
```javascript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['module/__tests__/**/*.test.js'],
    setupFiles: ['module/__mocks__/foundry.js']
  }
})
```

**`package.json`:**
```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest watch",
    "test:coverage": "vitest run --coverage"
  },
  "devDependencies": {
    "vitest": "^2.0.0",
    "@vitest/coverage-v8": "^2.0.0"
  }
}
```

### Mocking Foundry APIs

FoundryVTT APIs are not available in Node.js, so you need comprehensive mocks:

**`module/__mocks__/foundry.js`:**
```javascript
import { vi } from 'vitest'

// Mock the game object
global.game = {
  i18n: {
    localize: vi.fn((key) => key),
    format: vi.fn((key, data) => key)
  },
  settings: {
    get: vi.fn(),
    set: vi.fn(),
    register: vi.fn()
  },
  user: {
    id: 'test-user',
    isGM: true
  },
  actors: new Map(),
  items: new Map(),
  packs: new Map()
}

// Mock CONFIG
global.CONFIG = {
  MY_SYSTEM: {
    abilities: ['str', 'dex', 'con', 'int', 'wis', 'cha']
  }
}

// Mock CONST
global.CONST = {
  ACTIVE_EFFECT_MODES: {
    ADD: 2,
    MULTIPLY: 1,
    OVERRIDE: 5
  }
}

// Mock foundry utilities
global.foundry = {
  utils: {
    mergeObject: (target, source) => Object.assign({}, target, source),
    expandObject: (obj) => {
      const result = {}
      for (const [key, value] of Object.entries(obj)) {
        const parts = key.split('.')
        let current = result
        for (let i = 0; i < parts.length - 1; i++) {
          current[parts[i]] = current[parts[i]] || {}
          current = current[parts[i]]
        }
        current[parts[parts.length - 1]] = value
      }
      return result
    },
    getProperty: (obj, path) => {
      return path.split('.').reduce((o, k) => o?.[k], obj)
    },
    deepClone: (obj) => JSON.parse(JSON.stringify(obj))
  }
}

// Mock Roll class
global.Roll = class Roll {
  constructor(formula, data = {}) {
    this.formula = formula
    this.data = data
    this.total = 0
    this.dice = []
    this.terms = []
  }

  async evaluate() {
    this.total = global._mockRollTotal ?? 10
    return this
  }

  async toMessage() {
    return {}
  }
}

// Helper to set mock roll results
global.mockRollResult = (total) => {
  global._mockRollTotal = total
}

// Mock ChatMessage
global.ChatMessage = {
  create: vi.fn(),
  getSpeaker: vi.fn(() => ({ alias: 'Test Actor' }))
}

// Mock Actor base class
global.Actor = class Actor {
  constructor(data = {}) {
    this.name = data.name || 'Test Actor'
    this.type = data.type || 'character'
    this.system = data.system || {}
    this.items = new foundry.utils.Collection()
    this.flags = data.flags || {}
  }

  update(data) { return Promise.resolve(this) }
  createEmbeddedDocuments(type, data) { return Promise.resolve([]) }
  updateEmbeddedDocuments(type, data) { return Promise.resolve([]) }
  deleteEmbeddedDocuments(type, ids) { return Promise.resolve([]) }

  prepareData() {
    this.prepareBaseData()
    this.prepareDerivedData()
  }

  prepareBaseData() {}
  prepareDerivedData() {}
}

// Mock Item base class
global.Item = class Item {
  constructor(data = {}) {
    this.name = data.name || 'Test Item'
    this.type = data.type || 'weapon'
    this.system = data.system || {}
    this.actor = data.actor || null
  }

  update(data) { return Promise.resolve(this) }
}

// Mock Collection
foundry.utils.Collection = class Collection extends Map {
  filter(fn) {
    return Array.from(this.values()).filter(fn)
  }

  find(fn) {
    return Array.from(this.values()).find(fn)
  }

  getName(name) {
    return this.find(e => e.name === name)
  }
}
```

### Test Structure

```javascript
import { vi, describe, it, expect, beforeEach } from 'vitest'
import '../__mocks__/foundry.js'
import { MyActor } from '../actor.js'

describe('MyActor', () => {
  let actor

  beforeEach(() => {
    vi.clearAllMocks()
    actor = new MyActor({
      name: 'Test Character',
      type: 'character',
      system: {
        hp: { value: 10, max: 10 },
        abilities: {
          str: { value: 16 },
          dex: { value: 14 },
          con: { value: 12 }
        }
      }
    })
  })

  describe('prepareData', () => {
    it('should calculate ability modifiers', () => {
      // Act
      actor.prepareData()

      // Assert
      expect(actor.system.abilities.str.mod).toBe(3)
      expect(actor.system.abilities.dex.mod).toBe(2)
      expect(actor.system.abilities.con.mod).toBe(1)
    })

    it('should handle negative modifiers', () => {
      actor.system.abilities.str.value = 8

      actor.prepareData()

      expect(actor.system.abilities.str.mod).toBe(-1)
    })
  })

  describe('rollAbilityCheck', () => {
    it('should create a roll with the correct formula', async () => {
      actor.prepareData()
      global.mockRollResult(18)

      const roll = await actor.rollAbilityCheck('str')

      expect(roll.total).toBe(18)
      expect(ChatMessage.getSpeaker).toHaveBeenCalled()
    })
  })
})
```

### Testing Patterns

**Arrange/Act/Assert:**
```javascript
it('should calculate armor class', () => {
  // Arrange
  const actor = createTestActor({ armor: { ac: 15 }, abilities: { dex: { value: 14 } } })

  // Act
  actor.prepareData()

  // Assert
  expect(actor.system.ac).toBe(17)  // 15 + 2 (dex mod)
})
```

**Testing async operations:**
```javascript
it('should create a chat message on roll', async () => {
  const spy = vi.spyOn(ChatMessage, 'create')

  await actor.rollAttack()

  expect(spy).toHaveBeenCalledWith(
    expect.objectContaining({
      speaker: expect.any(Object)
    })
  )
})
```

**Testing with fixtures:**
```javascript
// module/__tests__/fixtures/test-character.json
{
  "name": "Test Fighter",
  "type": "character",
  "system": {
    "level": 5,
    "hp": { "value": 45, "max": 45 },
    "abilities": { "str": { "value": 18 } }
  }
}

// In test
import testCharacter from './fixtures/test-character.json'

it('should handle high-level character', () => {
  const actor = new MyActor(testCharacter)
  actor.prepareData()
  expect(actor.system.abilities.str.mod).toBe(4)
})
```

### Coverage Goals

| Category | Target | Rationale |
|----------|--------|-----------|
| Business Logic | 80-85% | Core calculations, parsers, data transformations |
| Document Classes | 60-70% | Methods with Foundry API calls need more mocking |
| UI Components | 40-50% | Difficult to test without browser, focus on data prep |
| Utilities | 90%+ | Pure functions, easy to test |
| Overall | 65-70% | Balance between coverage and test maintenance cost |

### Best Practices

1. **Isolate tests**: Each test should be independent — use `beforeEach` to reset state
2. **Clear mocks**: Always call `vi.clearAllMocks()` in `beforeEach`
3. **Descriptive names**: Test names should explain expected behavior
4. **Test edge cases**: Boundary conditions, empty inputs, invalid data
5. **Use fixtures**: Store complex test data in `fixtures/` directory
6. **Mock at boundaries**: Mock Foundry APIs, not your own code
7. **Test behavior, not implementation**: Focus on inputs and outputs, not internal state

## Internationalization (i18n)

### Language File Structure

**`lang/en.json`** (reference file):
```json
{
  "MY_SYSTEM": {
    "AbilityStr": "Strength",
    "AbilityDex": "Dexterity",
    "AbilityCon": "Constitution",
    "AbilityInt": "Intelligence",
    "AbilityWis": "Wisdom",
    "AbilityCha": "Charisma",
    "HP": "Hit Points",
    "AC": "Armor Class",
    "Level": "Level",
    "Name": "Name",
    "Attack": "Attack",
    "Damage": "Damage",
    "Save": "Saving Throw",
    "RollResult": "{actor} rolled {result}",
    "NewItem": "New {type}",
    "Settings": {
      "CriticalHitRule": "Critical Hit Rule",
      "CriticalHitRuleHint": "How to handle critical hits",
      "DoubleDamage": "Double Damage Dice",
      "MaxPlusRoll": "Max Damage + Roll"
    },
    "Sheet": {
      "Character": "Character Sheet",
      "NPC": "NPC Sheet",
      "Item": "Item Sheet"
    },
    "Dialog": {
      "Confirm": "Confirm",
      "Cancel": "Cancel",
      "Delete": "Delete",
      "ConfirmDelete": "Are you sure you want to delete {name}?"
    }
  }
}
```

### Using Translations

**In JavaScript:**
```javascript
// Simple key lookup
const label = game.i18n.localize('MY_SYSTEM.AbilityStr')
// Returns: "Strength"

// With interpolation
const message = game.i18n.format('MY_SYSTEM.RollResult', {
  actor: 'Gandalf',
  result: 18
})
// Returns: "Gandalf rolled 18"

// Check if key exists
const hasKey = game.i18n.has('MY_SYSTEM.SomeKey')

// For window titles in DEFAULT_OPTIONS, just use the key string
// Foundry automatically localizes it
static DEFAULT_OPTIONS = {
  window: { title: 'MY_SYSTEM.Sheet.Character' }
}
```

**In Handlebars templates:**
```handlebars
{{!-- Static key --}}
<label>{{localize "MY_SYSTEM.AbilityStr"}}</label>

{{!-- Dynamic key from context --}}
<label>{{localize abilityLabel}}</label>

{{!-- In attributes --}}
<input placeholder="{{localize 'MY_SYSTEM.Name'}}">
```

### Adding a New Language

1. Create the language file (e.g., `lang/ja.json`)
2. Copy structure from `en.json`
3. Translate ALL keys — never leave English text in non-English files
4. Register in `system.json`:

```json
{
  "languages": [
    { "lang": "en", "name": "English", "path": "lang/en.json" },
    { "lang": "de", "name": "Deutsch", "path": "lang/de.json" },
    { "lang": "ja", "name": "日本語", "path": "lang/ja.json" }
  ]
}
```

### Best Practices

**Do:**
- Use descriptive key names that indicate context
- Group related keys under common prefixes
- Keep translations consistent in tone and terminology
- Test UI with longer translations (German/French text is often 30% longer than English)
- Use `format()` for strings with variables, not string concatenation

**Don't:**
- Hardcode user-facing strings in JavaScript or templates
- Leave untranslated text in language files
- Split sentences across multiple keys (word order varies by language)
- Use abbreviations without context
- Concatenate translated fragments to build sentences

### Checking Translation Coverage

Create a comparison script or use a tool to verify all language files have matching keys:

```bash
# Example: Compare German against English
node scripts/compare-lang.js lang/en.json lang/de.json
```

A simple comparison script:
```javascript
import { readFileSync } from 'fs'

function getKeys(obj, prefix = '') {
  const keys = []
  for (const [key, value] of Object.entries(obj)) {
    const fullKey = prefix ? `${prefix}.${key}` : key
    if (typeof value === 'object' && value !== null) {
      keys.push(...getKeys(value, fullKey))
    } else {
      keys.push(fullKey)
    }
  }
  return keys
}

const reference = JSON.parse(readFileSync(process.argv[2], 'utf8'))
const target = JSON.parse(readFileSync(process.argv[3], 'utf8'))

const refKeys = new Set(getKeys(reference))
const targetKeys = new Set(getKeys(target))

const missing = [...refKeys].filter(k => !targetKeys.has(k))
const extra = [...targetKeys].filter(k => !refKeys.has(k))

if (missing.length) console.log('Missing keys:', missing)
if (extra.length) console.log('Extra keys:', extra)
if (!missing.length && !extra.length) console.log('All keys match!')
```

## Pack Management

### Directory Structure

```
packs/
+-- creatures/
|   +-- src/
|       +-- goblin.json
|       +-- dragon.json
+-- items/
|   +-- src/
|       +-- longsword.json
|       +-- leather-armor.json
+-- tables/
    +-- src/
        +-- critical-hits.json
```

### JSON to LevelDB Workflow

1. **Edit JSON source files** in `packs/*/src/`
2. **Compile** to LevelDB: use the [foundry-cli](https://github.com/foundryvtt/foundryvtt-cli)
   ```bash
   fvtt package pack <pack-name>
   ```
3. **Test** in FoundryVTT
4. **Commit** JSON changes to git (never commit LevelDB files)

### NPM Script Setup

```json
{
  "scripts": {
    "todb": "fvtt package pack creatures && fvtt package pack items && fvtt package pack tables",
    "tojson": "fvtt package unpack creatures && fvtt package unpack items && fvtt package unpack tables"
  }
}
```

### Git Tracking Rules

- **DO commit**: `packs/*/src/*.json` (human-readable source)
- **DO NOT commit**: LevelDB files (add to `.gitignore`)

```gitignore
# Compiled packs (LevelDB)
packs/*/*.db
packs/*/LOG
packs/*/LOCK
packs/*/CURRENT
packs/*/MANIFEST-*
!packs/*/src/
```

### Working with Foundry UI

If editing content in FoundryVTT's UI:

1. Run `npm run todb` to compile packs
2. Start FoundryVTT, create/load a test world
3. Make changes via the Foundry UI
4. Close FoundryVTT
5. Run `npm run tojson` to extract changes back to JSON
6. Commit the JSON changes

### Pack Registration in system.json

```json
{
  "packs": [
    {
      "name": "creatures",
      "label": "MY_SYSTEM.Packs.Creatures",
      "path": "packs/creatures",
      "type": "Actor"
    },
    {
      "name": "items",
      "label": "MY_SYSTEM.Packs.Items",
      "path": "packs/items",
      "type": "Item"
    },
    {
      "name": "tables",
      "label": "MY_SYSTEM.Packs.Tables",
      "path": "packs/tables",
      "type": "RollTable"
    }
  ]
}
```

### Troubleshooting

| Problem | Solution |
|---------|----------|
| Pack not showing in Foundry | Run `npm run todb`, check `system.json` registration, restart Foundry |
| JSON extraction failing | Make sure FoundryVTT is not running, check for locked files |
| Merge conflicts in packs | Work with JSON source files only, resolve conflicts in JSON, recompile |
| Pack data out of sync | Run `npm run tojson` before pulling, resolve, then `npm run todb` |
