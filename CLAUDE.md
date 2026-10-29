# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A local Claude Code plugin marketplace maintained by Cyface Design. It serves as a registry that maps plugin names to their source directories. There is no build system, no tests, and no dependencies — this is a content-only repository of JSON manifests and markdown reference files.

## Repository Structure

- `.claude-plugin/marketplace.json` — The marketplace registry. Lists all available plugins with name, description, source path, and category.
- `plugins/` — Contains plugin directories. Plugin contents are committed directly in this repo (inlined), so the marketplace can be installed straight from GitHub with `/plugin marketplace add cyface/cyface-claude-plugin-marketplace`. Do not create nested git repos inside `plugins/`.

## Adding a New Plugin

1. Create the plugin directory under `plugins/<plugin-name>/`
2. Ensure it has a `.claude-plugin/plugin.json` manifest with `name`, `version`, `description`, `author`, and `keywords`
3. Add an entry to `.claude-plugin/marketplace.json` in the `plugins` array with `name`, `description`, `source` (relative path like `./plugins/<name>`), and `category`
4. Update the plugins table in `README.md`
5. Commit the plugin directory along with the manifest and README changes in this repo, then push (via a branch and PR to `main`)

## Plugin Manifest Format

Each plugin's `.claude-plugin/plugin.json`:
```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "...",
  "author": { "name": "Tim White" },
  "keywords": ["..."]
}
```

Marketplace registry `.claude-plugin/marketplace.json`:
```json
{
  "plugins": [
    {
      "name": "plugin-name",
      "description": "...",
      "source": "./plugins/plugin-name",
      "category": "development"
    }
  ]
}
```

## Key Conventions

- Plugin names use kebab-case
- Marketplace name is `"cyface"` — plugins are referenced as `<plugin-name>@cyface`
- Keep descriptions concise but specific about what the plugin provides
- The `source` field in marketplace.json uses relative paths from the repo root