#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
"$ROOT/scripts/prerequisites.sh"
printf '
Host checks passed. Continue with docs/BUILD.md.\n'
