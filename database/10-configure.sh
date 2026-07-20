#!/usr/bin/env bash

set -euo pipefail

cat /opt/osm-tile-server/postgresql.conf >> "$PGDATA/postgresql.conf"
