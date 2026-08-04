# Upstream Provenance

URL: https://github.com/maputnik/osm-liberty (mirror: https://github.com/openmaptiles/osm-liberty-gl-style)
Tag: none (pinned to commit)
Commit: cca1adefc6723ed2c6ce334fb8912920841daa48
Vendored: 2026-07-21
Local modifications: None at initial vendoring.
License: BSD-3-Clause (code, derived from Mapbox OSM Bright) + CC-BY 3.0/4.0 (design);
Maki icons CC0; Roboto fonts Apache-2.0.
Note: upstream style.json references a remote Natural Earth hillshade raster source
(natural_earth_shaded_relief) and its "natural_earth" layer; both are dropped by the
asset pipeline because the runtime serves only the local OpenMapTiles PMTiles archive.
2026-08-04: style.json: replaced upstream's hardcoded public MapTiler demo API
key with the {key} placeholder used by the other vendored styles (the source
URL is replaced wholesale by the asset pipeline anyway).
Upstream pushes: Prohibited; changes are maintained only in this repository.
