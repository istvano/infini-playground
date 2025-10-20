#!/usr/bin/env bash
set -euo pipefail
HOST=${1:-http://localhost:11222}
CACHE=${2:-sessions}
AUTH=(-u admin:password)

echo "Backups status:"
curl -sS "${HOST}/rest/v2/caches/${CACHE}/x-site/backups/" "${AUTH[@]}" | jq . || true

# Examples:
# Bring Vienna online (from Budapest):
# curl -sS -X POST "${HOST}/rest/v2/caches/${CACHE}/x-site/backups/Vienna?action=bring-online" "${AUTH[@]}"
# Bring London online (from Budapest):
# curl -sS -X POST "${HOST}/rest/v2/caches/${CACHE}/x-site/backups/London?action=bring-online" "${AUTH[@]}"
