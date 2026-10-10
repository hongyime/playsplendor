#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")" || exit 1
exec java -cp classes com.splendor.Main "$@"
