#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
grep -Fq -- '- ./data/openmaptiles:/data/openmaptiles:ro' "$ROOT/docker-compose.yml"
grep -Fq -- '- ./data/style-assets:/data/style-assets:ro' "$ROOT/docker-compose.yml"
grep -Fq -- '- ./data:/data' "$ROOT/docker-compose.yml"
git -C "$ROOT" check-ignore -q data/runtime-download
! grep -Eqi 'postgres|database18|region\.poly' "$ROOT/docker-compose.yml"
echo "local PMTiles data configuration is valid"
