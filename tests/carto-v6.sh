#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

! grep -Fq 'git clone --single-branch --branch v5.4.0' "$ROOT/Dockerfile"
grep -Fq 'COPY base-styles/openstreetmap-carto' "$ROOT/Dockerfile"
grep -Fq 'PGDATABASE: gis_carto_v6' "$ROOT/docker-compose.yml"
grep -Fq 'DATABASE_STATE_DIR: /data/database18-carto-v6-state' "$ROOT/docker-compose.yml"
grep -Fq -- '-O flex' "$ROOT/scripts/import-carto-v6.sh"
grep -Fq 'functions.sql' "$ROOT/scripts/import-carto-v6.sh"
grep -Fq 'common-values.sql' "$ROOT/scripts/import-carto-v6.sh"
grep -Fq 'mapnik.xml.part' "$ROOT/scripts/import-carto-v6.sh"
grep -Fq -- '--append -O flex' "$ROOT/openstreetmap-tiles-update-expire.sh"
grep -Fq 'openstreetmap-carto-flex.lua' "$ROOT/openstreetmap-tiles-update-expire.sh"
! grep -Fq -- '--tag-transform-script' "$ROOT/openstreetmap-tiles-update-expire.sh"
! grep -Fq 'openstreetmap-carto.style' "$ROOT/openstreetmap-tiles-update-expire.sh"
echo "Carto v6 configuration is valid"
