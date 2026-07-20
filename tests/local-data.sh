#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

grep -Fq -- "- ./data:/data" "$ROOT/docker-compose.yml"
grep -Fxq '/data/' "$ROOT/.dockerignore"
git -C "$ROOT" check-ignore -q data/runtime-download

echo "local data configuration is valid"
