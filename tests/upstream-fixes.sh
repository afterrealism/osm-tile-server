#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

bash -n "$ROOT/run.sh"
sh -n "$ROOT/openstreetmap-tiles-update-expire.sh"

grep -Fq 'mkdir -p "$DATABASE_STATE_DIR" /data/style /data/tiles' "$ROOT/run.sh"
grep -Fq 'if [ -f "$DATABASE_STATE_DIR/planet-import-complete" ]; then' "$ROOT/run.sh"
grep -Fq 'if [ ! -f "$DATABASE_STATE_DIR/osm-import-complete" ]; then' "$ROOT/run.sh"
grep -Fq 'touch "$DATABASE_STATE_DIR/osm-import-complete"' "$ROOT/scripts/import-carto-v6.sh"
grep -Fq 'wget ${WGET_ARGS:-} "$DOWNLOAD_PBF" -O /data/region.osm.pbf.part' "$ROOT/run.sh"
grep -Fq 'mv /data/region.osm.pbf.part /data/region.osm.pbf' "$ROOT/run.sh"
grep -Fq '. /etc/osm-tile-server.env && openstreetmap-tiles-update-expire.sh' "$ROOT/Dockerfile"
grep -Fxq 'jit = off' "$ROOT/database/postgresql.conf"
test ! -e "$ROOT/leaflet-demo.html"
test ! -e "$ROOT/.travis.yml"
test ! -e "$ROOT/.github/workflows/build-and-test.yaml"
! grep -Eqi 'leaflet|favicon' "$ROOT/Dockerfile"
! grep -Eqi 'leaflet|demo map|travis-ci' "$ROOT/README.md"
grep -Fq 'Options -Indexes' "$ROOT/apache.conf"

echo "upstream fixes are present and scripts parse successfully"
