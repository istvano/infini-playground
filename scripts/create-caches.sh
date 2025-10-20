#!/usr/bin/env bash
set -euo pipefail
HOST=${1:-http://localhost:11222}
AUTH=(-u admin:password)

# Create a Keycloak-friendly template (protostream + async backups example)
curl -sS "${HOST}/rest/v2/cache-config/templates/keycloak-template" \
  -H 'Content-Type: application/json' \
  -d '{
    "distributed-cache":{
      "mode":"SYNC",
      "encoding":{"media-type":"application/x-protostream"},
      "statistics":true,
      "backups":[
        {"site":"Vienna","strategy":"ASYNC","failure-policy":"FAIL"},
        {"site":"London","strategy":"ASYNC","failure-policy":"FAIL"}
      ]
    }
  }' "${AUTH[@]}"

# Example: precreate a sessions cache using the template
curl -sS -X POST \
  "${HOST}/rest/v2/caches/sessions?template=keycloak-template" \
  "${AUTH[@]}"
