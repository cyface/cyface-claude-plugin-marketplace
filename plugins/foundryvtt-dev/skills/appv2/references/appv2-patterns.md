# ApplicationV2 Code Patterns

Complete code examples for common FoundryVTT **V14** ApplicationV2 patterns. Last-verified build: see the plugin README. These patterns also work on V13 except where a V14 note says otherwise.

## Complete Actor Sheet Example

```javascript
const { HandlebarsApplicationMixin } = foundry.applications.api
const { ActorSheetV2 } = foundry.applications.sheets
const { TextEditor } = foundry.applications.ux

class MyActorSheet extends HandlebarsApplicationMixin(ActorSheetV2) {
  /** @inheritDoc */
  static DEFAULT_OPTIONS = {
    classes: ['my-system', 'sheet', 'actor'],
    position: {
      width: 680,
      height: 740
    },
    window: {
      resizable: true,
      title: 'MY_SYSTEM.SheetCharacter'
    },
    tag: 'form',
    form: {
      submitOnChange: true
    },
    actions: {
      rollAbilityCheck: this.#rollAbilityCheck,
      rollSave: this.#rollSave,
      itemCreate: this.#itemCreate,
      itemEdit: this.#itemEdit,
      itemDelete: this.#itemDelete,
      editImage: MyActorSheet.editImage  // Inherited from DocumentSheetV2
    }
  }

  /** @inheritDoc */
  static TABS = {
    sheet: {
      tabs: [
        { id: 'attributes', icon: 'fa-solid fa-dice-d20' },
        { id: 'inventory', icon: 'fa-solid fa-sack' },
        { id: 'spells', icon: 'fa-solid fa-wand-sparkles' },
        { id: 'biography', icon: 'fa-solid fa-book' }
      ],
      initial: 'attributes',
      labelPrefix: 'MY_SYSTEM.TABS'   // -> MY_SYSTEM.TABS.attributes, ...
    }
  }

  /** @inheritDoc */
  static PARTS = {
    header: {
      template: 'systems/my-system/templates/actor/header.hbs'
    },
    tabs: {
      template: 'templates/generic/tab-navigation.hbs'   // core partial
    },
    attributes: {
      template: 'systems/my-system/templates/actor/tab-attributes.hbs'
    },
    inventory: {
      template: 'systems/my-system/templates/actor/tab-inventory.hbs'
    },
    spells: {
      template: 'systems/my-system/templates/actor/tab-spells.hbs'
    },
    biography: {
      template: 'systems/my-system/templates/actor/tab-biography.hbs'
    }
  }

  /** @inheritDoc */
  async _prepareContext(options) {
    const context = await super._prepareContext(options)
    const actor = this.actor

    context.system = actor.system
    context.flags = actor.flags
    context.editable = this.isEditable

    // Organize items by type
    context.weapons = actor.items.filter(i => i.type === 'weapon')
    context.armor = actor.items.filter(i => i.type === 'armor')
    context.spells = actor.items.filter(i => i.type === 'spell')
    context.gear = actor.items.filter(i => i.type === 'equipment')

    // Enrich biography for ProseMirror
    context.biographyHTML = await TextEditor.enrichHTML(
      actor.system.biography,
      { secrets: actor.isOwner, relativeTo: actor }
    )

    return context
  }

  /** @inheritDoc */
  async _preparePartContext(partId, context, options) {
    const partContext = await super._preparePartContext(partId, context, options)
    // Expose the current tab as {{tab}} inside tab parts
    if (partId in partContext.tabs) partContext.tab = partContext.tabs[partId]
    if (partId === 'tabs') partContext.tabClasses = 'top-tabs'
    return partContext
  }

  /**
   * Handle ability check rolls
   * @this {MyActorSheet}
   * @param {PointerEvent} event
   * @param {HTMLElement} target
   */
  static async #rollAbilityCheck(event, target) {
    event.preventDefault()
    const ability = target.dataset.ability
    await this.actor.rollAbilityCheck(ability)
  }

  /**
   * Handle saving throw rolls
   * @this {MyActorSheet}
   */
  static async #rollSave(event, target) {
    event.preventDefault()
    const save = target.dataset.save
    await this.actor.rollSave(save)
  }

  /**
   * Create a new item on the actor
   * @this {MyActorSheet}
   */
  static async #itemCreate(event, target) {
    event.preventDefault()
    const type = target.dataset.type
    const itemData = {
      name: game.i18n.format('MY_SYSTEM.NewItem', { type }),
      type
    }
    await this.actor.createEmbeddedDocuments('Item', [itemData])
  }

  /**
   * Open an item's sheet for editing
   * @this {MyActorSheet}
   */
  static async #itemEdit(event, target) {
    const itemId = target.closest('[data-item-id]').dataset.itemId
    const item = this.actor.items.get(itemId)
    item?.sheet.render(true)
  }

  /**
   * Delete an item from the actor
   * @this {MyActorSheet}
   */
  static async #itemDelete(event, target) {
    const itemId = target.closest('[data-item-id]').dataset.itemId
    const item = this.actor.items.get(itemId)
    if (item) {
      await item.delete()
    }
  }
}
```

