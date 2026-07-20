FROM postgis/postgis:18-3.6

COPY postgresql.conf /opt/osm-tile-server/postgresql.conf
COPY 10-configure.sh /docker-entrypoint-initdb.d/10-configure.sh
COPY 20-extensions.sql /docker-entrypoint-initdb.d/20-extensions.sql

RUN chmod 0755 /docker-entrypoint-initdb.d/10-configure.sh
