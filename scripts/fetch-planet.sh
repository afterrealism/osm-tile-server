#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUT=${1:-"$ROOT/data/planet"}
BASE=https://planet.openstreetmap.org/pbf
mkdir -p "$OUT"
TMP=$(mktemp -d "$OUT/.planet-download.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

curl -fL --retry 5 --retry-all-errors "$BASE/planet-latest.osm.pbf" \
  -o "$TMP/planet.osm.pbf.part"
curl -fL --retry 5 --retry-all-errors "$BASE/planet-latest.osm.pbf.md5" \
  -o "$TMP/planet-latest.osm.pbf.md5"

EXPECTED=$(cut -d' ' -f1 "$TMP/planet-latest.osm.pbf.md5")
(cd "$TMP" && printf '%s  planet.osm.pbf.part\n' "$EXPECTED" | md5sum -c -)
test "$(stat -c%s "$TMP/planet.osm.pbf.part")" -gt 50000000000

SHA=$(sha256sum "$TMP/planet.osm.pbf.part" | cut -c1-16)
PBF="$OUT/planet-$SHA.osm.pbf"
mv "$TMP/planet.osm.pbf.part" "$PBF"
sha256sum "$PBF" > "$OUT/planet-$SHA.sha256"
ln -sfn "planet/$(basename "$PBF")" "$ROOT/data/planet.osm.pbf"
printf '%s\n' "$PBF"
