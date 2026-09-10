#!/usr/bin/env bash
# Build a complete site in a new directory; pass --output to choose an empty one.
set -euo pipefail
cd "$(dirname "$0")" || exit 1
exec python3 scripts/build_site.py "$@"
