#!/usr/bin/env bash
set -euo pipefail
[[ -n "${HOME:-}" && "${HOME#/}" != "$HOME" ]] || { echo "HOME must be an absolute user-home path" >&2; exit 2; }
HOME_REAL="$(cd -- "$HOME" && pwd -P)"
[[ "$HOME_REAL" != /usr && "$HOME_REAL" != /usr/* ]] || { echo "Refusing to write under /usr" >&2; exit 2; }
fail(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
WORK="${WOW_WORK_DIR:-$HOME/wow-arm64-work}"
VERSION=20260922
NAME="llvm-mingw-$VERSION-ucrt-ubuntu-22.04-aarch64"
SHA256=07d21263c56bfe9a713db6fdb3f7434bf4c121a005e40397d3b4c0170fb06769
if [[ ! -x "$WORK/$NAME/bin/clang" ]]; then
  command -v curl >/dev/null || fail 'curl is required'
  mkdir -p "$WORK"
  TAR="$WORK/$NAME.tar.xz"
  [[ -f "$TAR" ]] || curl -fL -o "$TAR" "https://github.com/mstorsjo/llvm-mingw/releases/download/$VERSION/$NAME.tar.xz"
  echo "$SHA256  $TAR" | sha256sum -c - >/dev/null || fail "SHA256 mismatch, delete and retry: $TAR"
  tar -xJf "$TAR" -C "$WORK"
fi
[[ -x "$WORK/$NAME/bin/clang" ]] || fail "Toolchain not found after extraction: $WORK/$NAME"
printf 'LLVM-MinGW %s ready: %s/bin\n' "$VERSION" "$WORK/$NAME"
