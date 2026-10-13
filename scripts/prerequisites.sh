#!/usr/bin/env bash
set -euo pipefail
fail(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
[[ "$(uname -m)" == aarch64 ]] || fail "Expected aarch64; found $(uname -m)"
[[ "$(getconf PAGESIZE)" == 4096 ]] || fail "Expected 4096-byte pages; found $(getconf PAGESIZE)"
for c in git sha256sum python3 curl tar; do command -v "$c" >/dev/null || fail "$c is required"; done
command -v distrobox >/dev/null || printf 'Warning: distrobox not found. The ArmadaOS host has no compiler; the builds need a container (see docs/BUILD.md).\n' >&2
[[ -r /etc/os-release ]] || fail 'Cannot identify host OS'
grep -Eiq armada /etc/os-release || printf 'Warning: /etc/os-release does not identify ArmadaOS.\n' >&2
printf 'Host checks passed: aarch64, 4096-byte pages.\n'
