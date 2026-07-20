#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUT="$ROOT/data/style-assets"
FONT_SOURCE="$ROOT/base-styles/openmaptiles-fonts"
mkdir -p "$OUT"

if [ ! -s "$OUT/fonts/Open Sans Regular/0-255.pbf" ]; then
  npm install --prefix "$FONT_SOURCE" --no-package-lock
  (cd "$FONT_SOURCE" && node generate.js)
  rm -rf "$OUT/fonts.part"
  cp -a "$FONT_SOURCE/_output" "$OUT/fonts.part"
  rm -rf "$OUT/fonts"
  mv "$OUT/fonts.part" "$OUT/fonts"
fi

STYLE_ASSET_ROOT="$OUT" node "$ROOT/scripts/prepare-theme-assets.mjs"

for pair in standard:osm-bright light:positron dark:dark-matter natural:osm-bright; do
  name=${pair%%:*}
  upstream=${pair##*:}
  node "$ROOT/scripts/build-sprites.mjs" \
    "$OUT/$name/sprite" "$ROOT/base-styles/$upstream/icons"
  node "$ROOT/scripts/build-sprites.mjs" --retina \
    "$OUT/$name/sprite@2x" "$ROOT/base-styles/$upstream/icons"
  python3 "$ROOT/scripts/artifact_manifest.py" write \
    --kind "theme-$name" \
    --source "$ROOT/base-styles/$upstream/style.json" \
    --artifact "$OUT/$name/style.json" \
    --source-ref local-vendored \
    --source-commit "$(grep '^Commit: ' "$ROOT/base-styles/$upstream/UPSTREAM.md" | cut -d' ' -f2)" \
    --local-source "$ROOT/base-styles/$upstream" \
    --manifest "$OUT/$name/manifest.json"
done

STYLE_ASSET_ROOT="$OUT" node "$ROOT/scripts/verify-local-styles.mjs"
