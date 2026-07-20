#!/usr/bin/env bash
set -euo pipefail

OUT=/data/openmaptiles
SOURCE=/data/planet.osm.pbf
PART=$OUT/openmaptiles.pmtiles.part
mkdir -p "$OUT/sources" "$OUT/tmp"
test -s "$SOURCE"
rm -f "$PART"

java -jar /app/planetiler-openmaptiles.jar \
  --osm_path="$SOURCE" \
  --download_dir="$OUT/sources" \
  --tmpdir="$OUT/tmp" \
  --output="$PART?format=pmtiles" \
  --storage=mmap \
  --nodemap-type=array \
  --fetch-wikidata \
  --download --force

python3 /workspace/scripts/validate-openmaptiles-pmtiles.py --require-world "$PART"
SHA=$(sha256sum "$PART" | cut -c1-16)
ARTIFACT=$OUT/openmaptiles-$SHA.pmtiles
if [ -e "$ARTIFACT" ]; then
  cmp -s "$PART" "$ARTIFACT"
  rm -f "$PART"
else
  mv "$PART" "$ARTIFACT"
fi
ln -sfn "$(basename "$ARTIFACT")" "$OUT/openmaptiles.pmtiles"

python3 /workspace/scripts/artifact_manifest.py write \
  --kind openmaptiles-pmtiles \
  --source "$SOURCE" \
  --artifact "$ARTIFACT" \
  --source-ref v3.16 \
  --source-commit 5be22807170439320354b39ed9b390aa796a2cee \
  --local-source /workspace/base-styles/planetiler \
  --local-source /workspace/base-styles/planetiler-openmaptiles \
  --manifest "$OUT/manifest.json"
