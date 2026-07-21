#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUT=${1:-"$ROOT/data/planet"}
BASE=https://planet.openstreetmap.org/pbf
mkdir -p "$OUT"
PART="$OUT/.planet.osm.pbf.part"
trap 'rm -f "$PART.md5"' EXIT

fetch() {
  if command -v aria2c >/dev/null 2>&1; then
    aria2c --dir="$OUT" --out="$(basename "$2")" --continue=true \
      --max-connection-per-server=16 --split=16 --min-split-size=64M \
      --max-tries=5 --retry-wait=5 --auto-file-renaming=false \
      --allow-overwrite=true "$1"
  else
    if ! curl -fL -C - --retry 5 --retry-all-errors "$1" -o "$2"; then
      rm -f "$2"
      curl -fL --retry 5 --retry-all-errors "$1" -o "$2"
    fi
  fi
}

fetch "$BASE/planet-latest.osm.pbf" "$PART"
curl -fL --retry 5 --retry-all-errors "$BASE/planet-latest.osm.pbf.md5" -o "$PART.md5"

EXPECTED=$(cut -d' ' -f1 "$PART.md5")
if ! (cd "$OUT" && printf '%s  %s\n' "$EXPECTED" "$(basename "$PART")" | md5sum -c -); then
  echo "checksum failed; deleting partial download so the next run starts fresh" >&2
  rm -f "$PART"
  exit 1
fi
test "$(stat -c%s "$PART")" -gt 50000000000

SHA=$(sha256sum "$PART" | cut -c1-16)
PBF="$OUT/planet-$SHA.osm.pbf"
mv "$PART" "$PBF"
sha256sum "$PBF" > "$OUT/planet-$SHA.sha256"
ln -sfn "planet/$(basename "$PBF")" "$ROOT/data/planet.osm.pbf"
printf '%s\n' "$PBF"
