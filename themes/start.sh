#!/usr/bin/env bash
set -euo pipefail

PMTILES=/data/openmaptiles/openmaptiles.pmtiles
python3 /workspace/scripts/validate-openmaptiles-pmtiles.py --require-world "$PMTILES"
STYLE_ASSET_ROOT=/data/style-assets node /workspace/scripts/verify-local-styles.mjs
exec /usr/src/app/docker-entrypoint.sh --config /data/config.json -s