### Actor Sheet Templates

**Header template (`actor/header.hbs`):**
```html
<header class="sheet-header">
  <img src="{{actor.img}}" data-action="editImage" data-edit="img" alt="Portrait" class="profile-img">
  <div class="header-details">
    <h1><input name="name" type="text" value="{{actor.name}}" placeholder="{{localize 'MY_SYSTEM.Name'}}"></h1>
    <div class="header-stats">
      <span>{{localize "MY_SYSTEM.Level"}}: {{system.level}}</span>
      <span>{{localize "MY_SYSTEM.HP"}}: {{system.hp.value}} / {{system.hp.max}}</span>
    </div>
  </div>
</header>
```

**Tab navigation.** Prefer the core partial `templates/generic/tab-navigation.hbs`, which renders `context.tabs` for you. If you write your own, `context.tabs` is a **record keyed by tab id** (not an array) and the nav links must carry `data-action="tab"` — tab switching is a framework action, not a CSS-class listener:

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

**Tab content template (`actor/tab-attributes.hbs`):**
```html
<section class="tab {{tabs.attributes.id}} {{tabs.attributes.cssClass}}"
         data-tab="{{tabs.attributes.id}}"
         data-group="{{tabs.attributes.group}}">
  <div class="abilities-grid">
    {{#each system.abilities}}
      <div class="ability">
        <label data-action="rollAbilityCheck" data-ability="{{@key}}">
          {{localize this.label}}
        </label>
        <input type="number" name="system.abilities.{{@key}}.value" value="{{this.value}}">
        <span class="modifier">{{this.mod}}</span>
      </div>
    {{/each}}
  </div>
</section>
```

**Inventory tab template (`actor/tab-inventory.hbs`):**
```html
<section class="tab {{tabs.inventory.id}} {{tabs.inventory.cssClass}}"
         data-tab="{{tabs.inventory.id}}"
         data-group="{{tabs.inventory.group}}">
  <div class="item-header">
    <h3>{{localize "MY_SYSTEM.Weapons"}}</h3>
    <button data-action="itemCreate" data-type="weapon">
      <i class="fa-solid fa-plus"></i> {{localize "MY_SYSTEM.Add"}}
    </button>
  </div>
  <ol class="item-list">
    {{#each weapons}}
      <li class="item draggable" data-item-id="{{this._id}}">
        <img src="{{this.img}}" alt="{{this.name}}" width="24" height="24">
        <span class="item-name" data-action="itemEdit">{{this.name}}</span>
        <span class="item-detail">{{this.system.damage}}</span>
        <button data-action="itemDelete"><i class="fa-solid fa-trash"></i></button>
      </li>
    {{/each}}
  </ol>
</section>
```

