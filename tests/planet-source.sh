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
echo "planet source and capacity gates are present"
