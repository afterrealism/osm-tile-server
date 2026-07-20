#!/usr/bin/env bash
set -euo pipefail

: "${PGHOST:?}"
: "${PGPORT:=5432}"
: "${PGUSER:?}"
: "${PGPASSWORD:?}"
: "${PGDATABASE:=gis_carto_v6}"
: "${DATABASE_STATE_DIR:=/data/database18-carto-v6-state}"

STYLE=/opt/openstreetmap-carto
PBF=/data/region.osm.pbf
GENERATED=/data/generated/carto-v6

[[ "$PGDATABASE" =~ ^[a-z_][a-z0-9_]*$ ]] || { echo "invalid PGDATABASE" >&2; exit 1; }
mkdir -p "$DATABASE_STATE_DIR" "$GENERATED"
chown -R renderer: "$DATABASE_STATE_DIR" "$GENERATED"

if ! PGPASSWORD="$PGPASSWORD" psql -d postgres -Atc \
  "SELECT 1 FROM pg_database WHERE datname = '$PGDATABASE'" | grep -qx 1; then
  PGPASSWORD="$PGPASSWORD" createdb --maintenance-db=postgres \
    --owner="$PGUSER" --encoding=UTF8 "$PGDATABASE"
fi

psql -v ON_ERROR_STOP=1 -d "$PGDATABASE" -c \
  'CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS hstore;'

if [ ! -f "$DATABASE_STATE_DIR/osm-import-complete" ]; then
  sudo -E -u renderer osm2pgsql --create --slim -O flex \
    -S "$STYLE/openstreetmap-carto-flex.lua" \
    --number-processes "${THREADS:-4}" -d "$PGDATABASE" \
    ${OSM2PGSQL_EXTRA_ARGS:-} "$PBF"
  psql -v ON_ERROR_STOP=1 -d "$PGDATABASE" -f "$STYLE/functions.sql"
  psql -v ON_ERROR_STOP=1 -d "$PGDATABASE" -f "$STYLE/common-values.sql"
  psql -v ON_ERROR_STOP=1 -d "$PGDATABASE" -f "$STYLE/indexes.sql"
  sudo -u renderer touch "$DATABASE_STATE_DIR/osm-import-complete"
fi

sudo -E -u renderer python3 "$STYLE/scripts/get-external-data.py" \
  -c "$STYLE/external-data.yml" -d "$PGDATABASE" -H "$PGHOST" -p "$PGPORT" -U "$PGUSER" \
  -w "$PGPASSWORD" -R "$PGUSER" -D /data/generated/carto-v6/external

(cd "$STYLE" && carto -a '3.0.22' project.mml > "$GENERATED/mapnik.xml.part")
mv "$GENERATED/mapnik.xml.part" "$GENERATED/mapnik.xml"
ln -sfn "$STYLE/symbols" "$GENERATED/symbols"
ln -sfn "$STYLE/patterns" "$GENERATED/patterns"

psql -v ON_ERROR_STOP=1 -d "$PGDATABASE" -Atc \
  "SELECT to_regclass('public.planet_osm_point') IS NOT NULL
       AND to_regclass('public.planet_osm_line') IS NOT NULL
       AND to_regclass('public.planet_osm_polygon') IS NOT NULL
       AND to_regclass('public.planet_osm_roads') IS NOT NULL
       AND to_regclass('public.carto_pois') IS NOT NULL" | grep -qx t

python3 /workspace/scripts/artifact_manifest.py write \
  --kind carto-v6 --source "$PBF" --artifact "$GENERATED/mapnik.xml" \
  --source-ref v6.0.0 \
  --source-commit 7d2926a85acd07c0a4051f3d444ebe2b59c0676e \
  --local-source "$STYLE" --manifest "$DATABASE_STATE_DIR/manifest.json"
sudo -u renderer touch "$DATABASE_STATE_DIR/planet-import-complete"
