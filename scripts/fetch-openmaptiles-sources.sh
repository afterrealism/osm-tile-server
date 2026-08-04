#!/usr/bin/env bash
# Seed and verify the non-OSM inputs of the openmaptiles build against
# scripts/openmaptiles-sources.sha256. Re-fetching is deliberate: delete a
# file, run this script, then run `$0 --pin` to record the new hashes.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUT="$ROOT/data/openmaptiles"
LOCK="$ROOT/scripts/openmaptiles-sources.sha256"
mkdir -p "$OUT/sources"

# The exact mirrors that produced the pinned bytes. Upstream primaries are
# moving targets and need a --pin after switching:
#   https://github.com/acalcutt/osm-lakelines/releases/download/latest/lake_centerline.shp.zip
#   https://naciscdn.org/naturalearth/packages/natural_earth_vector.sqlite.zip
declare -A URLS=(
  [sources/lake_centerline.shp.zip]=https://dev.maptiler.download/geodata/omt/lake_centerline.shp.zip
  [sources/natural_earth_vector.sqlite.zip]=https://dev.maptiler.download/geodata/omt/natural_earth_vector.sqlite.zip
  [sources/water-polygons-split-3857.zip]=https://osmdata.openstreetmap.de/download/water-polygons-split-3857.zip
)

if [ "${1:-}" = --pin ]; then
  tmp=$(mktemp)
  (
    cd "$OUT"
    for f in "${!URLS[@]}" tile_weights.tsv.gz sources/wikidata_names.json; do
      if [ -s "$f" ]; then sha256sum "$f"; fi
    done | sort -k2
  ) > "$tmp"
  mv "$tmp" "$LOCK"
  cat "$LOCK"
  exit 0
fi

# tile_weights is pinned in-tree: byte-identical to planetiler's layerstats copy.
if [ ! -s "$OUT/tile_weights.tsv.gz" ]; then
  cp "$ROOT/base-styles/planetiler/layerstats/top_osm_tiles.tsv.gz" "$OUT/tile_weights.tsv.gz"
fi

for f in "${!URLS[@]}"; do
  if [ ! -s "$OUT/$f" ]; then
    curl -fL --retry 5 --retry-all-errors "${URLS[$f]}" -o "$OUT/$f.part"
    mv "$OUT/$f.part" "$OUT/$f"
  fi
done

# wikidata_names.json is derived from the planet by planetiler --fetch-wikidata,
# never downloaded here; verify it only when present.
(cd "$OUT" && grep -v wikidata_names "$LOCK" | sha256sum --strict -c -)
if [ -s "$OUT/sources/wikidata_names.json" ]; then
  (cd "$OUT" && grep wikidata_names "$LOCK" | sha256sum --strict -c -)
fi
echo "openmaptiles sources verified"
