#!/usr/bin/env bash
set -euo pipefail

python3 /workspace/scripts/artifact_manifest.py verify \
  --source /data/region.osm.pbf \
  --artifact /data/openmaptiles/openmaptiles.mbtiles \
  --local-source /workspace/base-styles/planetiler \
  --local-source /workspace/base-styles/planetiler-openmaptiles \
  --manifest /data/openmaptiles/manifest.json

for pair in light:positron dark:dark-matter natural:osm-bright; do
  style=${pair%%:*}
  source=${pair##*:}
  python3 /workspace/scripts/artifact_manifest.py verify \
    --source /data/region.osm.pbf \
    --artifact "/data/style-assets/$style/style.json" \
    --local-source "/workspace/base-styles/$source" \
    --manifest "/data/style-assets/$style/manifest.json"
done

node /workspace/scripts/verify-local-styles.mjs
exec /usr/src/app/docker-entrypoint.sh --config /data/config.json
