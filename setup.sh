#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
"$ROOT/scripts/prerequisites.sh"
printf '\nNext: run ./install.sh, or follow docs/BUILD.md to do the steps by hand.\n'
