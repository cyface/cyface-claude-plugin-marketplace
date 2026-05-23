---
name: appv2
description: >-
  This skill should be used when the user asks about "ApplicationV2", "ActorSheetV2",
  "ItemSheetV2", "DocumentSheetV2", "DialogV2", "DEFAULT_OPTIONS", "PARTS",
  "data-action", "_prepareContext", "HandlebarsApplicationMixin",
  "sheet registration", "form handling in Foundry", "tabs in Foundry sheets",
  "drag and drop in Foundry", "V12 to V13 migration", "migrate to V13",
  "convert to ApplicationV2", "ProseMirror editor", "submitOnChange",
  "tag form", "actions system", "editImage", "_processFormData",
  "_processSubmitData", "inline item editing", "CSS theming in Foundry",
  "theme variables", "CSS layers", or mentions FoundryVTT V13 application
  classes, sheet patterns, or migration from V12 to V13.
version: 1.0.0
---

# FoundryVTT V13 ApplicationV2 Development Guide

FoundryVTT V13 introduces ApplicationV2 — a complete rewrite of the application layer. It replaces jQuery with plain DOM, introduces declarative actions, template parts, and a new tab system. All new development should use ApplicationV2.

## Class Hierarchy

Choose the right base class for your use case:

```
ApplicationV2 (Base)           -> Configuration dialogs, custom tools
+-- DocumentSheetV2            -> Journal entries, other documents
|   +-- ActorSheetV2           -> Actor character sheets (auto drag/drop)
|   +-- ItemSheetV2            -> Item editing sheets
+-- DialogV2                   -> User prompts, confirmations
```

### Quick Reference

```javascript
// For actor sheets
const { HandlebarsApplicationMixin } = foundry.applications.api
const { ActorSheetV2 } = foundry.applications.sheets
class MyActorSheet extends HandlebarsApplicationMixin(ActorSheetV2) { }

// For item sheets
const { ItemSheetV2 } = foundry.applications.sheets
class MyItemSheet extends HandlebarsApplicationMixin(ItemSheetV2) { }

// For configuration dialogs
const { ApplicationV2, HandlebarsApplicationMixin } = foundry.applications.api
class MyConfigDialog extends HandlebarsApplicationMixin(ApplicationV2) { }

// For user prompts
class MyPrompt extends DialogV2 { }
```

## HandlebarsApplicationMixin

Always mix in `HandlebarsApplicationMixin` for template rendering. It provides the `PARTS` system and Handlebars template support.

```javascript
const { HandlebarsApplicationMixin } = foundry.applications.api
class MySheet extends HandlebarsApplicationMixin(ActorSheetV2) { }
```

## DEFAULT_OPTIONS

Replaces `defaultOptions` getter. Defined as a static property:

```javascript
static DEFAULT_OPTIONS = {
  classes: ['my-system', 'sheet', 'actor'],
  position: {
    width: 600,
    height: 600
  },
  window: {
    resizable: true,
    title: 'MY_SYSTEM.SheetTitle'  // Localization key
  },
  actions: {
    rollAbilityCheck: this.#rollAbilityCheck,
    itemCreate: this.#itemCreate,
    itemDelete: this.#itemDelete
  }
}
```

**For forms and dialogs**, add `tag: 'form'`:

```javascript
static DEFAULT_OPTIONS = {
  tag: 'form',  // REQUIRED for forms
  form: {
    submitOnChange: true,   // Auto-save on field change (sheets)
    closeOnSubmit: false     // Keep open after submit (sheets)
  }
}
```

## PARTS (Template Definitions)

Define template parts instead of a single template:

```javascript
static PARTS = {
  tabs: {
    template: 'systems/my-system/templates/actor-partial-tabs.html'
  },
  character: {
    template: 'systems/my-system/templates/actor-partial-character.html'
  },
  equipment: {
    template: 'systems/my-system/templates/actor-partial-equipment.html'
  }
}
```

