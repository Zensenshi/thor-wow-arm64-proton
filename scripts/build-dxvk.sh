#!/usr/bin/env bash
set -euo pipefail
[[ -n "${HOME:-}" && "${HOME#/}" != "$HOME" ]] || { echo "HOME must be an absolute user-home path" >&2; exit 2; }
HOME_REAL="$(cd -- "$HOME" && pwd -P)"
[[ "$HOME_REAL" != /usr && "$HOME_REAL" != /usr/* ]] || { echo "Refusing to write under /usr" >&2; exit 2; }
fail(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
WORK="${WOW_WORK_DIR:-$HOME/wow-arm64-work}"
SRC="$WORK/dxvk"
BUILD="$WORK/dxvk-arm64/build.arm64"
BIN="${LLVM_MINGW_BIN:-$WORK/llvm-mingw-20260922-ucrt-ubuntu-22.04-aarch64/bin}"
[[ -x "$BIN/aarch64-w64-mingw32-clang" && -x "$BIN/aarch64-w64-mingw32-clang++" ]] || fail 'LLVM-MinGW 20260922 not found; run scripts/fetch-llvm-mingw.sh or set LLVM_MINGW_BIN.'
command -v meson >/dev/null || fail 'meson is required'
command -v ninja >/dev/null || fail 'ninja is required'
COMMIT=a6764047e587178283fcde4073ae6e1410af594f
if [[ ! -d "$SRC/.git" ]]; then
  git init -q "$SRC"
  git -C "$SRC" remote add origin https://github.com/ValveSoftware/dxvk.git
fi
if [[ "$(git -C "$SRC" rev-parse -q --verify HEAD 2>/dev/null || true)" != "$COMMIT" ]]; then
  git -C "$SRC" fetch --depth 1 origin "$COMMIT"
  git -C "$SRC" checkout -q FETCH_HEAD
fi
apply(){
  if git -C "$1" apply --check "$2"; then git -C "$1" apply "$2"
  elif git -C "$1" apply --reverse --check "$2"; then :
  else fail "Patch does not apply cleanly: $2"; fi
}
# Patches named *dxbc-spirv* belong to that submodule; the rest apply to DXVK itself.
for p in "$ROOT"/patches/dxvk/*.patch; do
  case "$p" in *dxbc-spirv*) ;; *) apply "$SRC" "$p";; esac
done
git -C "$SRC" submodule update --init --recursive
for p in "$ROOT"/patches/dxvk/*dxbc-spirv*.patch; do
  apply "$SRC/subprojects/dxbc-spirv" "$p"
done
WINDRES="$BIN/aarch64-w64-mingw32-windres"
[[ -x "$WINDRES" ]] || WINDRES="$BIN/llvm-windres"
[[ -x "$WINDRES" ]] || fail 'LLVM-MinGW windres wrapper not found.'
CROSS="$WORK/dxvk-aarch64-w64-mingw32.ini"
mkdir -p "$WORK" "$BUILD"
cat > "$CROSS" <<EOF
[binaries]
c = '$BIN/aarch64-w64-mingw32-clang'
cpp = '$BIN/aarch64-w64-mingw32-clang++'
ar = '$BIN/llvm-ar'
strip = '$BIN/llvm-strip'
windres = '$WINDRES'
[properties]
needs_exe_wrapper = true
[host_machine]
system = 'windows'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'
EOF
if [[ -f "$BUILD/build.ninja" ]]; then
  meson setup --reconfigure "$BUILD" "$SRC" --cross-file "$CROSS" --buildtype release --prefix "$WORK/dxvk-stage"
else
  meson setup "$BUILD" "$SRC" --cross-file "$CROSS" --buildtype release --prefix "$WORK/dxvk-stage"
fi
ninja -C "$BUILD" ${JOBS:+-j"$JOBS"}
printf 'DXVK build complete: %s\n' "$BUILD"
printf 'Artifacts: %s/src/dxgi/dxgi.dll and %s/src/d3d11/d3d11.dll\n' "$BUILD" "$BUILD"
