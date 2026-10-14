#!/usr/bin/env bash
# Builds Wine ntdll, DXVK and Turnip in two distrobox containers and installs the private Proton tool.
# Run on the device from anywhere; see docs/BUILD.md for what each step does.
set -uo pipefail
[[ -n "${HOME:-}" && "${HOME#/}" != "$HOME" ]] || { echo "HOME must be an absolute user-home path" >&2; exit 2; }
ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
WORK="${WOW_WORK_DIR:-$HOME/wow-arm64-work}"
TOOL="${WOW_TOOL_NAME:-Proton-11-ARM64-WoW}"
STOCK="${STOCK_PROTON_DIR:-$HOME/.local/share/Steam/steamapps/common/Proton 11.0 (ARM64)}"
WINE_BOX="${WOW_WINE_CONTAINER:-wow-wine-build}"
MESA_BOX="${WOW_MESA_CONTAINER:-wow-mesa-build}"
CPUS="$(getconf _NPROCESSORS_ONLN)"
JOBS="${JOBS:-$(( CPUS > 2 ? CPUS - 2 : 1 ))}"
DEST="$HOME/.local/share/Steam/compatibilitytools.d/$TOOL"
LOGS="$WORK/logs"
UBUNTU_PACKAGES="build-essential clang lld autoconf flex bison gettext pkg-config perl python3 git patch curl xz-utils meson ninja-build glslang-tools"

fail(){ printf '\nFAILED: %s\n' "$1" >&2; if [[ -n "${2:-}" && -f "$2" ]]; then printf -- '--- last lines of %s\n' "$2" >&2; tail -25 "$2" >&2; fi; exit 1; }
step(){ printf '\n[%s] %s\n' "$1" "$2"; }
box_exists(){
  if command -v podman >/dev/null; then podman container exists "$1"
  else docker container inspect "$1" >/dev/null 2>&1; fi
}
# Runs a command inside a container with all output in a log file.
in_box(){
  local box=$1 log=$2; shift 2
  distrobox enter "$box" -- bash -c "$(printf '%q ' "$@") > $(printf '%q' "$log") 2>&1 < /dev/null"
}

step 1/7 "Checks"
"$ROOT/scripts/prerequisites.sh" || fail "host check"
command -v distrobox >/dev/null || fail "distrobox is required"
[[ -f "$STOCK/proton" && -f "$STOCK/toolmanifest.vdf" ]] || fail "stock Proton 11.0 (ARM64) not found at: $STOCK
Install it through Steam, or set STOCK_PROTON_DIR."
[[ ! -e "$DEST" ]] || fail "$TOOL is already installed at $DEST
To rebuild and reinstall, remove it first with: WOW_TOOL_NAME=$TOOL $ROOT/scripts/uninstall.sh"
mkdir -p "$LOGS"
printf 'Work directory: %s\nLogs:           %s\nThe builds take about 40 minutes and print little while they run.\n' "$WORK" "$LOGS"

step 2/7 "Build containers"
if ! box_exists "$WINE_BOX"; then
  echo "Creating $WINE_BOX (Ubuntu 24.04)"
  distrobox create --yes --name "$WINE_BOX" --image docker.io/library/ubuntu:24.04 > "$LOGS/container-wine.log" 2>&1 || fail "could not create $WINE_BOX" "$LOGS/container-wine.log"
fi
echo "Installing build packages in $WINE_BOX"
rm -f "$LOGS/packages-wine.ok"
distrobox enter "$WINE_BOX" -- sh -c "{ sudo apt-get update && sudo apt-get install -y $UBUNTU_PACKAGES; } > $(printf '%q' "$LOGS/packages-wine.log") 2>&1 < /dev/null && touch $(printf '%q' "$LOGS/packages-wine.ok")"
[[ -f "$LOGS/packages-wine.ok" ]] || fail "package install in $WINE_BOX" "$LOGS/packages-wine.log"
if ! box_exists "$MESA_BOX"; then
  echo "Creating $MESA_BOX (Fedora 44)"
  distrobox create --yes --name "$MESA_BOX" --image registry.fedoraproject.org/fedora:44 > "$LOGS/container-mesa.log" 2>&1 || fail "could not create $MESA_BOX" "$LOGS/container-mesa.log"
fi
echo "Installing build packages in $MESA_BOX"
rm -f "$LOGS/packages-mesa.ok"
distrobox enter "$MESA_BOX" -- sh -c "{ sudo dnf install -y git && sudo dnf builddep -y mesa; } > $(printf '%q' "$LOGS/packages-mesa.log") 2>&1 < /dev/null && touch $(printf '%q' "$LOGS/packages-mesa.ok")"
[[ -f "$LOGS/packages-mesa.ok" ]] || fail "package install in $MESA_BOX" "$LOGS/packages-mesa.log"

step 3/7 "Toolchain"
WOW_WORK_DIR="$WORK" "$ROOT/scripts/fetch-llvm-mingw.sh" > "$LOGS/toolchain.log" 2>&1 || fail "LLVM-MinGW download" "$LOGS/toolchain.log"

A=("$WORK/wine-build-wow/dlls/ntdll/ntdll.so" "$WORK/wine-build-wow/dlls/ntdll/aarch64-windows/ntdll.dll"
   "$WORK/dxvk-arm64/build.arm64/src/dxgi/dxgi.dll" "$WORK/dxvk-arm64/build.arm64/src/d3d11/d3d11.dll")

step 4/7 "Wine ntdll"
in_box "$WINE_BOX" "$LOGS/wine.log" env WOW_WORK_DIR="$WORK" JOBS="$JOBS" nice -n 10 "$ROOT/scripts/build-wine.sh"
[[ -f "${A[0]}" && -f "${A[1]}" ]] || fail "Wine build" "$LOGS/wine.log"

step 5/7 "DXVK"
in_box "$WINE_BOX" "$LOGS/dxvk.log" env WOW_WORK_DIR="$WORK" JOBS="$JOBS" nice -n 10 "$ROOT/scripts/build-dxvk.sh"
[[ -f "${A[2]}" && -f "${A[3]}" ]] || fail "DXVK build" "$LOGS/dxvk.log"

step 6/7 "Turnip"
in_box "$MESA_BOX" "$LOGS/turnip.log" env WOW_WORK_DIR="$WORK" JOBS="$JOBS" nice -n 10 "$ROOT/scripts/build-turnip.sh"
LIBDIR="$WORK/turnip-root/lib64"; [[ -d "$LIBDIR" ]] || LIBDIR="$WORK/turnip-root/lib"
[[ -f "$LIBDIR/libvulkan_freedreno.so" ]] || fail "Turnip build" "$LOGS/turnip.log"

step 7/7 "Verify and install"
"$ROOT/scripts/verify.sh" "${A[@]}" || fail "verification of the built files"
STOCK_PROTON_DIR="$STOCK" WOW_TOOL_NAME="$TOOL" WOW_WORK_DIR="$WORK" "$ROOT/scripts/install-proton.sh" > "$LOGS/install.log" 2>&1 || fail "install" "$LOGS/install.log"
tail -1 "$LOGS/install.log"

ICD="$WORK/turnip-root/share/vulkan/icd.d/freedreno_icd.aarch64.json"
cat <<EOF

Done. Now, in Steam:
  1. Restart Steam.
  2. In the game's Properties > Compatibility, choose: $TOOL
  3. Set its launch options to:

VK_DRIVER_FILES=$ICD LD_LIBRARY_PATH=$LIBDIR\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH} /usr/libexec/armada/armada-game-launch %command% -d3d11

EOF
