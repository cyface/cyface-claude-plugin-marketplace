#!/usr/bin/env bash
# Wrapper for Coolify API calls - sources .env from CWD and calls curl
# Usage: coolify.sh <endpoint> [curl-args...]
set -euo pipefail

if [[ ! -f .env ]]; then
  echo "Error: No .env file in current directory" >&2
  exit 1
fi

source .env

if [[ -z "${COOLIFY_URL:-}" || -z "${COOLIFY_API_TOKEN:-}" ]]; then
  echo "Error: COOLIFY_URL and COOLIFY_API_TOKEN must be set in .env" >&2
  exit 1
fi

ENDPOINT="$1"
shift

curl -s "${COOLIFY_URL}/api/v1${ENDPOINT}" \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  "$@"