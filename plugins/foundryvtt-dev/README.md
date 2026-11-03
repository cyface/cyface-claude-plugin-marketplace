# foundryvtt-dev

A Claude Code plugin providing expert guidance for **FoundryVTT v14** system and module development — data models, Active Effects V2, ApplicationV2 sheets, Regions, Scene Levels, hooks, testing, and i18n. Includes a V13→V14 (and V12→V13) migration reference.

> **Disclaimer**: This is a community-created resource and is not affiliated with, endorsed by, or associated with Foundry Gaming LLC. "FoundryVTT" is a trademark of Foundry Gaming LLC.

## What's Included

### Skills

| Skill | Triggers On | What It Provides |
|-------|-------------|------------------|
| **ApplicationV2 Development** | ApplicationV2, ActorSheetV2, ItemSheetV2, DocumentSheetV2, DialogV2, DEFAULT_OPTIONS, PARTS, data-action, _prepareContext, sheets, forms, tabs, drag-drop, detached windows, V13-to-V14 or V12-to-V13 migration | Class hierarchy, HandlebarsApplicationMixin, DEFAULT_OPTIONS, PARTS, `_prepareContext`/`_preparePartContext`, actions system, form pipeline, tab system, drag-drop, image editing, ProseMirror, sheet registration, pop-out windows, CSS theming |
| **FoundryVTT System Development** | system/module development, TypeDataModel, defineSchema, documentTypes, hooks, Active Effects, Regions, Scene Levels, Actor, Item, Roll, compendium packs, settings, i18n, testing | Project structure, data models, document types, Active Effects V2, hooks lifecycle, settings, Roll and message modes, batched updates, pack management, CSS/SCSS, i18n, testing |

Both skills include reference files with complete, verified code examples.

### Agent

| Agent | Triggers | What It Does |
|-------|----------|--------------|
| **foundryvtt-reviewer** | Proactively after writing FoundryVTT code | Reviews for V13/V12 patterns that break under V14, data model and Active Effects mistakes, ApplicationV2 errors, template issues, i18n violations, security issues |

## Install

```text
/plugin install foundryvtt-dev --marketplace cyface/cyface-claude-plugin-marketplace
```

That single command works on Claude Code 2.1.275 or later. On older versions, add the [cyface marketplace](https://github.com/cyface/cyface-claude-plugin-marketplace) first:

```text
/plugin marketplace add cyface/cyface-claude-plugin-marketplace
/plugin install foundryvtt-dev@cyface
```

From a shell: `claude plugin marketplace add cyface/cyface-claude-plugin-marketplace && claude plugin install foundryvtt-dev@cyface`. To try a local checkout without installing: `claude --plugin-dir ./foundryvtt-dev-claude-plugin`.

## Skills Detail

### ApplicationV2 Development

- Class hierarchy (`ApplicationV2` → `DocumentSheetV2` → `ActorSheetV2`/`ItemSheetV2`, `DialogV2`)
- `HandlebarsApplicationMixin`, `PARTS`, sub-templates and scrollable regions
- `DEFAULT_OPTIONS` (position, window, form, actions), including V14's Detach/Attach header controls
- `_prepareContext()` and `_preparePartContext()`; the `fields` / `source` context and schema-driven form helpers
- Actions system with `data-action`, including the `{ handler, buttons }` form
- Form pipeline: `tag: 'form'`, `submitOnChange`, `_processFormData` → `_processSubmitData`
- Tab system: `static TABS`, `labelPrefix`, the `context.tabs` **record**, and the `data-action="tab"` requirement
- Drag and drop (automatic via ActorSheetV2, manual `DragDrop` for plain ApplicationV2)
- Image editing, ProseMirror, sheet registration, constructor patterns
- Detached (pop-out) windows and how to make a sheet detach-safe
- CSS theming, including the two V14 traps: dead `body.game .app` variables and the light-themed chat log

### FoundryVTT System Development

- System file structure and `system.json` manifest (compatibility, documentTypes, relationships, styles layers)
- **Data models**: `TypeDataModel`, `defineSchema`, reusable field classes, `migrateData` (`template.json` is deprecated, removed in V16)
- Document classes, and why every `prepareBaseData()` override must call super in V14
- **Active Effects V2**: `system.changes`, string change types, two-phase application, custom change types, duration units and expiry events
- Hooks lifecycle, including context-menu hooks that fire only at first render
- Settings registration and menus
- Roll system and V14 **message modes** (`public`/`gm`/`blind`/`self`/`ic`)
- **Regions** replacing MeasuredTemplate; **Scene Levels**
- Batched document updates via `foundry.documents.modifyBatch`
- Compendium/pack management (JSON ↔ LevelDB), CSS/SCSS, i18n, Vitest testing

## File Structure

```
foundryvtt-dev/
+-- .claude-plugin/
|   +-- plugin.json
+-- skills/
|   +-- appv2/
|   |   +-- SKILL.md
|   |   +-- references/
|   |       +-- appv2-migration.md      # V13→V14 and V12→V13
|   |       +-- appv2-patterns.md
|   +-- foundryvtt-system/
|       +-- SKILL.md
|       +-- references/
|           +-- v14-changes.md          # V13→V14 data/document changes
|           +-- hooks-and-documents.md
|           +-- testing-and-i18n.md
+-- agents/
|   +-- foundryvtt-reviewer.md
+-- README.md
+-- CHANGELOG.md
+-- PRIVACY.md
+-- LICENSE
```

## FoundryVTT Version

- **Target**: FoundryVTT v14
- **Last verified against**: FoundryVTT **14.369** Stable, on 2026-10-30
  (this line and `metadata.foundryVerified` in `.claude-plugin/plugin.json` are the only places the build number is recorded; the skills and reference files deliberately say "V14" and defer here)
- Requires **Node.js 24** (`>=24.13.1 <25`) for system tooling
- Includes V13→V14 migration guidance, and V12→V13 for packages still on AppV1

## License

MIT
