# Upstream Provenance

URL: https://github.com/openmaptiles/planetiler-openmaptiles
Tag: v3.16
Commit: 5be22807170439320354b39ed9b390aa796a2cee
Vendored: 2026-07-19
Local modifications: None at initial vendoring.
2026-07-19: added Dockerfile (project build recipe: engine v0.10.2 + this profile
built via the submodule path, packaged as a with-deps jar).
2026-07-21: Dockerfile Maven build now uses a BuildKit cache mount for /root/.m2
so rebuilds do not re-download all dependencies.
2026-08-04: Dockerfile uses the image's mvn (the ./mvnw wrapper downloaded Maven
3.8.2 from Maven Central on every cold build); base images pinned by digest.
Upstream pushes: Prohibited; changes are maintained only in this repository.
