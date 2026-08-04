#!/usr/bin/env bash
set -euo pipefail

OUT=/data/openmaptiles
SOURCE=/data/planet.osm.pbf
PART=$OUT/openmaptiles.pmtiles.part
mkdir -p "$OUT/sources" "$OUT/tmp"
test -s "$SOURCE"
exec 9>"$OUT/.build.lock"
if ! flock -n 9; then
  echo "another openmaptiles build is already running" >&2
  exit 1
fi
rm -f "$PART"

# All non-OSM inputs must match the committed pins before java starts; the
# java invocation below never touches the network (no --download) except the
# sanctioned wikidata bootstrap when the cache is absent.
LOCK=/workspace/scripts/openmaptiles-sources.sha256
(cd "$OUT" && grep -v wikidata_names "$LOCK" | sha256sum --strict -c -)
if [ -s "$OUT/sources/wikidata_names.json" ]; then
  (cd "$OUT" && grep wikidata_names "$LOCK" | sha256sum --strict -c -)
else
  echo "wikidata_names.json absent; planetiler will derive it via query.wikidata.org (re-pin with scripts/fetch-openmaptiles-sources.sh --pin)" >&2
fi

WIKIDATA_ARGS=()
if [ ! -s "$OUT/sources/wikidata_names.json" ]; then
  WIKIDATA_ARGS=(--fetch-wikidata)
fi

BUILD_ARGS=()
if [ "${BUILDING_MERGE_Z13:-false}" != true ]; then
  BUILD_ARGS+=(--building-merge-z13=false)
fi
if [ "${REUSE_FEATUREDB:-false}" = true ]; then
  BUILD_ARGS+=(--reuse_featuredb)
fi

java -jar /app/planetiler-openmaptiles.jar \
  --osm_path="$SOURCE" \
  --download_dir="$OUT/sources" \
  --tmpdir="$OUT/tmp" \
  --output="$PART?format=pmtiles" \
  --storage=mmap \
  --nodemap-type=array \
  --sort_max_readers="${SORT_MAX_READERS:-12}" \
  --sort_max_writers="${SORT_MAX_WRITERS:-12}" \
  "${WIKIDATA_ARGS[@]}" \
  "${BUILD_ARGS[@]}" \
  --force

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
