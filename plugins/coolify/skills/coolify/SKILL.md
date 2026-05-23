---
name: coolify
description: This skill should be used when the user asks about "Coolify", "deploy app", "restart app", "app logs", "deployment status", "list servers", "list databases", "environment variables", or any other management of applications, databases, deployments, servers, services, or projects on a self-hosted Coolify instance via its REST API.
---

# Coolify API Skill

Manage a self-hosted Coolify instance via its REST API. Use this skill to inspect and operate on applications, databases, deployments, servers, services, projects, teams, and private keys.

## Configuration

Read the Coolify connection details from the project `.env` file:
- `COOLIFY_URL` — base URL of the Coolify instance (no trailing slash)
- `COOLIFY_API_TOKEN` — Bearer token for authentication

If either value is missing, ask the user to provide it before making any API calls.

## How to Make API Calls

Use the wrapper script via the Bash tool. Always reference it via the `${CLAUDE_PLUGIN_ROOT}` environment variable so the path resolves correctly regardless of where the plugin is installed:

```bash
# GET request
${CLAUDE_PLUGIN_ROOT}/skills/coolify/coolify.sh /endpoint

# POST/PATCH/DELETE - pass extra curl args after the endpoint
${CLAUDE_PLUGIN_ROOT}/skills/coolify/coolify.sh /endpoint -X POST -d '{"key": "value"}'
```

The script sources `.env` from the current working directory automatically.

Always pipe JSON responses through `jq` for readability. If `jq` is not available, use `python3 -m json.tool`.

**IMPORTANT:** Always use the `coolify.sh` wrapper script — never use raw `curl` with `source .env &&` chains, as the Claude Code permission system blocks compound shell commands with `&&` or `|`.

**PERMISSION SETUP:** To avoid permission prompts on every call, add this to the project's `.claude/settings.local.json` permissions allow list:
```json
"Bash(${CLAUDE_PLUGIN_ROOT}/skills/coolify/coolify.sh *)"
```

## Available API Endpoints

**IMPORTANT:** The `coolify.sh` script automatically prepends `/api/v1` to endpoints. Pass only the path after `/api/v1` — e.g., use `/applications`, NOT `/api/v1/applications`.

### Applications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/applications` | List all applications |
| GET | `/applications/{uuid}` | Get application details |
| PATCH | `/applications/{uuid}` | Update application |
| DELETE | `/applications/{uuid}` | Delete application |
| GET | `/applications/{uuid}/logs` | Get application logs |
| GET | `/applications/{uuid}/envs` | List environment variables |
| POST | `/applications/{uuid}/envs` | Create environment variable |
| PATCH | `/applications/{uuid}/envs` | Update environment variable |
| PATCH | `/applications/{uuid}/envs/bulk` | Bulk update env vars |
| DELETE | `/applications/{uuid}/envs/{env_uuid}` | Delete environment variable |
| GET | `/applications/{uuid}/start` | Start application |
| GET | `/applications/{uuid}/stop` | Stop application |
| GET | `/applications/{uuid}/restart` | Restart application |
| POST | `/applications/public` | Create from public git repo |
| POST | `/applications/private-github-app` | Create from private GitHub App |
| POST | `/applications/private-deploy-key` | Create from private deploy key |
| POST | `/applications/dockerfile` | Create from Dockerfile |
| POST | `/applications/dockerimage` | Create from Docker image |
| POST | `/applications/dockercompose` | Create from Docker Compose |

### Databases
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/databases` | List all databases |
| GET | `/databases/{uuid}/backups` | Get backup details |
| POST | `/databases/{uuid}/backups` | Create backup configuration |
| GET | `/databases/{uuid}/backups/{backup_uuid}` | Get specific backup |
| DELETE | `/databases/{uuid}/backups/{backup_uuid}` | Delete backup |

### Deployments
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/deployments` | List all deployments |
| GET | `/deployments/{uuid}` | Get deployment details |
| GET | `/deployments/{uuid}/logs` | Get deployment logs |

### Servers
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/servers` | List all servers |
| POST | `/servers` | Create a server |
| GET | `/servers/{uuid}` | Get server details |
| PATCH | `/servers/{uuid}` | Update server |
| DELETE | `/servers/{uuid}` | Delete server |

### Services
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/services` | List all services |
| POST | `/services` | Create a service |
| GET | `/services/{uuid}` | Get service details |
| PATCH | `/services/{uuid}` | Update service |
| DELETE | `/services/{uuid}` | Delete service |
| GET | `/services/{uuid}/logs` | Get service logs |
| GET | `/services/{uuid}/envs` | List environment variables |
| POST | `/services/{uuid}/envs` | Create environment variable |
| PATCH | `/services/{uuid}/envs` | Update environment variable |
| DELETE | `/services/{uuid}/envs/{env_uuid}` | Delete environment variable |

### Projects
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/projects` | List all projects |
| POST | `/projects` | Create a project |
| GET | `/projects/{uuid}` | Get project details |
| DELETE | `/projects/{uuid}` | Delete project |

### Teams
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/teams` | List all teams |
| GET | `/teams/{uuid}` | Get team details |

### Security (Private Keys)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/security/private-keys` | List private keys |
| POST | `/security/private-keys` | Create private key |
| DELETE | `/security/private-keys/{uuid}` | Delete private key |

## Behavior Guidelines

1. **List first to resolve names to UUIDs.** Users refer to apps and services by name, not UUID. When a request targets a specific resource without a UUID, list the resource type first and match the name before operating on it.

2. **Confirm destructive actions.** Ask for explicit confirmation before any DELETE, stop, or restart operation.

3. **Format output clearly.** Present API responses as readable tables or summaries — extract useful fields (name, status, UUID, URLs) rather than dumping raw JSON.

4. **Mask sensitive values.** When displaying environment variables, mask values that look like passwords, tokens, or secrets (show the first 4 characters followed by `****`).

5. **Explain API errors.** When a call fails, surface the status code and likely cause:
   - 401: Token expired or invalid
   - 404: Resource UUID not found
   - 422: Validation error in request body
   - 500: Coolify server error

## Common Workflows

| User says | Action |
|-----------|--------|
| "Show me my apps" | `coolify.sh /applications` → table of name, status, UUID |
| "Deploy hexateer" | Resolve UUID, then `coolify.sh /applications/{uuid}/restart` |
| "Check deployment status" | `coolify.sh /deployments` → recent deployments with status |
| "Show logs for X" | Resolve UUID, then `coolify.sh /applications/{uuid}/logs` |
| "What servers do I have?" | `coolify.sh /servers` → table of name, IP, status |
| "App environment variables" | Resolve UUID, then `coolify.sh /applications/{uuid}/envs` → key=value list with secrets masked |