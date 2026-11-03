# Cyface Design Claude Code Plugin Marketplace

A [Claude Code](https://claude.ai/code) plugin marketplace for custom plugins by Cyface Design.

## Plugins

| Plugin | Description |
|--------|-------------|
| [alpine-htmx](plugins/alpine-htmx) | Expert guidance for Alpine.js v3 and htmx (2.x and 4) — directives, attributes, patterns, and combined usage. Includes htmx upgrade and debugging skills and a proactive code reviewer. |
| [foundryvtt-dev](plugins/foundryvtt-dev) | Expert guidance for FoundryVTT v14 system and module development — ApplicationV2, data models, hooks, Regions, testing, and i18n. Includes a proactive code reviewer. Not affiliated with Foundry Gaming LLC. |
| [ui-design-principles](plugins/ui-design-principles) | Expert UI/UX design guidance based on Universal Principles of Design — visual hierarchy, interaction patterns, cognitive load, accessibility, and layout. Includes a proactive design reviewer. |
| [coolify](plugins/coolify) | Interact with a self-hosted Coolify instance via its REST API — manage applications, databases, deployments, servers, services, and projects. |

## Setup

Register this marketplace in Claude Code from GitHub:

```
/plugin marketplace add cyface/cyface-claude-plugin-marketplace
```

Or from a local clone:

```
/plugin marketplace add /path/to/cyface-claude-plugin-marketplace
```

Then enable a plugin in your project's `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "alpine-htmx@cyface": true
  }
}
```

## Structure

```
cyface-claude-plugin-marketplace/
├── .claude-plugin/
│   └── marketplace.json    # Plugin registry
├── plugins/
│   ├── alpine-htmx/
│   ├── coolify/
│   ├── foundryvtt-dev/
│   └── ui-design-principles/
└── README.md
```

Plugin contents live directly in this repository under `plugins/`, so the marketplace is fully self-contained.
