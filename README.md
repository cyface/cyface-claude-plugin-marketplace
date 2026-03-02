# Cyface Claude Code Plugin Marketplace

A local [Claude Code](https://claude.ai/code) plugin marketplace for custom plugins by Cyface.

## Plugins

| Plugin | Description |
|--------|-------------|
| [alpine-htmx](https://github.com/cyface/alpine-htmx-claude-plugin) | Expert guidance for Alpine.js v3 and HTMX development — directives, attributes, patterns, and combined usage. Includes a proactive code reviewer. |

## Setup

Register this marketplace in Claude Code:

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
│   └── alpine-htmx/       # Each plugin is its own git repo
└── README.md
```

Each plugin under `plugins/` is an independent git repository. The marketplace repo only tracks the marketplace manifest and configuration — not the plugin contents.
