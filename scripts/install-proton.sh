#!/usr/bin/env bash
set -euo pipefail
[[ -n "${HOME:-}" && "${HOME#/}" != "$HOME" ]] || { echo "HOME must be an absolute user-home path" >&2; exit 2; }
HOME_REAL="$(cd -- "$HOME" && pwd -P)"
[[ "$HOME_REAL" != /usr && "$HOME_REAL" != /usr/* ]] || { echo "Refusing to write under /usr" >&2; exit 2; }
fail(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
STOCK="${STOCK_PROTON_DIR:-}"; WORK="${WOW_WORK_DIR:-$HOME/wow-arm64-work}"
BUILD="$WORK/wine-build-wow"; DXVK="$WORK/dxvk-arm64/build.arm64"
TOOL="${WOW_TOOL_NAME:-Proton-11-ARM64-WoW}"
[[ "$TOOL" =~ ^[A-Za-z0-9._-]+$ ]] || fail 'WOW_TOOL_NAME may only contain letters, digits, dot, underscore and dash.'
DEST="$HOME/.local/share/Steam/compatibilitytools.d/$TOOL"
[[ -n "$STOCK" && -d "$STOCK" && ! -L "$STOCK" && -f "$STOCK/proton" && -f "$STOCK/toolmanifest.vdf" ]] || fail 'Set STOCK_PROTON_DIR to a real existing proton-11.0-2e-arm64 directory.'
STOCK_REAL="$(cd -- "$STOCK" && pwd -P)"
[[ "$STOCK_REAL" != "$DEST" ]] || fail 'Stock and destination must differ.'
case "$DEST/" in "$STOCK_REAL/"*) fail 'Destination cannot be inside stock Proton.';; esac
case "$STOCK_REAL/" in "$DEST/"*) fail 'Stock Proton cannot be inside destination.';; esac
[[ ! -e "$DEST" ]] || fail "Destination exists; move it aside manually: $DEST"
A=("$BUILD/dlls/ntdll/ntdll.so" "$BUILD/dlls/ntdll/aarch64-windows/ntdll.dll" "$DXVK/src/dxgi/dxgi.dll" "$DXVK/src/d3d11/d3d11.dll")
for f in "${A[@]}"; do [[ -f "$f" ]] || fail "Missing artifact: $f"; done
"$ROOT/scripts/verify.sh" --artifacts-only "${A[@]}"
mkdir -p "$(dirname -- "$DEST")"
DEST_PARENT_REAL="$(cd -- "$(dirname -- "$DEST")" && pwd -P)"
case "$DEST_PARENT_REAL/" in "$HOME_REAL/"*) ;; *) fail 'Resolved Proton destination is outside the user home directory.';; esac
mkdir "$DEST"
# Dereference stock symlinks so replacement cannot write through to the stock installation.
cp -aL -- "$STOCK/." "$DEST/"
# Replace only the four requested files in the private copy.
LIB="$DEST/files/lib"; [[ -d "$LIB/wine/aarch64-unix" ]] || LIB="$DEST/files/lib64"
DX="$LIB/wine/dxvk/aarch64-windows"
# Steam installs Proton read-only; make only the replaced files and their directories writable.
chmod u+w "$DEST"
for f in "$LIB/wine/aarch64-unix/ntdll.so" "$LIB/wine/aarch64-windows/ntdll.dll" "$DX/dxgi.dll" "$DX/d3d11.dll"; do
  [[ -f "$f" && ! -L "$f" ]] || fail "Private copy is missing the file to replace: $f"
  chmod u+w "$f" "$(dirname -- "$f")"
done
cp -- "${A[0]}" "$LIB/wine/aarch64-unix/ntdll.so"
cp -- "${A[1]}" "$LIB/wine/aarch64-windows/ntdll.dll"
# Proton copies DXVK into the prefix from wine/dxvk; the stock DLLs there are ARM64EC-only.
cp -- "${A[2]}" "$DX/dxgi.dll"
cp -- "${A[3]}" "$DX/d3d11.dll"
# Steam lists a tool in compatibilitytools.d only if this file names it.
[[ ! -e "$DEST/compatibilitytool.vdf" ]] || chmod u+w "$DEST/compatibilitytool.vdf"
cat > "$DEST/compatibilitytool.vdf" <<EOF
"compatibilitytools"
{
  "compat_tools"
  {
    "$TOOL"
    {
      "install_path" "."
      "display_name" "$TOOL"
      "from_oslist" "windows"
      "to_oslist" "linux"
    }
  }
}
EOF
printf 'Installed private tool at %s\n' "$DEST"
