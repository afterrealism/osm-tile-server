# Upstream Provenance

URL: https://github.com/maptiler/tileserver-gl
Tag: v5.6.0
Commit: 000c365f3d6948733355be167f09d5585697c4c6
Vendored: 2026-07-19
Local modifications: None at initial vendoring.
2026-07-19: Dockerfile: added python3 to the final stage (manifest verification at
startup); pinned builder-stage npm to v10 (`--build-from-source` was removed in
npm 11 and install-scripts are gated there).
Upstream pushes: Prohibited; changes are maintained only in this repository.
2026-07-20: src/serve_rendered.js: opt-in Cache-Control response header on
rendered tiles when TILE_CACHE_CONTROL is set.
2026-07-21: src/utils.js: reject retina scale suffixes without constructing an
invalid regular expression when maxScaleFactor is 1; test/utils.js covers it.
2026-08-04: src/serve_rendered.js: static-mode renderer pools are only created
when static maps are enabled (or tileMargin > 0); renderer pools use a bounded
TimedQueue (15 s wait, 200 deep) so overload fails fast as 503 instead of
queueing unbounded.
2026-08-04: src/pmtiles_adapter.js: PMTiles directory-cache size configurable
via PMTILES_MAX_CACHE_ENTRIES (default 512; upstream pmtiles default is 100).
2026-08-04: src/main.js: uncaughtException exits the process so the container
restart policy recovers a clean instance; unhandledRejection stays log-only.
2026-08-04: Dockerfile: ubuntu:noble pinned by digest in both stages.
