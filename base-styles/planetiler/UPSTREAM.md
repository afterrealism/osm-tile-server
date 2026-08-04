# Upstream Provenance

URL: https://github.com/onthegomap/planetiler
Tag: v0.10.2
Commit: 0e5588c4a6e8c29a270a33afe8df62027d889604
Vendored: 2026-07-19
Local modifications: None at initial vendoring.
2026-07-19: removed .gitmodules (upstream submodule metadata; the profile is
vendored as the sibling base-styles/planetiler-openmaptiles tree).
2026-08-04: removed planet-logs/ (16 MB of upstream benchmark logs, unused by
the build). layerstats/ is kept: top_osm_tiles.tsv.gz is the pinned offline
source of data/openmaptiles/tile_weights.tsv.gz.
Upstream pushes: Prohibited; changes are maintained only in this repository.
