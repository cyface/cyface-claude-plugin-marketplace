# ApplicationV2 Migration Reference

Complete reference for migrating from FoundryVTT V12 (Application/FormApplication) to V13 (ApplicationV2).

## Breaking Changes Summary

### HTML Elements — jQuery Removed

**V12**: `html` parameters in hooks and `activateListeners()` are jQuery objects.
**V13**: `html` parameters are plain DOM elements.

```javascript
// V12 jQuery (BREAKS in V13)
html.find('.my-button').click(handler)
html.html('<p>Content</p>')
html.addClass('active')

// V13 DOM (REQUIRED)
html.querySelector('.my-button').addEventListener('click', handler)
html.innerHTML = '<p>Content</p>'
html.classList.add('active')
```

### Document Data Path

```javascript
// V12 (BREAKS in V13)
this.object.update({ data: { results } })

// V13 (REQUIRED)
this.object.update({ system: { results } })
```

### Namespace Deprecations

**Applications and UX:**
```javascript
// V12 (Deprecated)                              // V13 (Required)
TextEditor.enrichHTML(content)                    foundry.applications.ux.TextEditor.implementation.enrichHTML(content)
FilePicker.browse()                               foundry.applications.apps.FilePicker.browse()
renderTemplate('template.html', data)             foundry.applications.handlebars.renderTemplate('template.html', data)
```

**Canvas Objects:**
```javascript
// V12 (Deprecated)                              // V13 (Required)
new Ray(origin, direction)                        new foundry.geometry.Ray(origin, direction)
NotesLayer.TOGGLE_SETTING                         foundry.canvas.layers.NotesLayer.TOGGLE_SETTING
```

## Method-by-Method Migration

| V12 (Old) | V13 (New) | Notes |
|-----------|-----------|-------|
| `static get defaultOptions()` | `static DEFAULT_OPTIONS = {}` | Static property, not getter |
| `getData()` | `async _prepareContext(options)` | Now async, takes options |
| `activateListeners(html)` | `static DEFAULT_OPTIONS.actions` | Declarative action system |
| `_updateObject(event, formData)` | `static #onSubmitForm(event, form, formData)` | Static form handler |
| `this.object` | `this.document` or `this.actor` | Depends on base class |
| `template: 'path.html'` | `static PARTS = { ... }` | Template parts system |
| `tabs: [{ navSelector }]` | `static TABS = { ... }` | New tab configuration |
| `new MyApp(document, options)` | `new MyApp({ document, ...options })` | Single options object |
| `super.defaultOptions` | N/A (auto-merged) | DEFAULT_OPTIONS auto-merges |
| `mergeObject(super.defaultOptions, {})` | N/A | Not needed for DEFAULT_OPTIONS |

## Class Inheritance Changes

```javascript
// V12 Actor Sheet
class MyActorSheet extends ActorSheet { }

// V13 Actor Sheet
const { HandlebarsApplicationMixin } = foundry.applications.api
const { ActorSheetV2 } = foundry.applications.sheets
class MyActorSheet extends HandlebarsApplicationMixin(ActorSheetV2) { }
```

```javascript
// V12 Item Sheet
class MyItemSheet extends ItemSheet { }

// V13 Item Sheet
const { ItemSheetV2 } = foundry.applications.sheets
class MyItemSheet extends HandlebarsApplicationMixin(ItemSheetV2) { }
```

```javascript
// V12 Dialog
class MyDialog extends FormApplication { }

// V13 Dialog
const { ApplicationV2, HandlebarsApplicationMixin } = foundry.applications.api
class MyDialog extends HandlebarsApplicationMixin(ApplicationV2) { }
```

## DEFAULT_OPTIONS Migration

```javascript
// V12
static get defaultOptions() {
  return foundry.utils.mergeObject(super.defaultOptions, {
    classes: ['my-system', 'sheet', 'actor'],
    template: 'systems/my-system/templates/actor-sheet.html',
    width: 600,
    height: 600,
    resizable: true,
    tabs: [{
      navSelector: '.tabs',
      contentSelector: '.tab-content',
      initial: 'character'
    }]
  })
}

// V13
static DEFAULT_OPTIONS = {
  classes: ['my-system', 'sheet', 'actor'],
  position: {
    width: 600,
    height: 600
  },
  window: {
    resizable: true,
    title: 'MY_SYSTEM.ActorSheet'
  },
  tag: 'form',
  form: {
    submitOnChange: true
  },
  actions: {
    rollAbilityCheck: this.#rollAbilityCheck
  }
}
```

## Hook Name Changes

### Render Hooks

```javascript
// V12 (Deprecated)
Hooks.on('renderChatMessage', (message, html, data) => {
  // html is jQuery object
})

// V13 (Required)
Hooks.on('renderChatMessageHTML', (message, html, data) => {
  // html is DOM element
  const content = html.querySelector('.message-content')
})
```

### Context Menu Hooks

All context menu hook names changed to `get{DocumentName}ContextOptions`:

| V12 Hook | V13 Hook |
|----------|----------|
| `getChatLogEntryContext` | `getChatMessageContextOptions` |
| `getActorDirectoryEntryContext` | `getActorContextOptions` |
| `getSceneNavigationContext` | `getSceneContextOptions` |
| `getCombatTrackerEntryContext` | `getCombatContextOptions` |
| `getCombatantEntryContext` | `getCombatantContextOptions` |
| `getMacroDirectoryEntryContext` | `getMacroContextOptions` |
| `getPlaylistDirectoryEntryContext` | `getPlaylistContextOptions` |
| `getPlaylistSoundContext` | `getPlaylistSoundContextOptions` |
| `getFolderContext` | `getFolderContextOptions` |
| `getUserContextOptions` | `getUserContextOptions` (unchanged) |

