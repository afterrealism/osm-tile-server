.PHONY: build import run push test test-config test-multistyle stop

CONTAINER_ENGINE ?= docker
COMPOSE = ${CONTAINER_ENGINE} compose
DOCKER_IMAGE=afterrealism/osm-tile-server
DATABASE_IMAGE=afterrealism/osm-tile-database

build:
	${COMPOSE} build

import: build
	${COMPOSE} run --rm map import

run:
	${COMPOSE} up map

push: build
	${CONTAINER_ENGINE} tag ${DOCKER_IMAGE}:local ${DOCKER_IMAGE}:latest
	${CONTAINER_ENGINE} push ${DOCKER_IMAGE}:latest
	${CONTAINER_ENGINE} push ${DATABASE_IMAGE}:pg18

test: test-config test-multistyle

test-config:
	./tests/local-data.sh
	./tests/upstream-fixes.sh
	./tests/postgres18.sh

test-multistyle: build
	CONTAINER_ENGINE=${CONTAINER_ENGINE} ./tests/multistyle-integration.sh

stop:
	${COMPOSE} down