**Important**: Cannot use CONFIG values in static initializers — hard-code template paths:

```javascript
// BROKEN — CONFIG is undefined during static initialization
static PARTS = {
  form: { template: CONFIG.MY_SYSTEM.templates.dialog }  // ERROR
}

// CORRECT — Hard-coded path
static PARTS = {
  form: { template: 'systems/my-system/templates/dialog.html' }
}
```

## _prepareContext() (Replaces getData)

```javascript
async _prepareContext(options) {
  const context = await super._prepareContext(options)
  context.system = this.actor.system    // For ActorSheetV2
  context.flags = this.actor.flags
  context.editable = this.isEditable
  return context
}
```

For enriched HTML content (ProseMirror editors):

```javascript
const { TextEditor } = foundry.applications.ux

async _prepareContext(options) {
  const context = await super._prepareContext(options)
  context.descriptionHTML = await TextEditor.enrichHTML(
    this.document.system.description,
    { secrets: this.document.isOwner, relativeTo: this.document }
  )
  return context
}
```

## Actions System (Replaces activateListeners)

Declare actions in `DEFAULT_OPTIONS` and use `data-action` in templates:

```javascript
static DEFAULT_OPTIONS = {
  actions: {
    rollAbilityCheck: this.#rollAbilityCheck,
    editItem: this.#editItem,
    deleteItem: this.#deleteItem
  }
}

/**
 * @this {MyActorSheet}
 * @param {PointerEvent} event
 * @param {HTMLElement} target
 */
static async #rollAbilityCheck(event, target) {
  event.preventDefault()
  const ability = target.dataset.ability
  await this.actor.rollAbilityCheck(ability)
}
```

**Template:**
```html
<span data-action="rollAbilityCheck" data-ability="str">Strength</span>
<button data-action="deleteItem" data-item-id="{{item._id}}">Delete</button>
```

## Form Handling

### Pattern 1: Auto-Submit (Actor/Item Sheets)

```javascript
static DEFAULT_OPTIONS = {
  tag: 'form',
  form: { submitOnChange: true }
}
// No handler needed — ActorSheetV2/ItemSheetV2 handle updates automatically
```

### Pattern 2: Explicit Submit (Dialogs)

```javascript
static DEFAULT_OPTIONS = {
  tag: 'form',
  form: {
    handler: MyDialog.#onSubmitForm,
    closeOnSubmit: true,
    submitOnChange: false
  }
}

/**
 * @this {MyDialog}
 * @param {SubmitEvent} event
 * @param {HTMLFormElement} form
 * @param {FormDataExtended} formData
 */
static async #onSubmitForm(event, form, formData) {
  event.preventDefault()
  await this.options.document.update(formData.object)
}
```

**Template requirement**: When using `tag: 'form'`, templates must NOT contain `<form>` elements:

```html
<!-- WRONG: Nested forms are invalid HTML -->
<form class="config-dialog">...</form>

<!-- CORRECT: Use section or div -->
<section class="config-dialog">...</section>
```

## Tab System

### Configuration

```javascript
static TABS = {
  sheet: {
    tabs: [
      { id: 'character', group: 'sheet', label: 'MY_SYSTEM.Character' },
      { id: 'equipment', group: 'sheet', label: 'MY_SYSTEM.Equipment' },
      { id: 'notes', group: 'sheet', label: 'MY_SYSTEM.Notes' }
    ],
    initial: 'character'
  }
}

static PARTS = {
  tabs: { template: 'systems/my-system/templates/partial-tabs.html' },
  character: { template: 'systems/my-system/templates/partial-character.html' },
  equipment: { template: 'systems/my-system/templates/partial-equipment.html' },
  notes: { template: 'systems/my-system/templates/partial-notes.html' }
}
```

### Tab Navigation Template

