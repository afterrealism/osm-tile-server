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
  "${COMPOSE[@]}" start themes >/dev/null 2>&1 || true
  if [ -n "$PROJECT" ]; then
    "${COMPOSE[@]}" down --volumes --remove-orphans >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

if [ -n "$PROJECT" ]; then
  "${COMPOSE[@]}" up -d database
  "${COMPOSE[@]}" run --rm map import
  "${COMPOSE[@]}" up -d map themes
fi

ready=false
for _ in $(seq 1 90); do
  if curl -fsS "http://127.0.0.1:$PORT/tile/standard/0/0/0.png" -o /dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done

if [ "$ready" != true ]; then
  "${COMPOSE[@]}" logs >&2 || true
  exit 1
fi

for tile in 0/0/0 10/529/348 18/135536/89345; do
  for style in standard light dark natural; do
    name=${tile//\//-}-$style
    curl -fsS "http://127.0.0.1:$PORT/tile/$style/$tile.png" \
      -o "$TMP/$name.png"
    test "$(file --brief --mime-type "$TMP/$name.png")" = image/png
  done
done

test "$(curl -sS -o /dev/null -w '%{http_code}' \
  "http://127.0.0.1:$PORT/")" = 403
test "$(curl -sS -o /dev/null -w '%{http_code}' \
  "http://127.0.0.1:$PORT/tile/18/135536/89345.png")" = 404

test "$(sha256sum "$TMP/18-135536-89345-"*.png | cut -d' ' -f1 | sort -u | wc -l)" = 4

"${COMPOSE[@]}" stop themes
curl -fsS "http://127.0.0.1:$PORT/tile/standard/18/135536/89345.png" -o /dev/null
test "$(curl -sS -o /dev/null -w '%{http_code}' \
  "http://127.0.0.1:$PORT/tile/light/18/135536/89345.png")" = 503

echo "multi-style raster stack and degradation behavior are valid"