**Biography tab template (`actor/tab-biography.hbs`):**
```html
<section class="tab {{tabs.biography.id}} {{tabs.biography.cssClass}}"
         data-tab="{{tabs.biography.id}}"
         data-group="{{tabs.biography.group}}">
  {{#if editable}}
    <prose-mirror
      name="system.biography"
      button="true"
      editable="{{editable}}"
      toggled="false"
      value="{{system.biography}}">
      {{{biographyHTML}}}
    </prose-mirror>
  {{else}}
    <div class="biography-content">{{{biographyHTML}}}</div>
  {{/if}}
</section>
```

## Complete Item Sheet Example

```javascript
const { HandlebarsApplicationMixin } = foundry.applications.api
const { ItemSheetV2 } = foundry.applications.sheets
const { TextEditor } = foundry.applications.ux

class MyItemSheet extends HandlebarsApplicationMixin(ItemSheetV2) {
  /** @inheritDoc */
  static DEFAULT_OPTIONS = {
    classes: ['my-system', 'sheet', 'item'],
    position: {
      width: 520,
      height: 480
    },
    window: {
      resizable: true
    },
    tag: 'form',
    form: {
      submitOnChange: true
    },
    actions: {
      editImage: MyItemSheet.editImage
    }
  }

  /** @inheritDoc */
  static TABS = {
    sheet: {
      tabs: [
        { id: 'details', icon: 'fa-solid fa-list' },
        { id: 'description', icon: 'fa-solid fa-book' }
      ],
      initial: 'details',
      labelPrefix: 'MY_SYSTEM.TABS'
    }
  }

  /** @inheritDoc */
  static PARTS = {
    header: {
      template: 'systems/my-system/templates/item/header.hbs'
    },
    tabs: {
      template: 'templates/generic/tab-navigation.hbs'
    },
    details: {
      template: 'systems/my-system/templates/item/tab-details.hbs'
    },
    description: {
      template: 'systems/my-system/templates/item/tab-description.hbs'
    }
  }

  /** @inheritDoc */
  get title() {
    return this.document.name
  }

  /** @inheritDoc */
  async _prepareContext(options) {
    const context = await super._prepareContext(options)
    const item = this.document

    context.item = item
    context.system = item.system
    context.editable = this.isEditable

    context.descriptionHTML = await TextEditor.enrichHTML(
      item.system.description,
      { secrets: item.isOwner, relativeTo: item }
    )

    return context
  }
}
```

## Configuration Dialog Example

```javascript
const { ApplicationV2, HandlebarsApplicationMixin } = foundry.applications.api

class MyConfigDialog extends HandlebarsApplicationMixin(ApplicationV2) {
  /** @inheritDoc */
  static DEFAULT_OPTIONS = {
    classes: ['my-system', 'config-dialog'],
    tag: 'form',
    position: { width: 420, height: 'auto' },
    window: {
      title: 'MY_SYSTEM.Configuration',
      resizable: false
    },
    form: {
      handler: MyConfigDialog.#onSubmitForm,
      submitOnChange: false,
      closeOnSubmit: true
    }
  }

  /** @inheritDoc */
  static PARTS = {
    form: {
      template: 'systems/my-system/templates/dialog-config.hbs'
    }
  }

  /** @inheritDoc */
  async _prepareContext(options) {
    const context = await super._prepareContext(options)
    const doc = this.options.document
    context.system = doc.system
    context.config = CONFIG.MY_SYSTEM
    return context
  }

  /**
   * @this {MyConfigDialog}
   * @param {SubmitEvent} event
   * @param {HTMLFormElement} form
   * @param {FormDataExtended} formData
   */
  static async #onSubmitForm(event, form, formData) {
    event.preventDefault()
    await this.options.document.update(formData.object)
    await this.options.document.sheet.render(true)
  }
}

// Usage:
new MyConfigDialog({ document: someActor }).render(true)
```

## DialogV2 Prompt Example

