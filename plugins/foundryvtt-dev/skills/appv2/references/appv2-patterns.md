# ApplicationV2 Code Patterns

Complete code examples for common FoundryVTT V13 ApplicationV2 patterns.

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
        { id: 'attributes', group: 'sheet', label: 'MY_SYSTEM.Attributes' },
        { id: 'inventory', group: 'sheet', label: 'MY_SYSTEM.Inventory' },
        { id: 'spells', group: 'sheet', label: 'MY_SYSTEM.Spells' },
        { id: 'biography', group: 'sheet', label: 'MY_SYSTEM.Biography' }
      ],
      initial: 'attributes'
    }
  }

  /** @inheritDoc */
  static PARTS = {
    header: {
      template: 'systems/my-system/templates/actor/header.html'
    },
    tabs: {
      template: 'systems/my-system/templates/actor/tabs-nav.html'
    },
    attributes: {
      template: 'systems/my-system/templates/actor/tab-attributes.html'
    },
    inventory: {
      template: 'systems/my-system/templates/actor/tab-inventory.html'
    },
    spells: {
      template: 'systems/my-system/templates/actor/tab-spells.html'
    },
    biography: {
      template: 'systems/my-system/templates/actor/tab-biography.html'
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

**Header template (`actor/header.html`):**
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

**Tab navigation template (`actor/tabs-nav.html`):**
```html
<nav class="tabs sheet-tabs" data-group="{{tabs.sheet.group}}">
  {{#each tabs.sheet.tabs}}
    <a class="tab {{this.cssClass}}" data-tab="{{this.id}}" data-group="{{this.group}}">
      {{localize this.label}}
    </a>
  {{/each}}
</nav>
```

**Tab content template (`actor/tab-attributes.html`):**
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

**Inventory tab template (`actor/tab-inventory.html`):**
```html
<section class="tab {{tabs.inventory.id}} {{tabs.inventory.cssClass}}"
         data-tab="{{tabs.inventory.id}}"
         data-group="{{tabs.inventory.group}}">
  <div class="item-header">
    <h3>{{localize "MY_SYSTEM.Weapons"}}</h3>
    <button data-action="itemCreate" data-type="weapon">
      <i class="fas fa-plus"></i> {{localize "MY_SYSTEM.Add"}}
    </button>
  </div>
  <ol class="item-list">
    {{#each weapons}}
      <li class="item draggable" data-item-id="{{this._id}}">
        <img src="{{this.img}}" alt="{{this.name}}" width="24" height="24">
        <span class="item-name" data-action="itemEdit">{{this.name}}</span>
        <span class="item-detail">{{this.system.damage}}</span>
        <button data-action="itemDelete"><i class="fas fa-trash"></i></button>
      </li>
    {{/each}}
  </ol>
</section>
```

**Biography tab template (`actor/tab-biography.html`):**
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
        { id: 'details', group: 'sheet', label: 'MY_SYSTEM.Details' },
        { id: 'description', group: 'sheet', label: 'MY_SYSTEM.Description' }
      ],
      initial: 'details'
    }
  }

  /** @inheritDoc */
  static PARTS = {
    header: {
      template: 'systems/my-system/templates/item/header.html'
    },
    tabs: {
      template: 'systems/my-system/templates/item/tabs-nav.html'
    },
    details: {
      template: 'systems/my-system/templates/item/tab-details.html'
    },
    description: {
      template: 'systems/my-system/templates/item/tab-description.html'
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
      template: 'systems/my-system/templates/dialog-config.html'
    }
  }

  /** @inheritDoc */
  async _prepareContext(options) {
    const context = await super._prepareContext(options)
    const document = this.options.document
    context.system = document.system
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
  content: `<p>${game.i18n.localize('MY_SYSTEM.ConfirmDeleteMessage')}</p>`,
  yes: { callback: () => true },
  no: { callback: () => false }
})

// Input prompt
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
    // Extract raw form data BEFORE validation strips items
    const expanded = foundry.utils.expandObject(formData.object)

    if (expanded.items) {
      this._pendingItemUpdates = Object.entries(expanded.items).map(([id, itemData]) => ({
        _id: id,
        ...itemData
      }))
    }

    return super._processFormData(event, form, formData)
  }

  /** @override */
  async _processSubmitData(event, form, formData) {
    const result = await super._processSubmitData(event, form, formData)

    // Apply pending item updates after actor update
    if (this._pendingItemUpdates?.length > 0) {
      await this.document.updateEmbeddedDocuments('Item', this._pendingItemUpdates)
      delete this._pendingItemUpdates
    }

    return result
  }
}
```

**Key points:**
- Use `items.{{id}}.property` naming convention in templates
- Override `_processFormData` to intercept item data before form validation
- Override `_processSubmitData` to apply item updates after the main actor update
- Clean up temporary storage after updates complete

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
      return new DragDrop(d)
    })
  }

  _onRender(context, options) {
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
        { id: 'attributes', group: 'sheet', label: 'MY_SYSTEM.Attributes' },
        { id: 'inventory', group: 'sheet', label: 'MY_SYSTEM.Inventory' }
      ],
      initial: 'attributes'
    }
  }

  _getTabsConfig(group) {
    const tabs = foundry.utils.deepClone(super._getTabsConfig(group))

    // Add spells tab only for spellcaster types
    if (this.document.type === 'spellcaster') {
      tabs.tabs.push({ id: 'spells', group: 'sheet', label: 'MY_SYSTEM.Spells' })
    }

    return tabs
  }
}
```

## Hybrid Drag and Drop (ActorSheetV2 + Custom Types)

When you need ActorSheetV2's automatic item handling plus custom drag types:

```javascript
class MyActorSheet extends HandlebarsApplicationMixin(ActorSheetV2) {
  #dragDrop

  static DEFAULT_OPTIONS = {
    dragDrop: [{
      dragSelector: '[data-drag="true"]',
      dropSelector: '.my-system.actor'
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
      return new foundry.applications.ux.DragDrop(d)
    })
  }

  _onRender(context, options) {
    this.#dragDrop.forEach((d) => d.bind(this.element))
  }

  _onDragStart(event) {
    const element = event.currentTarget
    if (!element.dataset.drag) return

    const dragAction = element.dataset.dragAction
    let dragData = null

    switch (dragAction) {
      case 'ability': {
        const abilityId = element.dataset.ability
        dragData = {
          type: 'Ability',
          actorId: this.actor.id,
          data: { abilityId }
        }
        break
      }
      default: {
        // Fall back to standard item drag
        const itemId = element.dataset.itemId
        const item = this.actor.items.get(itemId)
        if (item) dragData = item.toDragData()
        break
      }
    }

    if (dragData) {
      event.dataTransfer.setData('text/plain', JSON.stringify(dragData))
    }
  }

  _onDrop(event) {
    const data = foundry.applications.ux.TextEditor.getDragEventData(event)
    if (!data) return false
    // Delegate to ActorSheetV2 built-in handling
    return super._onDrop?.(event)
  }
}
```

**Template:**
```html
<!-- Standard items — automatic ActorSheetV2 handling -->
<li class="item draggable" data-item-id="{{item._id}}">{{item.name}}</li>

<!-- Custom drag types — manual handling -->
<span data-drag="true" data-drag-action="ability" data-ability="str">Strength</span>
```

## Complete Dialog Migration Example

### Before (V12)
```javascript
class MyActorConfig extends FormApplication {
  static get defaultOptions() {
    const options = super.defaultOptions
    options.template = 'systems/my-system/templates/dialog-config.html'
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

### After (V13)
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
      template: 'systems/my-system/templates/dialog-config.html'
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
