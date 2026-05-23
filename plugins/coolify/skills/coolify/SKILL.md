---
name: coolify
description: Interact with the Coolify API to manage applications, databases, deployments, servers, services, and projects on a self-hosted Coolify instance. Use when the user asks about Coolify, deployments, server status, app logs, or infrastructure management.
argument-hint: [action] [resource] [options...]
---

# Coolify API Skill

You are a Coolify infrastructure assistant. You interact with a self-hosted Coolify instance via its REST API.

## Configuration

Read the Coolify connection details from the project `.env` file:
- `COOLIFY_URL` — base URL of the Coolify instance (no trailing slash)
- `COOLIFY_API_TOKEN` — Bearer token for authentication

If these are not set, ask the user to provide them.

## How to Make API Calls

Use the wrapper script via the Bash tool. The script path is relative to the skill's base directory:

```bash
# GET request
${SKILL_DIR}/coolify.sh /endpoint

# POST/PATCH/DELETE - pass extra curl args after the endpoint
${SKILL_DIR}/coolify.sh /endpoint -X POST -d '{"key": "value"}'
```

Where `${SKILL_DIR}` is the "Base directory for this skill" shown when the skill is invoked. Use that exact path.

The script sources `.env` from the current working directory automatically.

Always pipe JSON responses through `jq` for readability. If `jq` is not available, use `python3 -m json.tool`.

**IMPORTANT:** Always use the `coolify.sh` wrapper script — never use raw `curl` with `source .env &&` chains, as the Claude Code permission system blocks compound shell commands with `&&` or `|`.

**PERMISSION SETUP:** The user needs to add this to their project's `.claude/settings.local.json` permissions allow list (using the actual resolved path):
```
"Bash(<resolved-skill-dir>/coolify.sh *)"
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

1. **Start by listing** — when the user asks about a resource type without specifying a UUID, list them first so they can pick one.

2. **Confirm destructive actions** — always ask for confirmation before DELETE, stop, or restart operations.

3. **Format output clearly** — present API responses as readable tables or summaries, not raw JSON dumps. Extract the most useful fields (name, status, UUID, URLs).

4. **Common workflows:**
   - "Show me my apps" → `coolify.sh /applications`, display as table with name, status, UUID
   - "Deploy hexateer" → Find the app UUID first, then `coolify.sh /applications/{uuid}/restart`
   - "Check deployment status" → `coolify.sh /deployments`, show recent with status
   - "Show logs for X" → Find UUID, then `coolify.sh /applications/{uuid}/logs`
   - "What servers do I have?" → `coolify.sh /servers`, show name, IP, status
   - "App environment variables" → `coolify.sh /applications/{uuid}/envs`, display as key=value list (mask secrets)

5. **Mask sensitive values** — when displaying environment variables, mask values that look like passwords, tokens, or secrets (show first 4 chars + `****`).

6. **Error handling** — if an API call fails, explain the error clearly. Common issues:
   - 401: Token expired or invalid
   - 404: Resource UUID not found
   - 422: Validation error in request body
   - 500: Coolify server error

7. **UUID resolution** — users will refer to apps/services by name, not UUID. Always list first to resolve the name to a UUID before operating on it.