```javascript
// Simple confirmation
const confirmed = await foundry.applications.api.DialogV2.confirm({
  window: { title: 'MY_SYSTEM.ConfirmDelete' },
  content: `<p>${game.i18n.localize('MY_SYSTEM.ConfirmDeleteMessage')}</p>`
})
// Resolves to true / false (or null if dismissed) — no callbacks needed

// Form input prompt — DialogV2.input returns the form data object directly
const data = await foundry.applications.api.DialogV2.input({
  window: { title: 'MY_SYSTEM.EnterValue' },
  content: `
    <div class="form-group">
      <label>${game.i18n.localize('MY_SYSTEM.Value')}</label>
      <input type="number" name="value" value="0">
    </div>
  `
})
// data?.value — null if the dialog was dismissed

// Custom prompt with an explicit callback
const result = await foundry.applications.api.DialogV2.prompt({
  window: { title: 'MY_SYSTEM.EnterValue' },
  content: `
    <div class="form-group">
      <label>${game.i18n.localize('MY_SYSTEM.Value')}</label>
      <input type="number" name="value" value="0">
    </div>
  `,
  ok: {
    callback: (event, button, dialog) => {
      return button.form.elements.value.value
    }
  }
})
```

## Inline Item Editing on Actor Sheets

When editing item properties directly on an actor sheet (like equip checkboxes or inline damage fields):

### Template

```html
<li class="weapon" data-item-id="{{weapon._id}}">
  <input type="text"
         name="items.{{weapon._id}}.name"
         value="{{weapon.name}}">
  <input type="checkbox"
         name="items.{{weapon._id}}.system.equipped"
         {{checked weapon.system.equipped}}>
  <input type="text"
         name="items.{{weapon._id}}.system.damage"
         value="{{weapon.system.damage}}">
</li>
```

### Implementation

```javascript
class MyActorSheet extends HandlebarsApplicationMixin(ActorSheetV2) {
  /** @override */
  _processFormData(event, form, formData) {
    // super returns foundry.utils.expandObject(formData.object), so `items.<id>.…` arrives as submitData.items[id]
    const submitData = super._processFormData(event, form, formData)
    if (submitData.items) {
      this._pendingItemUpdates = Object.entries(submitData.items).map(([_id, data]) => ({ _id, ...data }))
      delete submitData.items   // never hand an `items` object to actor.update()
    }
    return submitData
  }

  /** @override */
  async _processSubmitData(event, form, submitData, options) {
    const result = await super._processSubmitData(event, form, submitData, options)

    // Apply pending item updates after the actor update
    if (this._pendingItemUpdates?.length) {
      await this.document.updateEmbeddedDocuments('Item', this._pendingItemUpdates)
      delete this._pendingItemUpdates
    }

    return result
  }
}
```

**Key points:**
- Use the `items.{{id}}.property` naming convention in templates
- Override `_processFormData` to pull the item data out of the expanded submit object and **remove it** before the actor update
- Override `_processSubmitData` (four parameters in V14: `event, form, submitData, options`) to apply the item updates after the actor update
- Clean up the temporary storage after the updates complete

## Manual Drag and Drop Setup

For ApplicationV2 (non-actor sheets) that need drag/drop:

