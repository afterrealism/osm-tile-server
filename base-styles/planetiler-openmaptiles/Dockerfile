FROM maven:3.9.11-eclipse-temurin-21 AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src/planetiler
COPY planetiler/ .
COPY planetiler-openmaptiles/ ./planetiler-openmaptiles/
RUN git init \
 && git config user.email build@local \
 && git config user.name build \
 && git add . \
 && git commit -m vendored \
 && MAVEN_CONFIG= ./mvnw -B -ntp -DskipTests -Dspotless.check.skip -Pflatten install \
 && MAVEN_CONFIG= ./mvnw -B -ntp -DskipTests -Dspotless.check.skip \
      -Dplanetiler.version=0.10.2-SNAPSHOT \
      -f planetiler-openmaptiles/pom.xml package

FROM eclipse-temurin:21-jre
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /src/planetiler/planetiler-openmaptiles/target/*with-deps.jar /app/planetiler-openmaptiles.jar
ENTRYPOINT ["java", "-jar", "/app/planetiler-openmaptiles.jar"]
