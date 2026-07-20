# OpenStreetMap Tile Server

Docker Compose stack for importing OpenStreetMap `.osm.pbf` data and serving raster XYZ tiles in four styles.

```text
PostgreSQL 18 + PostGIS 3.6
             ↑
osm2pgsql flex / OpenStreetMap Carto v6 / Mapnik / renderd / Apache mod_tile (standard)
Planetiler OpenMapTiles + TileServer GL (light, dark, natural)
             ↓
http://localhost:8080/tile/{standard,light,dark,natural}/{z}/{x}/{y}.png
```

Public output is raster PNG only, served on four named endpoints:

| Route | Style | Renderer |
|---|---|---|
| `/tile/standard/{z}/{x}/{y}.png` | OpenStreetMap Carto v6 | Mapnik/renderd |
| `/tile/light/{z}/{x}/{y}.png` | Positron derivative | TileServer GL |
| `/tile/dark/{z}/{x}/{y}.png` | Dark Matter derivative | TileServer GL |
| `/tile/natural/{z}/{x}/{y}.png` | Green OSM Bright derivative | TileServer GL |

The unnamed `/tile/{z}/{x}/{y}.png` route returns `404`. The server root returns `403`; there is no demo UI.

## Storage

All persistent files remain under `data/` and are ignored by Git:

| Path | Contents |
|---|---|
| `data/postgres18/` | PostgreSQL 18 cluster (`gis` rollback DB and `gis_carto_v6`) |
| `data/database18-state/` | Retained Carto v5 import markers and replication state |
| `data/database18-carto-v6-state/` | Carto v6 import markers, replication state, manifest |
| `data/generated/carto-v6/` | Compiled `mapnik.xml` and external cartographic datasets |
| `data/openmaptiles/` | `openmaptiles.mbtiles` and its manifest |
| `data/style-assets/` | Localized styles, sprites, PBF fontstacks, manifests |
| `data/region.osm.pbf` | Retained OSM source extract |
| `data/region.poly` | Retained extract boundary |
| `data/style/` | Retained Carto v5 style (rollback) |
| `data/tiles/` | Rendered PNG cache (`data/tiles/standard/` for Carto v6) |

An existing PostgreSQL 15 cluster under `data/database/` is not mounted by this stack. Follow [`database/UPGRADE.md`](database/UPGRADE.md) before deleting it.

## Build And Import

Docker:

```sh
docker compose build
docker compose --profile tools build planetiler
docker compose up -d database
docker compose run --rm map import
docker compose --profile tools run --rm planetiler
node scripts/prepare-theme-assets.mjs
node scripts/verify-local-styles.mjs
docker compose up -d map themes
```

Podman: replace `docker` with `podman`.

Theme assets additionally require the sprite/font tooling once per checkout:

```sh
npm ci --prefix themes
node scripts/build-sprites.mjs data/style-assets/light/sprite base-styles/positron/icons
node scripts/build-sprites.mjs --retina data/style-assets/light/sprite@2x base-styles/positron/icons
# repeat for dark (dark-matter) and natural (osm-bright)
```

Without a source file, the import downloads Luxembourg. To select another Geofabrik extract:

```sh
DOWNLOAD_PBF=https://download.geofabrik.de/europe/germany-latest.osm.pbf \
DOWNLOAD_POLY=https://download.geofabrik.de/europe/germany.poly \
docker compose run --rm -e DOWNLOAD_PBF -e DOWNLOAD_POLY map import
```

Downloads and generated archives use temporary `.part` files and replace the retained artifact only after completion. Repeating a completed import is non-destructive. The Planetiler build needs at least 4 GiB of JVM heap (`JAVA_TOOL_OPTIONS`) plus several times the PBF size in free disk; larger regions require increasing both.

## Serve Tiles

```sh
curl --fail --output tile.png \
  http://localhost:8080/tile/standard/18/135536/89345.png
```

Standard keeps serving when the `themes` service is unavailable; the three themed routes then return `503`.

## Configuration

Compose supplies these database variables to the map container:

| Variable | Default |
|---|---|
| `PGHOST` | `database` |
| `PGPORT` | `5432` |
| `PGDATABASE` | `gis_carto_v6` |
| `PGUSER` | `renderer` |
| `PGPASSWORD` | `${POSTGRES_PASSWORD:-renderer}` |
| `DATABASE_STATE_DIR` | `/data/database18-carto-v6-state` |

Set `POSTGRES_PASSWORD` in the shell or a local `.env` file before starting Compose to replace the development default.

Other supported map variables include `THREADS`, `ALLOW_CORS`, `UPDATES`, `FLAT_NODES`, `OSM2PGSQL_EXTRA_ARGS`, `REPLICATION_URL`, `MAX_INTERVAL_SECONDS`, and the `EXPIRY_*` settings.

When automatic updates are enabled, provide both `region.osm.pbf` and `region.poly` from the same extract.

## Operations

Inspect the database version:

```sh
docker compose exec database psql -U renderer -d gis_carto_v6 -Atc \
  "SELECT current_setting('server_version_num'), postgis_full_version();"
```

Stop the stack without deleting data:

```sh
docker compose down
```

Run fast configuration checks:

```sh
make test-config
```

Run the disposable full multi-style integration test:

```sh
make test
```

The integration test imports the sample into a temporary container volume and removes that volume afterward.

## Attribution

Maps rendered from these tiles must visibly credit `© OpenStreetMap contributors` with a link to the Open Database License (<https://opendatacommons.org/licenses/odbl/>).

## Project Origin

This project was originally forked from [Overv/openstreetmap-tile-server](https://github.com/Overv/openstreetmap-tile-server) and is now maintained as a standalone repository with independent history.
