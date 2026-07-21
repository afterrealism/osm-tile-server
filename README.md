# OpenStreetMap Tile Server

Full-world OpenStreetMap raster tiles rendered from one immutable PMTiles v3 archive in fifteen local styles.

```text
planet-latest.osm.pbf -> Planetiler -> openmaptiles-<sha16>.pmtiles
                                      -> TileServer GL
                                      -> /styles/{atlas,paper,onyx,terra,nova,graphite,fjord,meridian,community,canvas,mist,prism,avenue,watercolor,ink}/{z}/{x}/{y}.png
```

The source PBF is a build-time input only. Local and cloud runtimes require the PMTiles archive and complete style assets.

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
| `/styles/nova/{z}/{x}/{y}.png` | MapTiler Basic (open) |
| `/styles/graphite/{z}/{x}/{y}.png` | MapTiler Toner (open) |
| `/styles/fjord/{z}/{x}/{y}.png` | Fiord Color (open) |
| `/styles/meridian/{z}/{x}/{y}.png` | OSM Liberty (open) |
| `/styles/community/{z}/{x}/{y}.png` | MapTiler OpenStreetMap (proprietary, local use only) |
| `/styles/canvas/{z}/{x}/{y}.png` | MapTiler Base v4 re-authored to OpenMapTiles schema (local use only) |
| `/styles/mist/{z}/{x}/{y}.png` | MapTiler Backdrop v4 re-authored (local use only) |
| `/styles/prism/{z}/{x}/{y}.png` | MapTiler Dataviz v4 re-authored (local use only) |
| `/styles/avenue/{z}/{x}/{y}.png` | MapTiler Streets v4 re-authored (local use only) |
| `/styles/watercolor/{z}/{x}/{y}.png` | MapTiler Aquarelle v4 re-authored (local use only) |
| `/styles/ink/{z}/{x}/{y}.png` | MapTiler Toner v2, OpenMapTiles v3 schema (local use only) |

`/health` reports readiness only after all renderer pools initialize. Every style, sprite, glyph, and tile source is local to the runtime.

## Generated Data

- `data/planet/planet-<sha16>.osm.pbf`: checksummed official source snapshot.
- `data/planet.osm.pbf`: stable relative source symlink used only by the build service.
- `data/openmaptiles/openmaptiles-<sha16>.pmtiles`: immutable world archive.
- `data/openmaptiles/openmaptiles.pmtiles`: stable runtime symlink.
- `data/openmaptiles/manifest.json`: source, artifact, and vendor provenance.
- `data/style-assets/{atlas,paper,onyx,terra,nova,graphite,fjord,meridian,community,canvas,mist,prism,avenue,watercolor,ink}/`: styles, normal and retina sprites, and manifests.
- `data/style-assets/fonts/`: local PBF font stacks.
- `data/v4-sources/`: fetched proprietary MapTiler v4 source styles (local use only) re-authored by `scripts/convert-maptiler-v4.mjs`; refetch with `MAPTILER_KEY=... scripts/fetch-v4-styles.sh`.

Do not commit generated source, archive, style, sprite, font, manifest, or build-context files.

## Cloud Run

The existing deployment uses project `scheece-dev-20260701`, region `asia-southeast1`, service `tileserver`, and domain <https://tiles.geocanvas.dev>. The runtime image embeds style assets and validators. A private `tiles-geocanvas-dev` bucket supplies one immutable PMTiles object through a read-only Cloud Storage volume.

Cloud Run uses an HTTP `/health` startup probe so requests are admitted only after renderer initialization. Build, upload, deployment, acceptance, update, and rollback procedures are documented in [`gcp/README.md`](gcp/README.md).

## Verification

Run fast source and configuration checks:

```bash
make test-config
```

After building the world archive and assets, run the local integration and staged cloud-image checks:

```bash
make CONTAINER_ENGINE=podman test
CONTAINER_ENGINE=podman ./tests/gcp-image.sh
```

## Attribution

Maps rendered from these tiles must visibly credit `© OpenStreetMap contributors` with a link to the Open Database License (<https://opendatacommons.org/licenses/odbl/>).
