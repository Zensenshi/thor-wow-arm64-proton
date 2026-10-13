#!/usr/bin/env bash
set -euo pipefail
[[ -n "${HOME:-}" && "${HOME#/}" != "$HOME" ]] || { echo "HOME must be an absolute user-home path" >&2; exit 2; }
HOME_REAL="$(cd -- "$HOME" && pwd -P)"
[[ "$HOME_REAL" != /usr && "$HOME_REAL" != /usr/* ]] || { echo "Refusing to write under /usr" >&2; exit 2; }
fail(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
WORK="${WOW_WORK_DIR:-$HOME/wow-arm64-work}"
SRC="$WORK/mesa"
BUILD="$WORK/mesa-build-turnip"
PREFIX="$WORK/turnip-root"
command -v git >/dev/null || fail 'git is required'
command -v meson >/dev/null || fail 'meson is required'
command -v ninja >/dev/null || fail 'ninja is required'
[[ "$(uname -m)" == aarch64 ]] || fail 'Turnip build must run natively on aarch64.'
if [[ ! -d "$SRC/.git" ]]; then
  git init -q "$SRC"
  git -C "$SRC" remote add origin https://gitlab.freedesktop.org/mesa/mesa.git
fi
git -C "$SRC" fetch --depth 1 origin tag mesa-26.2.4
git -C "$SRC" checkout -q mesa-26.2.4
[[ "$(git -C "$SRC" rev-parse HEAD)" == 96cb43121031992b85767f9c1be8f3f48e22b1d2 ]] || fail 'mesa-26.2.4 does not resolve to the pinned commit.'
for p in "$ROOT"/patches/mesa/*.patch; do
  [[ -e "$p" ]] || continue
  if git -C "$SRC" apply --check "$p"; then git -C "$SRC" apply "$p"
  elif git -C "$SRC" apply --reverse --check "$p"; then :
  else fail "Patch does not apply cleanly: $p"; fi
done
ARGS=(-Dbuildtype=release -Dprefix="$PREFIX" -Dvulkan-drivers=freedreno -Dgallium-drivers= -Dplatforms=x11,wayland -Degl=disabled -Dglx=disabled -Dgbm=disabled -Dllvm=disabled)
if [[ -f "$BUILD/build.ninja" ]]; then
  meson setup --reconfigure "$BUILD" "$SRC" "${ARGS[@]}"
else
  meson setup "$BUILD" "$SRC" "${ARGS[@]}"
fi
ninja -C "$BUILD" ${JOBS:+-j"$JOBS"}
meson install -C "$BUILD" --no-rebuild
printf 'Private Turnip installation: %s\n' "$PREFIX"
printf 'Point VK_DRIVER_FILES to the ICD JSON under this prefix and LD_LIBRARY_PATH to its private library directory.\n'
