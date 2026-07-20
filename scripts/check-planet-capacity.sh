#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PBF=${1:-"$ROOT/data/planet.osm.pbf"}
OUT=${2:-"$ROOT/data/openmaptiles"}
test -s "$PBF"
mkdir -p "$OUT"

pbf_size=$(stat -Lc%s "$PBF")
required_disk=$((pbf_size * 10))
required_ram=$(((pbf_size + 1) / 2))
available_disk=$(df --output=avail -B1 "$OUT" | tail -n 1 | tr -d ' ')
total_ram=$(($(awk '/MemTotal:/ {print $2}' /proc/meminfo) * 1024))

printf 'PBF bytes: %s\nRequired free disk: %s\nAvailable free disk: %s\nRequired RAM: %s\nTotal RAM: %s\n' \
  "$pbf_size" "$required_disk" "$available_disk" "$required_ram" "$total_ram"
test "$available_disk" -ge "$required_disk"
test "$total_ram" -ge "$required_ram"
