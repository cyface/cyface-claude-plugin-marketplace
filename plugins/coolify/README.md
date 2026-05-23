# Coolify Claude Plugin

A [Claude Code](https://claude.com/claude-code) plugin that lets Claude manage a self-hosted [Coolify](https://coolify.io/) instance through its REST API. Ask Claude about your apps, deployments, databases, servers, and services in natural language and it will call the right endpoints for you.

## What it does

Once installed, Claude can:

- List and inspect applications, databases, services, servers, projects, and teams
- Start, stop, restart, and deploy applications
- View application, deployment, and service logs
- Manage environment variables (with automatic masking of secrets)
- Create and delete resources (with confirmation before destructive actions)
- Manage database backups and private keys

See [`skills/coolify/SKILL.md`](skills/coolify/SKILL.md) for the full endpoint reference.

## Installation

Clone or copy this repository into your Claude Code plugins directory, or reference it directly from a project that uses Claude Code.

The plugin exposes a single skill (`coolify`) that activates automatically when you ask Claude about Coolify, deployments, server status, app logs, or related topics.

## Configuration

In the project where you want to use the plugin, create a `.env` file with your Coolify connection details:

```bash
COOLIFY_URL=https://coolify.example.com
COOLIFY_API_TOKEN=your-bearer-token-here
```

`COOLIFY_URL` should have no trailing slash. The API token can be generated from your Coolify instance under **Keys & Tokens → API tokens**.

### Permissions

The skill calls a wrapper script (`coolify.sh`) via the Bash tool. To avoid prompting on every call, add an entry to your project's `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(${CLAUDE_PLUGIN_ROOT}/skills/coolify/coolify.sh *)"
    ]
  }
}
```

`${CLAUDE_PLUGIN_ROOT}` is set by Claude Code to the plugin's install directory, so this entry works regardless of where the plugin lives on disk.

## Usage

Just talk to Claude:

- "Show me my Coolify apps"
- "What's the status of the hexateer deployment?"
- "Tail the logs for the api service"
- "Restart the staging app"
- "List environment variables for the marketing site"

Claude will list resources first to resolve names to UUIDs, then perform the requested action. Destructive operations (delete, stop, restart) are confirmed before running.

## How it works

- `.claude-plugin/plugin.json` — plugin manifest
- `skills/coolify/SKILL.md` — the skill's instructions to Claude, including the full endpoint reference
- `skills/coolify/coolify.sh` — thin curl wrapper that sources `.env` and calls the Coolify API

The wrapper automatically prepends `/api/v1` to endpoints, sets the `Authorization` and `Content-Type` headers, and forwards any extra arguments to curl (so `-X POST -d '{...}'` works as expected).

## Repository

<https://github.com/cyface/coolify-claude-plugin>

## License

MIT