```html
<nav class="tabs sheet-tabs" data-group="{{tabs.sheet.group}}">
  {{#each tabs.sheet.tabs}}
    <a class="tab {{this.cssClass}}" data-tab="{{this.id}}" data-group="{{this.group}}">
      {{localize this.label}}
    </a>
  {{/each}}
</nav>
```

### Tab Content Template

Each tab template must have exactly one root element with proper attributes:

```html
<section class="tab {{tabs.character.id}} {{tabs.character.cssClass}}"
         data-tab="{{tabs.character.id}}"
         data-group="{{tabs.character.group}}">
  <!-- Tab content -->
</section>
```

**CSS Warning**: If parent elements have `display: grid` or `display: flex`, ALL tabs will be visible at once. Apply layout styles to inner elements, not tab containers.

## Drag and Drop

### ActorSheetV2 (Automatic)

ActorSheetV2 provides automatic drag/drop for items and effects. Just add the right attributes:

```html
<li class="item draggable" data-item-id="{{item._id}}">{{item.name}}</li>
<li class="effect draggable" data-effect-id="{{effect._id}}">{{effect.name}}</li>
```

### ApplicationV2 (Manual Setup)

For non-actor apps, set up drag/drop manually. See **`references/appv2-patterns.md`** for the full pattern.

## Image Editing

Use the inherited `editImage` method from DocumentSheetV2:

```javascript
static DEFAULT_OPTIONS = {
  actions: {
    editImage: MySheetClass.editImage  // Inherited static method
  }
}
```

```html
<img src="{{img}}" data-action="editImage" data-edit="img" alt="Portrait">
```

## ProseMirror Editor

```html
{{#if editable}}
  <prose-mirror
    name="system.description"
    button="true"
    editable="{{editable}}"
    toggled="false"
    value="{{system.description}}">
    {{{descriptionHTML}}}
  </prose-mirror>
{{else}}
  {{{descriptionHTML}}}
{{/if}}
```

## Sheet Registration

All systems must explicitly register sheets in the `init` hook:

```javascript
Hooks.once('init', () => {
  const { Actors, Items } = foundry.documents.collections
  const { ActorSheetV2, ItemSheetV2 } = foundry.applications.sheets

  // Unregister core sheets
  Actors.unregisterSheet('core', ActorSheetV2)
  Items.unregisterSheet('core', ItemSheetV2)

  // Register system sheets
  Actors.registerSheet('my-system', MyActorSheet, {
    types: ['character'],
    makeDefault: true,
    label: 'MY_SYSTEM.SheetCharacter'
  })

  Items.registerSheet('my-system', MyItemSheet, {
    makeDefault: true,
    label: 'MY_SYSTEM.SheetItem'
  })
})
```

## Constructor Pattern

ApplicationV2 takes ALL parameters in a single options object:

```javascript
// V1 (WRONG for V2)
new MyConfig(this.actor, { position: { ... } })

// V2 (CORRECT)
new MyConfig({
  document: this.actor,
  position: { ... }
})
```

## CSS Theming

V13 introduces CSS layers. Create a `variables.css` with a `system-` prefix for custom properties:

```css
:root {
  --system-primary-color: #1c1c1c;
  --system-background-color: #ffffff;
  --system-border-color: #cccccc;
}

.theme-dark {
  --system-primary-color: #e0e0e0;
  --system-background-color: #2d2d2d;
  --system-border-color: #555555;
}
```

Register in `system.json`:
```json
{
  "styles": [
    { "src": "styles/variables.css", "layer": "variables" },
    { "src": "styles/my-system.css", "layer": "system" }
  ]
}
```

## Additional Resources

### Reference Files
- **`references/appv2-migration.md`** — Complete V12-to-V13 migration reference: breaking changes, method-by-method mapping, hook renames, namespace changes
- **`references/appv2-patterns.md`** — Code patterns with complete examples: actor sheets, item sheets, dialogs, inline item editing, multi-tab sheets, manual drag-drop, form submission
