#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

grep -Fxq 'FROM postgis/postgis:18-3.6' "$ROOT/database/Dockerfile"
grep -Fq 'database:' "$ROOT/docker-compose.yml"
grep -Fq 'PGHOST: database' "$ROOT/docker-compose.yml"
grep -Fq './data/postgres18:/var/lib/postgresql' "$ROOT/docker-compose.yml"
! grep -Fq './data/database:' "$ROOT/docker-compose.yml"
grep -Fq 'DATABASE_STATE_DIR: /data/database18-carto-v6-state' "$ROOT/docker-compose.yml"
grep -Fq 'server_version_num' "$ROOT/run.sh"
grep -Fq 'function coreImportExists()' "$ROOT/run.sh"
! grep -Fq 'function fullImportExists()' "$ROOT/run.sh"
grep -Fq '[[ "$version" =~ ^[0-9]+$ ]]' "$ROOT/run.sh"
grep -Fq 'Import state does not match PostgreSQL 18' "$ROOT/run.sh"
grep -Fq 'DATABASE_STATE_DIR=${DATABASE_STATE_DIR:-/data/database18-carto-v6-state}' "$ROOT/run.sh"
grep -Fq 'postgresql-client-$PG_VERSION' "$ROOT/Dockerfile"
! grep -Fq 'service postgresql' "$ROOT/run.sh"
! grep -Fq 'postgresql-$PG_VERSION-postgis' "$ROOT/Dockerfile"
grep -Fq 'DATABASE_STATE_DIR=${DATABASE_STATE_DIR:-/data/database18-carto-v6-state}' "$ROOT/openstreetmap-tiles-update-expire.sh"
test -f "$ROOT/database/UPGRADE.md"

echo "PostgreSQL 18 service configuration is valid"
