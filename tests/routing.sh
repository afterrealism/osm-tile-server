#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
grep -Fq 'AddTileConfig /tile/standard/ standard' "$ROOT/apache.conf"
grep -Fq 'ProxyPass /tile/light/' "$ROOT/apache.conf"
grep -Fq 'ProxyPass /tile/dark/' "$ROOT/apache.conf"
grep -Fq 'ProxyPass /tile/natural/' "$ROOT/apache.conf"
grep -Fq 'RedirectMatch 404 ^/tile/[0-9]' "$ROOT/apache.conf"
grep -Fq 'a2enmod proxy proxy_http' "$ROOT/Dockerfile"
! grep -Fq 'AddTileConfig /tile/ default' "$ROOT/apache.conf"
echo "named tile routing is valid"
