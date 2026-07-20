#!/bin/bash

set -euo pipefail

DATABASE_STATE_DIR=${DATABASE_STATE_DIR:-/data/database18-carto-v6-state}
export DATABASE_STATE_DIR

function waitForDatabase() {
    local version

    for _ in $(seq 1 60); do
        if PGCONNECT_TIMEOUT=2 psql -d postgres -v ON_ERROR_STOP=1 -Atc 'SELECT 1' >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done

    if ! PGCONNECT_TIMEOUT=2 psql -d postgres -v ON_ERROR_STOP=1 -Atc 'SELECT 1' >/dev/null 2>&1; then
        echo "ERROR: PostgreSQL is not available at ${PGHOST}:${PGPORT}." >&2
        exit 1
    fi

    version=$(psql -d postgres -v ON_ERROR_STOP=1 -Atc 'SHOW server_version_num')
    if ! [[ "$version" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Could not read PostgreSQL server_version_num." >&2
        exit 1
    fi
    if [ "$version" -lt 180000 ] || [ "$version" -ge 190000 ]; then
        echo "ERROR: PostgreSQL 18 is required; server_version_num is $version." >&2
        exit 1
    fi

    if psql -d postgres -v ON_ERROR_STOP=1 -Atc \
       "SELECT 1 FROM pg_database WHERE datname = '$PGDATABASE'" | grep -qx 1 \
       && [ -z "$(psql -d "$PGDATABASE" -v ON_ERROR_STOP=1 -Atc "SELECT extversion FROM pg_extension WHERE extname = 'postgis'")" ]; then
        echo "ERROR: The PostGIS extension is not installed in ${PGDATABASE}." >&2
        exit 1
    fi
}

function coreImportExists() {
    [ "$(psql -v ON_ERROR_STOP=1 -Atc "SELECT to_regclass('public.planet_osm_point') IS NOT NULL AND to_regclass('public.planet_osm_line') IS NOT NULL AND to_regclass('public.planet_osm_polygon') IS NOT NULL AND to_regclass('public.planet_osm_roads') IS NOT NULL")" == "t" ]
}

function writeCronEnvironment() {
    local name
    install -o renderer -g renderer -m 0600 /dev/null /etc/osm-tile-server.env

    for name in THREADS OSM2PGSQL_EXTRA_ARGS REPLICATION_URL MAX_INTERVAL_SECONDS EXPIRY_MINZOOM EXPIRY_TOUCHFROM EXPIRY_DELETEFROM EXPIRY_MAXZOOM PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD DATABASE_STATE_DIR; do
        if [[ -v $name ]]; then
            printf 'export %s=%q\n' "$name" "${!name}" >> /etc/osm-tile-server.env
        fi
    done
}

if [ "$#" -ne 1 ]; then
    echo "usage: <import|run>"
    echo "commands:"
    echo "    import: Set up the database and import /data/region.osm.pbf"
    echo "    run: Runs Apache and renderd to serve tiles at /tile/{z}/{x}/{y}.png"
    exit 1
fi

: "${PGHOST:?PGHOST is required}"
: "${PGPORT:=5432}"
: "${PGDATABASE:=gis_carto_v6}"
: "${PGUSER:=renderer}"
: "${PGPASSWORD:?PGPASSWORD is required}"
export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD

set -x

mkdir -p "$DATABASE_STATE_DIR" /data/style /data/tiles
mkdir -p /data/tiles/standard
chown renderer: "$DATABASE_STATE_DIR" /data/tiles /data/tiles/standard

if [ "$1" == "import" ]; then
    waitForDatabase

    if [ -f "$DATABASE_STATE_DIR/planet-import-complete" ]; then
        if coreImportExists; then
            echo "INFO: PostgreSQL 18 import already completed; keeping the persisted database and source files."
            exit 0
        fi
        echo "ERROR: Import state does not match PostgreSQL 18; restore data/postgres18 or remove data/database18-state and re-import." >&2
        exit 1
    fi

    if [ -f "$DATABASE_STATE_DIR/osm-import-complete" ]; then
        if ! coreImportExists; then
            echo "ERROR: Import state does not match PostgreSQL 18; restore data/postgres18 or remove data/database18-state and re-import." >&2
            exit 1
        fi
    elif coreImportExists; then
        echo "ERROR: PostgreSQL 18 contains OSM tables but its import state is missing; restore data/database18-state before continuing." >&2
        exit 1
    fi

    # Download Luxembourg as a sample if no data is provided.
    if [ ! -f /data/region.osm.pbf ] && [ -z "${DOWNLOAD_PBF:-}" ]; then
        echo "WARNING: No import file at /data/region.osm.pbf, so importing Luxembourg as example..."
        DOWNLOAD_PBF="https://download.geofabrik.de/europe/luxembourg-latest.osm.pbf"
        DOWNLOAD_POLY="https://download.geofabrik.de/europe/luxembourg.poly"
    fi

    if [ -n "${DOWNLOAD_PBF:-}" ]; then
        echo "INFO: Download PBF file: $DOWNLOAD_PBF"
        wget ${WGET_ARGS:-} "$DOWNLOAD_PBF" -O /data/region.osm.pbf.part
        mv /data/region.osm.pbf.part /data/region.osm.pbf
        if [ -n "${DOWNLOAD_POLY:-}" ]; then
            echo "INFO: Download PBF-POLY file: $DOWNLOAD_POLY"
            wget ${WGET_ARGS:-} "$DOWNLOAD_POLY" -O /data/region.poly.part
            mv /data/region.poly.part /data/region.poly
        fi
    fi

    if [ ! -f "$DATABASE_STATE_DIR/osm-import-complete" ]; then
        if [ "${UPDATES:-}" == "enabled" ] || [ "${UPDATES:-}" == "1" ]; then
            REPLICATION_TIMESTAMP=$(osmium fileinfo -g header.option.osmosis_replication_timestamp /data/region.osm.pbf)
            sudo -E -u renderer openstreetmap-tiles-update-expire.sh "$REPLICATION_TIMESTAMP"
        fi

        if [ -f /data/region.poly ]; then
            cp /data/region.poly "$DATABASE_STATE_DIR/region.poly"
            chown renderer: "$DATABASE_STATE_DIR/region.poly"
        fi

        if [ "${FLAT_NODES:-}" == "enabled" ] || [ "${FLAT_NODES:-}" == "1" ]; then
            OSM2PGSQL_EXTRA_ARGS="${OSM2PGSQL_EXTRA_ARGS:-} --flat-nodes $DATABASE_STATE_DIR/flat_nodes.bin"
            export OSM2PGSQL_EXTRA_ARGS
        fi
    else
        echo "INFO: Core OSM import already completed; resuming external data setup."
    fi

    import-carto-v6
    exit 0
fi

if [ "$1" == "run" ]; then
    rm -rf /tmp/*
    waitForDatabase

    if [ ! -f "$DATABASE_STATE_DIR/planet-import-complete" ] || ! coreImportExists; then
        echo "ERROR: PostgreSQL 18 has not been imported; run the import command first." >&2
        exit 1
    fi

    if [ ! -f /data/tiles/planet-import-complete ]; then
        cp "$DATABASE_STATE_DIR/planet-import-complete" /data/tiles/planet-import-complete
    fi

    python3 /workspace/scripts/artifact_manifest.py verify \
      --source /data/region.osm.pbf \
      --artifact /data/generated/carto-v6/mapnik.xml \
      --local-source /opt/openstreetmap-carto \
      --manifest /data/database18-carto-v6-state/manifest.json

    if [ "${ALLOW_CORS:-}" == "enabled" ] || [ "${ALLOW_CORS:-}" == "1" ]; then
        echo "export APACHE_ARGUMENTS='-D ALLOW_CORS'" >> /etc/apache2/envvars
    fi

    service apache2 restart
    sed -i -E "s/num_threads=[0-9]+/num_threads=${THREADS:-4}/g" /etc/renderd.conf

    if [ "${UPDATES:-}" == "enabled" ] || [ "${UPDATES:-}" == "1" ]; then
        writeCronEnvironment
        /etc/init.d/cron start
        sudo -u renderer touch /var/log/tiles/run.log; tail -f /var/log/tiles/run.log >> /proc/1/fd/1 &
        sudo -u renderer touch /var/log/tiles/osmosis.log; tail -f /var/log/tiles/osmosis.log >> /proc/1/fd/1 &
        sudo -u renderer touch /var/log/tiles/expiry.log; tail -f /var/log/tiles/expiry.log >> /proc/1/fd/1 &
        sudo -u renderer touch /var/log/tiles/osm2pgsql.log; tail -f /var/log/tiles/osm2pgsql.log >> /proc/1/fd/1 &
    fi

    stop_handler() {
        kill -TERM "$child"
    }
    trap stop_handler SIGTERM

    sudo -E -u renderer renderd -f -c /etc/renderd.conf &
    child=$!
    wait "$child"
    exit 0
fi

echo "invalid command"
exit 1