```javascript
const { DragDrop } = foundry.applications.ux

class MyApp extends HandlebarsApplicationMixin(ApplicationV2) {
  #dragDrop

  static DEFAULT_OPTIONS = {
    dragDrop: [{
      dragSelector: '[data-drag="true"]',
      dropSelector: '.drop-zone'
    }]
  }

  constructor(options = {}) {
    super(options)
    this.#dragDrop = this.#createDragDropHandlers()
  }

  #createDragDropHandlers() {
    return this.options.dragDrop.map((d) => {
      d.permissions = {
        dragstart: this._canDragStart.bind(this),
        drop: this._canDragDrop.bind(this)
      }
      d.callbacks = {
        dragstart: this._onDragStart.bind(this),
        dragover: this._onDragOver.bind(this),
        drop: this._onDrop.bind(this)
      }
      return new DragDrop.implementation(d)
    })
  }

  /** @override */
  async _onRender(context, options) {
    await super._onRender(context, options)
    this.#dragDrop.forEach((d) => d.bind(this.element))
  }

  _canDragStart(selector) {
    return this.document?.isOwner && this.isEditable
  }

  _canDragDrop(selector) {
    return this.document?.isOwner && this.isEditable
  }

  _onDragStart(event) {
    const element = event.currentTarget
    const itemId = element.dataset.itemId
    const item = this.document.items.get(itemId)
    if (item) {
      event.dataTransfer.setData('text/plain', JSON.stringify(item.toDragData()))
    }
  }

  _onDragOver(event) {
    // Optional visual feedback
  }

  _onDrop(event) {
    const data = foundry.applications.ux.TextEditor.getDragEventData(event)
    if (!data) return false
    // Handle dropped data
  }
}
```

**Template:**
```html
<ol class="items drop-zone">
  {{#each items}}
    <li data-drag="true" data-item-id="{{this._id}}">
      {{this.name}}
    </li>
  {{/each}}
</ol>
```

## Dynamic Tab Configuration

For sheets where tabs vary based on document type:

```javascript
class MyActorSheet extends HandlebarsApplicationMixin(ActorSheetV2) {
  static TABS = {
    sheet: {
      tabs: [
        { id: 'attributes', icon: 'fa-solid fa-dice-d20' },
        { id: 'inventory', icon: 'fa-solid fa-sack' }
      ],
      initial: 'attributes',
      labelPrefix: 'MY_SYSTEM.TABS'
    }
  }

  /** @override */
  _getTabsConfig(group) {
    const config = foundry.utils.deepClone(super._getTabsConfig(group))

    // Add spells tab only for spellcaster types
    if (this.document.type === 'spellcaster') {
      config.tabs.push({ id: 'spells', icon: 'fa-solid fa-wand-sparkles' })
    }

    return config
  }
}
```

## Hybrid Drag and Drop (ActorSheetV2 + Custom Types)

When you need ActorSheetV2's automatic item handling plus custom drag types, **do not create a second `DragDrop`**. ActorSheetV2 already binds one to `.draggable` in `_onRender`, with its callbacks bound to *your* `_onDragStart` and `_onDrop`. A second instance with a drop selector would handle every drop twice. Override the methods instead:

```javascript
class MyActorSheet extends HandlebarsApplicationMixin(ActorSheetV2) {
  /** @override */
  async _onDragStart(event) {
    const element = event.currentTarget

    // Custom drag types
    if (element.dataset.dragAction === 'ability') {
      const dragData = {
        type: 'Ability',
        actorId: this.actor.id,
        data: { abilityId: element.dataset.ability }
      }
      event.dataTransfer.setData('text/plain', JSON.stringify(dragData))
      return
    }

    // Everything else (items, effects) — core handles [data-item-id] / [data-effect-id]
    return super._onDragStart(event)
  }

  /** @override */
  async _onDrop(event) {
    const data = foundry.applications.ux.TextEditor.getDragEventData(event)

    if (data?.type === 'Ability') {
      // Handle the custom type here
      return
    }

    // Delegate Item / ActiveEffect / Actor drops to ActorSheetV2
    return super._onDrop(event)
  }
}
```

**Template:**
```html
<!-- Standard items — automatic ActorSheetV2 handling -->
<li class="item draggable" data-item-id="{{item._id}}">{{item.name}}</li>

<!-- Custom drag types — same `draggable` class, branch on a data attribute -->
<span class="draggable" data-drag-action="ability" data-ability="str">Strength</span>
```

## Complete Dialog Migration Example

### Before (V12)
```javascript
class MyActorConfig extends FormApplication {
  static get defaultOptions() {
    const options = super.defaultOptions
    options.template = 'systems/my-system/templates/dialog-config.hbs'
    options.width = 380
    return options
  }

  get title() {
    return `${this.object.name}: ${game.i18n.localize('MY_SYSTEM.Config')}`
  }

  getData() {
    const data = this.object
    data.config = CONFIG.MY_SYSTEM
    return data
  }

  async _updateObject(event, formData) {
    await this.object.update(formData)
  }
}
```