**Signature change:**

```javascript
// V12 — html is jQuery, options is array
Hooks.on("getChatLogEntryContext", (html, options) => {
  options.push({
    name: "Custom Option",
    icon: '<i class="fas fa-star"></i>',
    condition: li => {
      const messageId = li.data("message-id")  // jQuery
      return game.messages.get(messageId)?.isAuthor
    },
    callback: li => {
      const messageId = li.data("message-id")  // jQuery
    }
  })
})

// V13 — application is AppV2 instance, element is HTMLElement
Hooks.on("getChatMessageContextOptions", (application, menuItems) => {
  menuItems.push({
    name: "Custom Option",
    icon: '<i class="fas fa-star"></i>',
    condition: element => {
      const messageId = element.dataset.messageId  // DOM
      return game.messages.get(messageId)?.isAuthor
    },
    callback: element => {
      const messageId = element.dataset.messageId  // DOM
    }
  })
})
```

## Rollable Table Property Changes

```javascript
// V12 (Deprecated)         // V13 (Required)
result.text                  result.description
table.compendium             table.collection
```

## Sheet Registration (Required in V13)

All systems must explicitly register sheets:

```javascript
Hooks.once('init', () => {
  const { Actors, Items } = foundry.documents.collections
  const { ActorSheetV2, ItemSheetV2 } = foundry.applications.sheets

  // Unregister core sheets
  Actors.unregisterSheet('core', ActorSheetV2)
  Items.unregisterSheet('core', ItemSheetV2)

  // Register your sheets
  Actors.registerSheet('my-system', MyActorSheet, {
    types: ['character'],
    makeDefault: true,
    label: 'MY_SYSTEM.SheetCharacter'
  })

  Actors.registerSheet('my-system', MyNPCSheet, {
    types: ['npc'],
    makeDefault: true,
    label: 'MY_SYSTEM.SheetNPC'
  })

  Items.registerSheet('my-system', MyItemSheet, {
    makeDefault: true,
    label: 'MY_SYSTEM.SheetItem'
  })
})
```

## CSS Layer Changes

V13 introduces CSS Layers, which may break existing styles:
- Checkboxes now use FontAwesome icons instead of native checkboxes
- Style `::before` and `::after` pseudo-elements for checkboxes
- Test all UI elements after migration

## Template Changes

### ProseMirror Editor

```handlebars
{{!-- V12 (Deprecated) --}}
{{editor descriptionHTML target="system.description" engine="prosemirror" button=true editable=editable}}

{{!-- V13 (Required) --}}
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

## Migration Checklist

### Pre-Migration
- [ ] Take baseline screenshots of all components
- [ ] Create backup of V1 implementation

### Core Steps
1. [ ] Register all actor and item sheets explicitly
2. [ ] Choose correct base class (ActorSheetV2, ItemSheetV2, ApplicationV2, DialogV2)
3. [ ] Update class inheritance with HandlebarsApplicationMixin
4. [ ] Convert `defaultOptions` to `DEFAULT_OPTIONS`
5. [ ] Add `tag: 'form'` for forms/dialogs
6. [ ] Move dimensions to `position` object
7. [ ] Move window properties to `window` object
8. [ ] Rename `getData()` to `_prepareContext()`
9. [ ] Define `PARTS` for templates

### Event System
10. [ ] Convert `activateListeners` to `actions`
11. [ ] Change handler methods from `_` prefix to static `#` prefix
12. [ ] Update templates with `data-action` attributes

### Tab System
13. [ ] Split monolithic templates into tab templates
14. [ ] Define `TABS` configuration
15. [ ] Implement `_getTabsConfig()` for dynamic tabs

### Advanced
16. [ ] Set up drag/drop (automatic for ActorSheetV2, manual for ApplicationV2)
17. [ ] Migrate `{{editor}}` to `<prose-mirror>`
18. [ ] Update image editing to use inherited `editImage`
19. [ ] Replace jQuery with vanilla JS in hooks
20. [ ] Replace deprecated namespace references
21. [ ] Update hook names

### Theme
22. [ ] Create `variables.css` with CSS custom properties
23. [ ] Add to `system.json` with `"layer": "variables"`
24. [ ] Define light and dark theme variables
25. [ ] Use `system-` prefix for CSS variables

### Validation
26. [ ] Run tests
27. [ ] Test all functionality end-to-end
28. [ ] Test drag/drop operations
29. [ ] Test theme switching
30. [ ] Verify performance

## Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Dialog not opening | Wrong constructor pattern | Use `new Dialog({ document: actor })` |
| All tabs visible | CSS display on tab container | Move display styles to inner elements |
| Actions not firing | Wrong `data-action` value | Must match actions object key exactly |
| Form not submitting | Missing `tag: 'form'` | Add to DEFAULT_OPTIONS |
| CONFIG undefined | CONFIG in static initializer | Hard-code template paths |
| Drag/drop broken | Missing setup for AppV2 | Use `.draggable` class for ActorSheetV2 or manual DragDrop for ApplicationV2 |
| Items not saving | Nested item data stripped | Override `_processFormData` and `_processSubmitData` |
| Theme not applying | Wrong CSS layer config | Add `"layer": "variables"` to system.json |
