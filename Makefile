.PHONY: build fetch-planet check-capacity build-pmtiles assets run test test-config test-multistyle stop

CONTAINER_ENGINE ?= docker
COMPOSE = ${CONTAINER_ENGINE} compose

build:
	${COMPOSE} build themes
	${COMPOSE} --profile tools build planetiler

fetch-planet:
	./scripts/fetch-planet.sh

check-capacity:
	./scripts/check-planet-capacity.sh

build-pmtiles: check-capacity
	${COMPOSE} --profile tools run --rm planetiler

assets:
	./scripts/prepare-style-assets.sh

run:
	${COMPOSE} up themes

test: test-config test-multistyle

test-config:
	./tests/local-data.sh
	./tests/planet-source.sh
	./tests/vendor-sources.sh
	PYTHONPATH=. python3 tests/artifact_manifest.test.py -v
	PYTHONPATH=. python3 tests/openmaptiles-pmtiles.test.py -v
	node --test tests/tileserver-config.mjs tests/theme-assets.test.mjs

test-multistyle: build
	CONTAINER_ENGINE=${CONTAINER_ENGINE} ./tests/multistyle-integration.sh

stop:
	${COMPOSE} down
