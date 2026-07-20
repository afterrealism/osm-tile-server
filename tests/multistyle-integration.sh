#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ENGINE=${CONTAINER_ENGINE:-docker}
TMP=$(mktemp -d)

if [ -n "${PORT:-}" ]; then
  PROJECT=
  COMPOSE=("$ENGINE" compose -f "$ROOT/docker-compose.yml")
else
  PORT=${TEST_PORT:-18080}
  PROJECT=osm-tile-server-multistyle-$$
  COMPOSE=("$ENGINE" compose -p "$PROJECT" -f "$ROOT/tests/docker-compose.yml")
fi

cleanup() {
  if [ -n "$PROJECT" ]; then
    "${COMPOSE[@]}" down --volumes --remove-orphans >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

if [ -n "$PROJECT" ]; then
  "${COMPOSE[@]}" up -d themes
fi

ready=false
for _ in $(seq 1 90); do
  if curl -fsS "http://127.0.0.1:$PORT/health" -o /dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done

if [ "$ready" != true ]; then
  "${COMPOSE[@]}" logs >&2 || true
  exit 1
fi

mapfile -t STYLES < <(node -e "console.log(Object.keys(JSON.parse(require('fs').readFileSync('$ROOT/themes/config.json','utf8')).styles).join('\n'))")

for tile in 0/0/0 10/529/348 18/135536/89345; do
  for style in "${STYLES[@]}"; do
    name=${tile//\//-}-$style
    curl -fsS "http://127.0.0.1:$PORT/styles/$style/$tile.png" \
      -o "$TMP/$name.png"
    test "$(file --brief --mime-type "$TMP/$name.png")" = image/png
  done
done

test "$(sha256sum "$TMP/18-135536-89345-"*.png | cut -d' ' -f1 | sort -u | wc -l)" = "${#STYLES[@]}"

echo "PMTiles-only ${#STYLES[@]}-style stack is valid"
