# syntax=docker/dockerfile:1
# tag pinned by digest 2026-08-04
FROM maven:3.9.11-eclipse-temurin-21@sha256:463a1849665463254b2dd56e3a5b316f1596bc93d0571065c06ea05bb48ab8f4 AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src/planetiler
COPY planetiler/ .
COPY planetiler-openmaptiles/ ./planetiler-openmaptiles/
RUN --mount=type=cache,target=/root/.m2 \
 git init \
 && git config user.email build@local \
 && git config user.name build \
 && git add . \
 && git commit -m vendored \
 && mvn -B -ntp -DskipTests -Dspotless.check.skip -Pflatten install \
 && mvn -B -ntp -DskipTests -Dspotless.check.skip \
      -Dplanetiler.version=0.10.2-SNAPSHOT \
      -f planetiler-openmaptiles/pom.xml package

# tag pinned by digest 2026-08-04
FROM eclipse-temurin:21-jre@sha256:273396ed5998598ed1091e8d72711c2d36980a0e65103859c55a4e977a41ffd3
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /src/planetiler/planetiler-openmaptiles/target/*with-deps.jar /app/planetiler-openmaptiles.jar
ENTRYPOINT ["java", "-jar", "/app/planetiler-openmaptiles.jar"]
