#!/usr/bin/env bash
set -euo pipefail
docker network inspect wan >/dev/null 2>&1 || docker network create wan
echo "WAN network ready: 'wan'"
