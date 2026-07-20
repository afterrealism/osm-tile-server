#!/usr/bin/env bash
set -euo pipefail

OUT=/data/openmaptiles
mkdir -p "$OUT"
rm -f "$OUT/openmaptiles.mbtiles.part"

java -jar /app/planetiler-openmaptiles.jar \
  --osm_path=/data/region.osm.pbf \
  --output="$OUT/openmaptiles.mbtiles.part?format=mbtiles" \
  --download --force

python3 /workspace/scripts/validate-openmaptiles.py "$OUT/openmaptiles.mbtiles.part"
mv "$OUT/openmaptiles.mbtiles.part" "$OUT/openmaptiles.mbtiles"
python3 /workspace/scripts/artifact_manifest.py write \
  --kind openmaptiles --source /data/region.osm.pbf \
  --artifact "$OUT/openmaptiles.mbtiles" \
  --source-ref v3.16 \
  --source-commit 5be22807170439320354b39ed9b390aa796a2cee \
  --local-source /workspace/base-styles/planetiler \
  --local-source /workspace/base-styles/planetiler-openmaptiles \
  --manifest "$OUT/manifest.json"
