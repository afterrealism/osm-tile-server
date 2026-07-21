# OpenStreetMap Tile Server

Full-world OpenStreetMap raster tiles rendered from one immutable PMTiles v3 archive in six local styles.

```text
planet-latest.osm.pbf -> Planetiler -> openmaptiles-<sha16>.pmtiles
                                       -> TileServer GL
                                       -> /styles/{atlas,paper,onyx,terra,fjord,meridian}/{z}/{x}/{y}.png
```

The source PBF is a build-time input only. The runtime requires the PMTiles archive and complete style assets.

## Requirements

- Java 21 and the vendored Planetiler OpenMapTiles v3.16 profile.
- Node.js 20 or newer for style generation.
- Docker Compose or Podman Compose.
- Free build disk of at least 10 times the planet PBF size.
- Total system RAM of at least half the planet PBF size.

The low-memory build profile uses mmap storage, an array node map, and a 20 GiB JVM heap. A current full-planet build should have approximately 1 TiB of free disk and at least 48 GiB RAM available before download.

## Build And Run

Run the complete workflow from the repository root:

```bash
make build
make fetch-planet
make check-capacity
make build-pmtiles
make assets
make run
curl --fail http://localhost:8080/health
curl --fail --output tile.png http://localhost:8080/styles/atlas/10/529/348.png
```

Make defaults to Docker. Use `make CONTAINER_ENGINE=podman <target>` when running Podman.

Downloads and generated archives remain under ignored `data/` paths. They are written through temporary `.part` paths, validated, and then published atomically. The final archive is content-versioned as `data/openmaptiles/openmaptiles-<sha16>.pmtiles`; `data/openmaptiles/openmaptiles.pmtiles` is a stable relative symlink.

## Routes

TileServer GL serves raster PNG output on port 8080:

| Route | Style source |
|---|---|
| `/styles/atlas/{z}/{x}/{y}.png` | OSM Bright |
| `/styles/paper/{z}/{x}/{y}.png` | Positron |
| `/styles/onyx/{z}/{x}/{y}.png` | Dark Matter |
| `/styles/terra/{z}/{x}/{y}.png` | Green OSM Bright derivative |
| `/styles/fjord/{z}/{x}/{y}.png` | Fiord Color |
| `/styles/meridian/{z}/{x}/{y}.png` | OSM Liberty |

`/health` reports readiness only after all renderer pools initialize. Every style, sprite, glyph, and tile source is local to the runtime.

## Generated Data

- `data/planet/planet-<sha16>.osm.pbf`: checksummed official source snapshot.
- `data/planet.osm.pbf`: stable relative source symlink used only by the build service.
- `data/openmaptiles/openmaptiles-<sha16>.pmtiles`: immutable world archive.
- `data/openmaptiles/openmaptiles.pmtiles`: stable runtime symlink.
- `data/openmaptiles/manifest.json`: source, artifact, and vendor provenance.
- `data/style-assets/{atlas,paper,onyx,terra,fjord,meridian}/`: styles, normal and retina sprites, and manifests.
- `data/style-assets/fonts/`: local PBF font stacks.

Do not commit generated source, archive, style, sprite, font, manifest, or build-context files.

## Verification

Run fast source and configuration checks:

```bash
make test-config
```

After building the world archive and assets, run the local integration check:

```bash
make CONTAINER_ENGINE=podman test
```

## Attribution

Maps rendered from these tiles must visibly credit `© OpenStreetMap contributors` with a link to the Open Database License (<https://opendatacommons.org/licenses/odbl/>).
