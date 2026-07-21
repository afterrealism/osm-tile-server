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

declare -a sprite_jobs=()
while IFS=$'\t' read -r name sprite_type sprite_arg manifest_source upstream_dir local_source; do
  if [ "$sprite_type" = build ]; then
    sprite_jobs+=("$name" "$sprite_arg")
  else
    for ratio in '' '@2x'; do
      for ext in json png; do
        cp "$sprite_arg$ratio.$ext" "$OUT/$name/sprite$ratio.$ext.part"
        mv "$OUT/$name/sprite$ratio.$ext.part" "$OUT/$name/sprite$ratio.$ext"
      done
    done
  fi
  if [ "$upstream_dir" != "-" ]; then
    source_ref=local-vendored
    source_commit=$(grep '^Commit: ' "$ROOT/base-styles/$upstream_dir/UPSTREAM.md" | cut -d' ' -f2)
  else
    source_ref=maptiler-v4-local
    source_commit=none
  fi
  python3 "$ROOT/scripts/artifact_manifest.py" write \
    --kind "theme-$name" \
    --source "$manifest_source" \
    --artifact "$OUT/$name/style.json" \
    --source-ref "$source_ref" \
    --source-commit "$source_commit" \
    --local-source "$local_source" \
    --manifest "$OUT/$name/manifest.json"
done < <(STYLE_ASSET_ROOT="$OUT" node "$ROOT/scripts/prepare-theme-assets.mjs" --plan)

if [ "${#sprite_jobs[@]}" -gt 0 ]; then
  printf '%s\n' "${sprite_jobs[@]}" | xargs -n2 -P"$(nproc)" bash -c '
    node "'"$ROOT"'/scripts/build-sprites.mjs" "'"$OUT"'/$0/sprite" "$1" &&
    node "'"$ROOT"'/scripts/build-sprites.mjs" --retina "'"$OUT"'/$0/sprite@2x" "$1"
  '
fi

STYLE_ASSET_ROOT="$OUT" node "$ROOT/scripts/verify-local-styles.mjs"
node "$ROOT/scripts/validate-style-schema.mjs"
