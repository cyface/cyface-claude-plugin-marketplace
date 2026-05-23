# foundryvtt-dev

A Claude Code plugin providing expert guidance for **FoundryVTT v13** system and module development — ApplicationV2 migration, sheets, forms, actions, tabs, drag-drop, hooks, data model, testing, and i18n.

> **Disclaimer**: This is a community-created resource and is not affiliated with, endorsed by, or associated with Foundry Gaming LLC. "FoundryVTT" is a trademark of Foundry Gaming LLC.

## What's Included

### Skills

| Skill | Triggers On | What It Provides |
|-------|-------------|------------------|
| **ApplicationV2 Development** | ApplicationV2, ActorSheetV2, ItemSheetV2, DocumentSheetV2, DialogV2, DEFAULT_OPTIONS, PARTS, data-action, _prepareContext, sheets, forms, tabs, drag-drop, V12-to-V13 migration | Class hierarchy, HandlebarsApplicationMixin, DEFAULT_OPTIONS, PARTS, _prepareContext, actions system, form handling, tab system, drag-drop, image editing, ProseMirror, sheet registration, CSS theming |
| **FoundryVTT System Development** | FoundryVTT system/module, hooks, data model, template.json, Actor, Item, Roll, compendium, packs, settings, i18n, testing | Project structure, data model, document types, hooks lifecycle, settings registration, Roll system, compendium management, CSS/SCSS, i18n, testing overview |

Both skills include comprehensive reference files with complete code examples.

### Agent

| Agent | Triggers | What It Does |
|-------|----------|--------------|
| **foundryvtt-reviewer** | Proactively after writing FoundryVTT code | Reviews for deprecated V12 patterns, ApplicationV2 mistakes, template issues, i18n violations, security issues, and common errors |

## Installation

```bash
# From the Claude Code marketplace (recommended)
/install foundryvtt-dev

# Or install directly from GitHub
claude plugin add --git https://github.com/cyface/foundryvtt-dev-claude-plugin.git
```

## Skills Detail

### ApplicationV2 Development

Covers FoundryVTT v13 ApplicationV2 essentials:
- Class hierarchy (`ApplicationV2` -> `DocumentSheetV2` -> `ActorSheetV2`/`ItemSheetV2`, `DialogV2`)
- `HandlebarsApplicationMixin` pattern
- `DEFAULT_OPTIONS` configuration (position, window, form, actions)
- `PARTS` template definitions
- `_prepareContext()` (replaces `getData`)
- Actions system with `data-action` (replaces `activateListeners`)
- Form handling (`tag: 'form'`, `submitOnChange`, explicit handlers)
- Tab system (`TABS`, tab templates, dynamic tabs)
- Drag and drop (automatic via ActorSheetV2, manual setup for ApplicationV2)
- Image editing (inherited `editImage`)
- ProseMirror editor migration
- Sheet registration
- Constructor patterns
- CSS theming with variables and layers

### FoundryVTT System Development

Covers system/module development fundamentals:
- System file structure
- Data model (`template.json`)
- Document types (Actor, Item, custom classes)
- Hooks system (init, ready, render, update lifecycle)
- Settings registration (world, client, hidden, menus)
- Roll system basics
- Compendium/pack management (JSON <-> LevelDB workflow)
- CSS/SCSS patterns
- Internationalization (i18n) and localization
- Testing strategy with Vitest

### Code Reviewer Agent

Automatically checks for:
- **Deprecated V12 patterns**: jQuery, `data` instead of `system`, old constructors, deprecated namespaces, old hook names
- **ApplicationV2 mistakes**: Missing `tag: 'form'`, `getData` instead of `_prepareContext`, `activateListeners` instead of actions, missing `HandlebarsApplicationMixin`
- **Template issues**: `<form>` inside `tag: 'form'` app, missing `data-action`, wrong tab structure, missing `data-tab`/`data-group`
- **Common errors**: Wrong sheet registration, missing `unregisterSheet`, inline item editing without `_processFormData`
- **i18n violations**: Hardcoded user-facing strings
- **Security**: Unescaped HTML, missing permission checks

## File Structure

```
foundryvtt-dev/
+-- .claude-plugin/
|   +-- plugin.json
+-- skills/
|   +-- appv2/
|   |   +-- SKILL.md
|   |   +-- references/
|   |       +-- appv2-migration.md
|   |       +-- appv2-patterns.md
|   +-- foundryvtt-system/
|       +-- SKILL.md
|       +-- references/
|           +-- hooks-and-documents.md
|           +-- testing-and-i18n.md
+-- agents/
|   +-- foundryvtt-reviewer.md
+-- README.md
+-- PRIVACY.md
+-- LICENSE
```

## FoundryVTT Version

- **Target**: FoundryVTT v13 (ApplicationV2 API)
- Includes V12-to-V13 migration guidance

## License

MIT
