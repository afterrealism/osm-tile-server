# PostgreSQL 15 to 18 Upgrade

The PostgreSQL 18 service uses `data/postgres18/`. The existing PostgreSQL 15 cluster under `data/database/` is never mounted or modified by the new service.

The supported migration is a clean re-import from the retained `data/region.osm.pbf`. This avoids carrying PostgreSQL and PostGIS catalog state across three major versions.

> **Status:** the PG15 → PG18 migration below is complete. The newer `gis` → `gis_carto_v6` migration is a *style-schema* migration (OpenStreetMap Carto v5 to v6, osm2pgsql flex) inside the same PostgreSQL 18 cluster, not another database-platform upgrade. Its rollback path uses the `afterrealism/osm-tile-server:pre-carto-v6` image and the retained `gis` database and `data/database18-state/` state described here.

## 1. Preserve rollback artifacts

Before building the new map image, tag the working PostgreSQL 15 image:

```sh
podman tag afterrealism/osm-tile-server:local afterrealism/osm-tile-server:pg15-backup
```

Do not delete any of these paths:

```text
data/database/
data/region.osm.pbf
data/region.poly
data/style/
data/tiles/
```

## 2. Build and start PostgreSQL 18

```sh
podman compose build database map
podman compose up -d database
podman compose exec database psql -U renderer -d gis -Atc \
  "SELECT current_setting('server_version_num'), postgis_full_version();"
```

The server version must begin with `18` and PostGIS must report version 3.6.

## 3. Re-import the retained OSM source

The PG18 import uses `data/database18-state/`, so PostgreSQL 15 completion markers cannot skip it.

```sh
podman compose run --rm map import
```

Verify the imported tables before cutover:

```sh
podman compose exec database psql -U renderer -d gis -Atc \
  "SELECT count(*) FROM planet_osm_point;
   SELECT count(*) FROM planet_osm_line;
   SELECT count(*) FROM planet_osm_polygon;
   SELECT count(*) FROM planet_osm_roads;"
```

## 4. Cut over the tile server

```sh
podman compose up -d map
curl --fail --output /tmp/osm-tile.png \
  http://localhost:8080/tile/18/135536/89345.png
file /tmp/osm-tile.png
```

The file must be a 256 by 256 PNG. Leave `data/database/` in place until the PG18 service has been verified with the required region and zoom levels.

## Rollback

Stop the PG18 stack without deleting either database directory:

```sh
podman compose down
```

Run the tagged PostgreSQL 15 image against the original data:

```sh
podman run --rm --name osm-tile-server-pg15 \
  --shm-size=128m \
  -v "$PWD/data:/data" \
  -p 8080:80 \
  afterrealism/osm-tile-server:pg15-backup run
```

After rollback, investigate the PG18 files under `data/postgres18/` and state under `data/database18-state/`. Do not point PostgreSQL 15 at the PostgreSQL 18 directory.
