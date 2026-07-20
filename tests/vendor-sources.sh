#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

declare -A EXPECTED=(
  [positron]=5f4d3457396c8dd9879a41d11edfb318877e1ddc
  [dark-matter]=d79ee85228e2701118009088dcdc824c461d8437
  [osm-bright]=0a78b469ecfabdc771e058ffce1bf474926df249
  [openmaptiles-fonts]=a4f9e7cf18aa382945c0a912f3022ba94a0b1d52
  [planetiler]=0e5588c4a6e8c29a270a33afe8df62027d889604
  [planetiler-openmaptiles]=5be22807170439320354b39ed9b390aa796a2cee
  [tileserver-gl]=000c365f3d6948733355be167f09d5585697c4c6
)

for name in "${!EXPECTED[@]}"; do
  dir="$ROOT/base-styles/$name"
  test -d "$dir"
  test -f "$dir/UPSTREAM.md"
  test ! -e "$dir/.git"
  test ! -e "$dir/.github"
  test ! -e "$dir/.gitmodules"
  grep -Fqx "Commit: ${EXPECTED[$name]}" "$dir/UPSTREAM.md"
done

echo "vendored source provenance is valid"
