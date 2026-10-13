#!/usr/bin/env bash
set -euo pipefail
[[ -n "${HOME:-}" && "${HOME#/}" != "$HOME" ]] || { echo "HOME must be an absolute user-home path" >&2; exit 2; }
HOME_REAL="$(cd -- "$HOME" && pwd -P)"
[[ "$HOME_REAL" != /usr && "$HOME_REAL" != /usr/* ]] || { echo "Refusing to write under /usr" >&2; exit 2; }
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
WORK="${WOW_WORK_DIR:-$HOME/wow-arm64-work}"
PATCH="${WINE_PATCH:-$ROOT/patches/wine/0001-copied-syscall-dispatch.patch}"
[[ -s "$PATCH" ]] || { printf 'No permitted Wine patch. See patches/wine/README.md. Refusing to build.\n' >&2; exit 2; }
SRC="$WORK/wine"
COMMIT=e60892cc2398b0a83c332a2078c7b85e47bdb42b
for t in git perl python3 autoreconf make flex bison; do command -v "$t" >/dev/null || { printf '%s is required (run inside the build container; see docs/BUILD.md)\n' "$t" >&2; exit 2; }; done
if [[ ! -d "$SRC/.git" ]]; then
  git init -q "$SRC"
  git -C "$SRC" remote add origin https://github.com/ValveSoftware/wine.git
fi
if [[ "$(git -C "$SRC" rev-parse -q --verify HEAD 2>/dev/null || true)" != "$COMMIT" ]]; then
  git -C "$SRC" fetch --depth 1 origin "$COMMIT"
  git -C "$SRC" checkout -q FETCH_HEAD
fi
if git -C "$SRC" apply --check "$PATCH"; then
  git -C "$SRC" apply "$PATCH"
elif git -C "$SRC" apply --reverse --check "$PATCH"; then
  : # already applied
else
  printf 'Patch does not apply cleanly: %s\n' "$PATCH" >&2; exit 1
fi
# The pinned tree ships without its generated sources; produce them the way Proton's build does.
if [[ ! -x "$SRC/configure" ]]; then
  (cd "$SRC" && XDG_CACHE_HOME="$WORK/wine-cache" dlls/winevulkan/make_vulkan -x vk.xml -X video.xml \
    && tools/make_specfiles && tools/make_requests && autoreconf -f)
fi
BUILD="$WORK/wine-build-wow"
BIN="${LLVM_MINGW_BIN:-$WORK/llvm-mingw-20260922-ucrt-ubuntu-22.04-aarch64/bin}"
[[ -x "$BIN/clang" ]] || { echo 'LLVM-MinGW 20260922 not found; run scripts/fetch-llvm-mingw.sh or set LLVM_MINGW_BIN.' >&2; exit 2; }
export PATH="$BIN:$PATH"
mkdir -p "$BUILD"
# ntdll.dll must be an ARM64X hybrid (aarch64 + arm64ec): Proton starts x86_64 helper
# processes, and an aarch64-only ntdll.dll fails to load for them with c00000bb.
if [[ ! -f "$BUILD/Makefile" ]]; then
  (cd "$BUILD" && "$SRC/configure" --enable-archs=aarch64,arm64ec --with-mingw=clang --disable-tests \
    --without-x --without-freetype --without-gstreamer --without-vulkan --without-wayland CC=clang CXX=clang++)
elif ! "$BUILD/config.status" --config | grep -q arm64ec; then
  printf 'Build directory was configured without arm64ec; remove it and rerun: %s\n' "$BUILD" >&2; exit 1
fi
make -C "$BUILD" -j"${JOBS:-$(getconf _NPROCESSORS_ONLN)}" dlls/ntdll/all
printf 'Wine build complete. Outputs: %s/dlls/ntdll/ntdll.so and %s/dlls/ntdll/aarch64-windows/ntdll.dll\n' "$BUILD" "$BUILD"
