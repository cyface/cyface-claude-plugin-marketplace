---
name: appv2
description: >-
  This skill should be used when the user asks about "ApplicationV2", "ActorSheetV2",
  "ItemSheetV2", "DocumentSheetV2", "DialogV2", "DEFAULT_OPTIONS", "PARTS",
  "data-action", "_prepareContext", "_preparePartContext", "HandlebarsApplicationMixin",
  "sheet registration", "form handling in Foundry", "tabs in Foundry sheets",
  "drag and drop in Foundry", "V13 to V14 migration", "migrate to V14",
  "V12 to V13 migration", "convert to ApplicationV2", "detached window",
  "pop-out sheet", "ProseMirror editor", "submitOnChange", "tag form",
  "actions system", "editImage", "_processFormData", "_processSubmitData",
  "inline item editing", "CSS theming in Foundry", "theme variables",
  "CSS layers", or mentions FoundryVTT V13/V14 application classes, sheet
  patterns, or migration between generations.
---

# FoundryVTT V14 ApplicationV2 Development Guide

Target: **FoundryVTT V14** (last-verified build: see the plugin README). ApplicationV2 is the application layer — plain DOM, declarative actions, template parts, and a tab system driven by `static TABS`.

ApplicationV1 (`Application`, `FormApplication`, `Dialog`, `DocumentSheet`) still loads in V14 but is deprecated with **removal targeted for V16**. All new work uses ApplicationV2. V14 ships no core AppV1 windows: in a running world every app root is `.application`, and `.app` matches nothing (this has real CSS consequences — see [CSS Theming](#css-theming)).

Migrating an existing package? See **`references/appv2-migration.md`** for both V13→V14 and V12→V13.

## Class Hierarchy

```
ApplicationV2 (Base)           -> Configuration dialogs, custom tools
+-- DocumentSheetV2            -> Journal entries, other documents
|   +-- ActorSheetV2           -> Actor character sheets (auto drag/drop)
|   +-- ItemSheetV2            -> Item editing sheets
+-- DialogV2                   -> User prompts, confirmations
```

```javascript
// Actor sheets
const { HandlebarsApplicationMixin } = foundry.applications.api
const { ActorSheetV2 } = foundry.applications.sheets
class MyActorSheet extends HandlebarsApplicationMixin(ActorSheetV2) { }

// Item sheets
const { ItemSheetV2 } = foundry.applications.sheets
class MyItemSheet extends HandlebarsApplicationMixin(ItemSheetV2) { }

// Configuration dialogs
const { ApplicationV2, HandlebarsApplicationMixin } = foundry.applications.api
class MyConfigDialog extends HandlebarsApplicationMixin(ApplicationV2) { }

// User prompts — use the static helpers, rarely a subclass
const { DialogV2 } = foundry.applications.api
```

## HandlebarsApplicationMixin

Always mix in `HandlebarsApplicationMixin` for template rendering. It provides `PARTS`, `_preparePartContext`, and per-part scroll/focus state preservation.

```javascript
const { HandlebarsApplicationMixin } = foundry.applications.api
class MySheet extends HandlebarsApplicationMixin(ActorSheetV2) { }
```

## DEFAULT_OPTIONS

A static property, not a getter. Options merge automatically up the inheritance chain — never call `mergeObject(super.DEFAULT_OPTIONS, …)`.

```javascript
static DEFAULT_OPTIONS = {
  classes: ['my-system', 'sheet', 'actor'],
  position: { width: 600, height: 600 },
  window: {
    resizable: true,
    title: 'MY_SYSTEM.SheetTitle',   // Localization key
    icon: 'fa-solid fa-user',
    contentClasses: ['standard-form']
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
  tag: 'form',                // REQUIRED for forms
  form: {
    submitOnChange: true,     // Auto-save on field change (sheets)
    closeOnSubmit: false      // Keep open after submit (sheets)
  }
}
```

**Window controls in V14**: the base `window.controls` already contains Detach and Attach entries. If you replace `window.controls` wholesale you lose pop-out support; prefer overriding `_getHeaderControls()` and appending to `super._getHeaderControls()`.

## PARTS (Template Definitions)

```javascript
static PARTS = {
  header:    { template: 'systems/my-system/templates/actor/header.hbs' },
  tabs:      { template: 'templates/generic/tab-navigation.hbs' },   // core partial
  character: { template: 'systems/my-system/templates/actor/tab-character.hbs' },
  equipment: {
    template: 'systems/my-system/templates/actor/tab-equipment.hbs',
    templates: ['systems/my-system/templates/actor/item-row.hbs'],   // sub-partials to preload
    scrollable: ['ol.item-list']                                      // preserved across re-renders
  }
}
```

**Template file extension**: Foundry fetches whatever path you give and compiles it with Handlebars, so the extension is a convention, not a requirement. Core and most newer systems use `.hbs`, which this guide uses throughout; `.html` works identically and many existing systems use it. Pick one and stay consistent.

**Cannot use CONFIG values in static initializers** — `CONFIG` is undefined when the class body evaluates:

```javascript
// BROKEN
static PARTS = { form: { template: CONFIG.MY_SYSTEM.templates.dialog } }

// CORRECT
static PARTS = { form: { template: 'systems/my-system/templates/dialog.hbs' } }
```

Only the *first* part may set `root: true`.

## _prepareContext() (Replaces getData)

```javascript
async _prepareContext(options) {
  const context = await super._prepareContext(options)
  context.system = this.actor.system
  context.flags = this.actor.flags
  context.editable = this.isEditable
  return context
}
```

`DocumentSheetV2._prepareContext` already supplies `document`, `model`, `source` (the raw `_source`), `fields` (the schema fields — bind form inputs to these with the `formInput`/`formGroup` helpers), `editable`, `user`, and `rootId`.

`ApplicationV2._prepareContext` supplies `tabs` automatically **when exactly one tab group is configured** (see below).

Per-part data goes in `_preparePartContext`:

```javascript
async _preparePartContext(partId, context, options) {
  const partContext = await super._preparePartContext(partId, context, options)
  if (partId in partContext.tabs) partContext.tab = partContext.tabs[partId]
  switch (partId) {
    case 'equipment':
      partContext.weapons = this.actor.items.filter(i => i.type === 'weapon')
      break
  }
  return partContext
}
```

### Enriched HTML

V14 re-exports `enrichHTML` on the class itself — `TextEditor.implementation` is no longer needed:

```javascript
const { TextEditor } = foundry.applications.ux

context.descriptionHTML = await TextEditor.enrichHTML(
  this.document.system.description,
  { secrets: this.document.isOwner, relativeTo: this.document }
)
```

## Actions System (Replaces activateListeners)

```javascript
static DEFAULT_OPTIONS = {
  actions: {
    rollAbilityCheck: this.#rollAbilityCheck,
    // Object form: also respond to right-click (button 2)
    itemContext: { handler: this.#itemContext, buttons: [0, 2] }
  }
}

/**
 * @this {MyActorSheet}
 * @param {PointerEvent} event
 * @param {HTMLElement} target   The element carrying [data-action]
 */
static async #rollAbilityCheck(event, target) {
  event.preventDefault()
  await this.actor.rollAbilityCheck(target.dataset.ability)
}
```

```html
<span data-action="rollAbilityCheck" data-ability="str">Strength</span>
<button data-action="deleteItem" data-item-id="{{item._id}}">Delete</button>
```

`close`, `tab`, and `toggleControls` are reserved action names handled by the framework. Actions with no registered handler fall through to `_onClickAction(event, target)`, which you may override as a catch-all.

## Form Handling

### Pattern 1: Auto-Submit (Actor/Item Sheets)

```javascript
static DEFAULT_OPTIONS = {
  tag: 'form',
  form: { submitOnChange: true }
}
// No handler needed — DocumentSheetV2 updates the document
```

The submit pipeline is `_onSubmitForm` → `_prepareSubmitData` → `_processFormData` → `_processSubmitData`. `_processFormData` returns `foundry.utils.expandObject(formData.object)`; override it to reshape that expanded object, and override `_processSubmitData(event, form, submitData, options)` to run work after the document update.

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
  await this.options.document.update(formData.object)
}
```

**Template requirement**: with `tag: 'form'` the application root *is* the form. Templates must not contain their own `<form>`:

```html
<!-- WRONG: nested forms are invalid HTML -->
<form class="config-dialog">...</form>

<!-- CORRECT -->
<section class="config-dialog">...</section>
```

## Tab System

Declare tabs in `static TABS`, keyed by group id. `group` is filled in for you; `labelPrefix` saves repeating the i18n path.

```javascript
static TABS = {
  sheet: {
    tabs: [
      { id: 'character', icon: 'fa-solid fa-user' },
      { id: 'equipment', icon: 'fa-solid fa-sack' },
      { id: 'notes',     icon: 'fa-solid fa-book' }
    ],
    initial: 'character',
    labelPrefix: 'MY_SYSTEM.TABS'   // -> MY_SYSTEM.TABS.character, …
  }
}

static PARTS = {
  tabs:      { template: 'templates/generic/tab-navigation.hbs' },
  character: { template: 'systems/my-system/templates/tab-character.hbs' },
  equipment: { template: 'systems/my-system/templates/tab-equipment.hbs' },
  notes:     { template: 'systems/my-system/templates/tab-notes.hbs' }
}
```

**`context.tabs` is a record keyed by tab id**, not an array — `context.tabs.character` is `{ id, group, active, cssClass, label, icon }`. With exactly one tab group, `ApplicationV2._prepareContext` populates it automatically; with several groups call `this._prepareTabs('groupId')` yourself.

### Tab Navigation

Easiest path is the core partial `templates/generic/tab-navigation.hbs`, which renders `context.tabs` and honours an optional `tabClasses` (e.g. `"top-tabs"`) and `verticalTabs`. Rolling your own, the critical bit is **`data-action="tab"`** — tab switching is a framework action, not a CSS-class listener:

```html
<nav class="tabs sheet-tabs" aria-roledescription="{{localize 'SHEETS.FormNavLabel'}}">
  {{#each tabs as |tab|}}
    <a data-action="tab" data-group="{{tab.group}}" data-tab="{{tab.id}}"
       class="{{tab.cssClass}}">
      {{#if tab.icon}}<i class="{{tab.icon}}" inert></i>{{/if}}
      {{#if tab.label}}<span>{{localize tab.label}}</span>{{/if}}
    </a>
  {{/each}}
</nav>
```

### Tab Content

Each tab part needs exactly one root element carrying `data-tab`, `data-group`, and the tab's `cssClass` (that is what carries `active`):

```html
<section class="tab {{tab.id}} {{tab.cssClass}}"
         data-tab="{{tab.id}}" data-group="{{tab.group}}">
  <!-- content -->
</section>
```

(`{{tab}}` comes from the `if (partId in partContext.tabs) partContext.tab = partContext.tabs[partId]` line in `_preparePartContext`; without it, address the record directly as `{{tabs.character.cssClass}}`.)

**CSS warning**: if an ancestor is `display: grid` or `display: flex`, every tab shows at once. Put layout styles on inner elements, not on the tab container.

## Drag and Drop

### ActorSheetV2 (Automatic)

```html
<li class="item draggable" data-item-id="{{item._id}}">{{item.name}}</li>
<li class="effect draggable" data-effect-id="{{effect._id}}">{{effect.name}}</li>
```

### ApplicationV2 (Manual Setup)

Non-document apps wire `foundry.applications.ux.DragDrop` themselves — full pattern in **`references/appv2-patterns.md`**.

## Image Editing

```javascript
static DEFAULT_OPTIONS = {
  actions: { editImage: MySheetClass.editImage }   // inherited from DocumentSheetV2
}
```

```html
<img src="{{document.img}}" data-action="editImage" data-edit="img" alt="Portrait">
```

## ProseMirror Editor

TinyMCE was **removed entirely in V14**; ProseMirror is the only bundled editor. The `{{editor}}` Handlebars helper and the `<prose-mirror>` element both remain, but new code should use the element:

```html
{{#if editable}}
  <prose-mirror name="system.description" button="true"
                editable="{{editable}}" toggled="false"
                value="{{system.description}}">
    {{{descriptionHTML}}}
  </prose-mirror>
{{else}}
  {{{descriptionHTML}}}
{{/if}}
```

Building plugins: `foundry.prosemirror.defaultPlugins` is deprecated — use `foundry.applications.ux.ProseMirrorEditor.buildDefaultPlugins()`.

## Detached (Pop-Out) Windows — New in V14

Any framed ApplicationV2 can be torn off into a separate browser window. The header buttons come free; the hooks let you opt out or react:

```javascript
render({ window: { detached: true } })   // open detached programmatically

_canDetach() { return super._canDetach() && !this.actor.pack }   // veto
_onDetach(from, to) { /* re-bind anything tied to the old document */ }
_onAttach(from, to) { }
```

Anything you cached against `document` / `window` globals at render time must be re-derived from `this.element.ownerDocument` — a detached app lives in a different document. Child apps opened from a detached parent should use `this.renderChild(app)` so they follow it.

## Sheet Registration

```javascript
Hooks.once('init', () => {
  const { Actors, Items } = foundry.documents.collections
  const { ActorSheetV2, ItemSheetV2 } = foundry.applications.sheets

  Actors.unregisterSheet('core', ActorSheetV2)
  Items.unregisterSheet('core', ItemSheetV2)

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

ApplicationV2 takes a single options object:

```javascript
// V1 style — wrong
new MyConfig(this.actor, { position: { … } })

// V2
new MyConfig({ document: this.actor, position: { … } })
```

## Removed Handlebars Helpers

V14 removed two long-deprecated helpers. The full registered set is `checked`, `disabled`, `concat`, `editor`, `formInput`, `formGroup`/`formField`, `filePicker`, `ifThen`, `localize`, `numberFormat`, `numberInput`, `object`, `radioBoxes`, `rangePicker`, `selectOptions`, `timeSince`, plus comparison helpers (`eq ne lt gt lte gte not and or`).

| Removed | Use instead |
|---------|-------------|
| `{{select}}` | `{{selectOptions}}` |
| `{{colorPicker}}` | the `<color-picker>` element |

## CSS Theming

Declare a `system-`prefixed variable set, in light **and** dark:

```css
:root, .theme-light {
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

```json
{
  "styles": [
    { "src": "styles/variables.css", "layer": "variables" },
    { "src": "styles/my-system.css", "layer": "system" }
  ]
}
```

### Two V14 traps worth knowing

**1. Legacy core variables no longer resolve.** Foundry declares `--color-text-dark-*`, `--color-border-light-*`, `--color-text-hyperlink` and friends only under `body.game .app`. V14 has no AppV1 windows, so nothing in a running world matches `.app` and every `var()` referencing those names resolves to nothing. The failure is silent and asymmetric: inherited properties like `color` compute to `inherit` (usually still legible), while `border` / `outline` / `background` shorthands render **nothing at all**. Verify in a live world rather than trusting the name:

```js
getComputedStyle(document.querySelector('.my-system.sheet'))
  .getPropertyValue('--color-text-dark-secondary')   // '' → does not resolve
```

**2. Chat re-establishes the light theme.** Foundry stamps `themed theme-light` on `ol.chat-log`, so a variable declared under `:root, .theme-light` / `.theme-dark` resolves to its *light* value inside chat regardless of the active theme. Anything rendered into a chat message needs names declared on `body` alone (e.g. `--chat-border-color`), and those must be literal values — `var(--system-…)` indirection is substituted at use site and resolves light again.

## Additional Resources

- **`references/appv2-migration.md`** — V13→V14 and V12→V13 migration: breaking changes, method mapping, hook renames, namespace changes, checklists
- **`references/appv2-patterns.md`** — complete examples: actor/item sheets, dialogs, DialogV2 helpers, inline item editing, multi-tab sheets, manual drag-drop, detached windows
