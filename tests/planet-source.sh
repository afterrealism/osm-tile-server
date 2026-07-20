#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

grep -Fq 'BASE=https://planet.openstreetmap.org/pbf' "$ROOT/scripts/fetch-planet.sh"
grep -Fq 'planet-latest.osm.pbf"' "$ROOT/scripts/fetch-planet.sh"
grep -Fq 'planet-latest.osm.pbf.md5' "$ROOT/scripts/fetch-planet.sh"
grep -Fq 'md5sum -c' "$ROOT/scripts/fetch-planet.sh"
grep -Fq 'planet.osm.pbf.part' "$ROOT/scripts/fetch-planet.sh"
grep -Fq 'ln -sfn' "$ROOT/scripts/fetch-planet.sh"
grep -Fq 'required_disk=$((pbf_size * 10))' "$ROOT/scripts/check-planet-capacity.sh"
grep -Fq 'required_ram=$(((pbf_size + 1) / 2))' "$ROOT/scripts/check-planet-capacity.sh"
BUILDER="$ROOT/scripts/build-openmaptiles.sh"
grep -Fq 'PART=$OUT/openmaptiles.pmtiles.part' "$BUILDER"
grep -Fq '.build.lock' "$BUILDER"
grep -Fq 'flock -n 9' "$BUILDER"
grep -Fq 'another openmaptiles build is already running' "$BUILDER"
grep -Fq -- '--output="$PART?format=pmtiles"' "$BUILDER"
grep -Fq 'validate-openmaptiles-pmtiles.py --require-world' "$BUILDER"
grep -Fq -- '--storage=mmap' "$BUILDER"
grep -Fq -- '--nodemap-type=array' "$BUILDER"
! grep -Fq '.mbtiles' "$BUILDER"
echo "planet source and capacity gates are present"
