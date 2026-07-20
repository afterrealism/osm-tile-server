FROM ubuntu:22.04 AS compiler-common
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
 ca-certificates gnupg lsb-release locales \
 wget curl \
 git-core unzip unrar \
&& locale-gen $LANG && update-locale LANG=$LANG \
&& sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
&& wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
&& apt-get update && apt-get -y upgrade

###########################################################################################################

FROM compiler-common AS compiler-stylesheet
COPY base-styles/openstreetmap-carto /root/openstreetmap-carto
RUN rm -rf /root/openstreetmap-carto/.github

###########################################################################################################

FROM compiler-common AS compiler-helper-script
RUN mkdir -p /home/renderer/src \
&& cd /home/renderer/src \
&& git clone https://github.com/zverik/regional \
&& cd regional \
&& rm -rf .git \
&& chmod u+x /home/renderer/src/regional/trim_osc.py

###########################################################################################################

FROM compiler-common AS compiler-osm2pgsql
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
 build-essential cmake pkg-config \
 libboost-dev libboost-system-dev libboost-filesystem-dev \
 libexpat1-dev zlib1g-dev libbz2-dev \
 libproj-dev liblua5.3-dev libpq-dev nlohmann-json3-dev \
&& apt-get clean autoclean \
&& apt-get autoremove --yes \
&& rm -rf /var/lib/{apt,dpkg,cache,log}/
RUN cd /root \
&& wget -q https://github.com/openstreetmap/osm2pgsql/archive/refs/tags/1.11.0.tar.gz \
&& echo "downloaded osm2pgsql 1.11.0" \
&& tar xf 1.11.0.tar.gz \
&& mkdir osm2pgsql-1.11.0/build && cd osm2pgsql-1.11.0/build \
&& cmake -DCMAKE_BUILD_TYPE=Release .. \
&& make -j"$(nproc)" \
&& make install DESTDIR=/root/osm2pgsql-install

###########################################################################################################

FROM compiler-common AS final

# Based on
# https://switch2osm.org/serving-tiles/manually-building-a-tile-server-18-04-lts/
ENV DEBIAN_FRONTEND=noninteractive
ENV AUTOVACUUM=on
ENV UPDATES=disabled
ENV REPLICATION_URL=https://planet.openstreetmap.org/replication/hour/
ENV MAX_INTERVAL_SECONDS=3600
ENV PG_VERSION 18

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Get packages
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
 apache2 \
 cron \
 dateutils \
 fonts-hanazono \
 fonts-noto-cjk \
 fonts-noto-hinted \
 fonts-noto-unhinted \
 fonts-unifont \
 gnupg2 \
 gdal-bin \
 liblua5.3-dev \
 lua5.3 \
 mapnik-utils \
 npm \
 osmium-tool \
 osmosis \
 postgresql-client-$PG_VERSION \
 python-is-python3 \
 python3-mapnik \
 python3-lxml \
 python3-psycopg2 \
 python3-shapely \
 python3-pip \
 renderd \
 sudo \
 vim \
&& apt-get clean autoclean \
&& apt-get autoremove --yes \
&& rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN adduser --disabled-password --gecos "" renderer

# Get Noto Emoji Regular font, despite it being deprecated by Google
RUN wget https://github.com/googlefonts/noto-emoji/blob/9a5261d871451f9b5183c93483cbd68ed916b1e9/fonts/NotoEmoji-Regular.ttf?raw=true --content-disposition -P /usr/share/fonts/

# For some reason this one is missing in the default packages
RUN wget https://github.com/stamen/terrain-classic/blob/master/fonts/unifont-Medium.ttf?raw=true --content-disposition -P /usr/share/fonts/

# Install python libraries
RUN pip3 install \
 requests \
 osmium \
 pyyaml

# Install carto for stylesheet
RUN npm install -g carto@1.2.0

# Configure Apache
RUN echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/conf-available/mod_tile.conf \
&& echo "LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so" >> /etc/apache2/conf-available/mod_headers.conf \
&& a2enconf mod_tile && a2enconf mod_headers \
&& a2enmod proxy proxy_http
COPY apache.conf /etc/apache2/sites-available/000-default.conf
RUN rm -rf /var/www/html/* \
&& ln -sf /dev/stdout /var/log/apache2/access.log \
&& ln -sf /dev/stderr /var/log/apache2/error.log

# Copy update scripts
COPY openstreetmap-tiles-update-expire.sh /usr/bin/
RUN chmod +x /usr/bin/openstreetmap-tiles-update-expire.sh \
&& mkdir /var/log/tiles \
&& chmod a+rw /var/log/tiles \
&& ln -s /home/renderer/src/mod_tile/osmosis-db_replag /usr/bin/osmosis-db_replag \
&& install -m 0644 /dev/null /etc/osm-tile-server.env \
&& echo "SHELL=/bin/bash" >> /etc/crontab \
&& echo "* * * * *   renderer    . /etc/osm-tile-server.env && openstreetmap-tiles-update-expire.sh\n" >> /etc/crontab

# Create volume directories
RUN mkdir -p /run/renderd/ \
  &&  mkdir  -p  /data/database18-state/  \
  &&  mkdir  -p  /data/style/  \
  &&  mkdir  -p  /home/renderer/src/  \
  &&  chown  -R  renderer:  /data/  \
  &&  chown  -R  renderer:  /home/renderer/src/  \
  &&  chown  -R  renderer:  /run/renderd  \
  &&  mv  /var/cache/renderd/tiles/            /data/tiles/     \
  &&  chown  -R  renderer: /data/tiles \
  &&  ln  -s  /data/style              /home/renderer/src/openstreetmap-carto  \
  &&  ln  -s  /data/tiles              /var/cache/renderd/tiles                \
;

RUN echo '[standard]\n\
URI=/tile/standard/\n\
TILEDIR=/data/tiles/standard\n\
XML=/data/generated/carto-v6/mapnik.xml\n\
HOST=localhost\n\
TILESIZE=256\n\
MAXZOOM=20' >> /etc/renderd.conf \
 && sed -i 's,^tile_dir=/var/cache/renderd/tiles,tile_dir=/data/tiles/standard,' /etc/renderd.conf \
 && sed -i 's,/usr/share/fonts/truetype,/usr/share/fonts,g' /etc/renderd.conf

# Install helper script
COPY --from=compiler-helper-script /home/renderer/src/regional /home/renderer/src/regional

# Install osm2pgsql 1.11.0 built from source (Carto v6 flex requires >= 1.8)
COPY --from=compiler-osm2pgsql /root/osm2pgsql-install/ /

COPY --from=compiler-stylesheet /root/openstreetmap-carto /opt/openstreetmap-carto
COPY scripts/artifact_manifest.py /workspace/scripts/artifact_manifest.py
COPY scripts/import-carto-v6.sh /usr/local/bin/import-carto-v6
RUN chmod 0755 /usr/local/bin/import-carto-v6 \
 && mkdir -p /data/generated/carto-v6 /data/database18-carto-v6-state /data/tiles/standard \
 && chown -R renderer: /data/generated /data/database18-carto-v6-state /data/tiles

# Start running
COPY run.sh /
ENTRYPOINT ["/run.sh"]
CMD []
EXPOSE 80