### After (V13/V14)
```javascript
const { ApplicationV2, HandlebarsApplicationMixin } = foundry.applications.api

class MyActorConfig extends HandlebarsApplicationMixin(ApplicationV2) {
  static DEFAULT_OPTIONS = {
    classes: ['my-system', 'sheet', 'actor-config'],
    tag: 'form',
    position: { width: 420, height: 'auto' },
    window: {
      title: 'MY_SYSTEM.Config',
      resizable: false
    },
    form: {
      handler: MyActorConfig.#onSubmitForm,
      submitOnChange: false,
      closeOnSubmit: true
    }
  }

  static PARTS = {
    form: {
      template: 'systems/my-system/templates/dialog-config.hbs'
    }
  }

  async _prepareContext(options) {
    const context = await super._prepareContext(options)
    const actor = this.options.document
    context.config = CONFIG.MY_SYSTEM
    context.system = actor.system
    context.actor = actor
    return context
  }

  static async #onSubmitForm(event, form, formData) {
    event.preventDefault()
    await this.options.document.update(formData.object)
    await this.options.document.sheet.render(true)
  }
}

// Usage — note single options object
new MyActorConfig({ document: someActor }).render(true)
```


## Detached (Pop-Out) Windows — V14

Every framed ApplicationV2 gets Detach/Attach header buttons for free. Only override the hooks when a sheet has state that cannot survive moving to another browser document.

```javascript
class MyActorSheet extends HandlebarsApplicationMixin(ActorSheetV2) {
  /** @type {ResizeObserver|null} */
  #observer = null

  /** Refuse to detach compendium sheets */
  _canDetach() {
    return super._canDetach() && !this.actor.pack
  }

  /** Re-derive anything bound to the old document/window */
  _onDetach(from, to) {
    super._onDetach(from, to)
    this.#observer?.disconnect()
    this.#observer = new ResizeObserver(() => this.#syncLayout())
    this.#observer.observe(this.element)
  }

  _onAttach(from, to) {
    super._onAttach(from, to)
    this._onDetach(from, to)   // same re-binding work
  }

  #syncLayout() {
    // Measure against the element, never against the global window
    const { width } = this.element.getBoundingClientRect()
    this.element.classList.toggle('compact', width < 600)
  }

  /** Child apps opened from a detached sheet should follow it */
  static async #openConfig(event, target) {
    this.renderChild(new MyConfigDialog({ document: this.actor }))
  }
}

// Open detached programmatically
actor.sheet.render({ window: { detached: true } })
```

**Rules of thumb for detach-safe sheets:**
- Never cache the global `document` or `window` at render time — read `this.element.ownerDocument` / `.defaultView` when you need them.
- Measure with `this.element.getBoundingClientRect()`, not viewport globals.
- Anything registered on `document` (listeners, observers, portals) is re-registered in `_onDetach` / `_onAttach`.

## Schema-Driven Form Fields — V14

`DocumentSheetV2._prepareContext` hands you `fields` (the document's schema fields) and `source` (the raw `_source` data). The `formGroup` and `formInput` helpers build labelled, correctly typed inputs from those, so field type changes in the data model propagate to the sheet automatically:

```javascript
async _prepareContext(options) {
  const context = await super._prepareContext(options)
  context.systemFields = this.document.system.schema.fields
  return context
}
```

```html
{{formGroup systemFields.hp.fields.value value=source.system.hp.value localize=true}}
{{formGroup systemFields.level value=source.system.level localize=true}}

{{!-- Just the input, no label wrapper --}}
{{formInput systemFields.notes value=source.system.notes}}
```

Bind to `source.*`, not the prepared `system.*` — prepared data may contain values derived by Active Effects, and writing those back to the document would bake the effect into the base data.
