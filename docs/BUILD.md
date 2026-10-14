# Build and install

Run everything on the AYN Thor. Builds stay under `~/wow-arm64-work`; nothing is installed to `/usr` and the host needs no `sudo`.

## Quick install

From the repository folder:

```sh
./install.sh
```

It runs steps 1 to 5 below in order: it checks the device, creates the two build containers if they don't exist and installs their packages, downloads the toolchain, runs the three builds, verifies the result and installs the private Proton tool. At the end it prints the Steam settings from step 6 with the paths for your machine. It was tested from a clean start on the device on 2026-10-14.

- **Output:** each step prints one line and the builds are quiet, about 40 minutes in total. Full logs go to `~/wow-arm64-work/logs`.
- **On failure:** it stops at the failing step and shows the end of that step's log. Fix the cause and run it again; finished work is reused.
- **Already installed:** it refuses to overwrite the tool. To reinstall, run `scripts/uninstall.sh` and then `./install.sh` again.
- **Proton updates:** the patches are pinned to `proton-11.0-2e-arm64`. If Steam updates Proton 11.0 (ARM64), reinstalling copies the new Proton but still builds the old pinned Wine, which may not match. Check `VERSION-PINS` against the new build before relying on it.

Environment overrides, all optional: `WOW_WORK_DIR` (work directory), `WOW_TOOL_NAME` (name of the private Proton copy, default `Proton-11-ARM64-WoW`), `STOCK_PROTON_DIR`, `LLVM_MINGW_BIN`, `JOBS`, and the container names `WOW_WINE_CONTAINER` and `WOW_MESA_CONTAINER` (defaults `wow-wine-build` and `wow-mesa-build`).

## Manual steps

The same process by hand, with what each step does. Run the commands from the repository folder.

### 1. Host check

`./setup.sh` checks aarch64, 4096-byte pages and the few host tools the scripts need. Install stock Proton `proton-11.0-2e-arm64` (build ID `1791559733`) through Steam; it normally lands in `~/.local/share/Steam/steamapps/common/Proton 11.0 (ARM64)`.

### 2. Build containers

The ArmadaOS host has no compiler, linker or `make`, so the builds run in two distrobox containers that share your home directory. These exact commands were tested from scratch on the device on 2026-10-14, followed by a full build:

```sh
distrobox create --yes --name wow-wine-build --image docker.io/library/ubuntu:24.04
distrobox enter wow-wine-build -- sh -c 'sudo apt-get update && sudo apt-get install -y build-essential clang lld autoconf flex bison gettext pkg-config perl python3 git patch curl xz-utils meson ninja-build glslang-tools'

distrobox create --yes --name wow-mesa-build --image registry.fedoraproject.org/fedora:44
distrobox enter wow-mesa-build -- sh -c 'sudo dnf install -y git && sudo dnf builddep -y mesa'
```

### 3. Toolchain

`scripts/fetch-llvm-mingw.sh` downloads LLVM-MinGW 20260922 from its GitHub release, checks SHA256 `07d21263c56bfe9a713db6fdb3f7434bf4c121a005e40397d3b4c0170fb06769` and unpacks it into the work directory, where the build scripts look for it.

### 4. Builds

```sh
distrobox enter wow-wine-build -- "$PWD/scripts/build-wine.sh"
distrobox enter wow-wine-build -- "$PWD/scripts/build-dxvk.sh"
distrobox enter wow-mesa-build -- "$PWD/scripts/build-turnip.sh"
```

- **Wine:** fetches the pinned Valve Wine commit, applies `patches/wine`, generates the sources the tree ships without (`make_vulkan`, `make_specfiles`, `make_requests`, `autoreconf`, as Proton's own build does), configures an ARM64X hybrid build (`--enable-archs=aarch64,arm64ec`) and builds only the `ntdll` targets. Outputs: `wine-build-wow/dlls/ntdll/ntdll.so` and `wine-build-wow/dlls/ntdll/aarch64-windows/ntdll.dll`.
- **DXVK:** fetches the pinned DXVK commit and its submodules, applies the include patches and cross-builds native ARM64 DLLs. Outputs: `dxvk-arm64/build.arm64/src/dxgi/dxgi.dll` and `.../src/d3d11/d3d11.dll`.
- **Turnip:** fetches Mesa tag `mesa-26.2.4`, applies the upstream scheduler fix, and installs a release build into the private `turnip-root` prefix.

### 5. Verify and install

```sh
W=~/wow-arm64-work
scripts/verify.sh $W/wine-build-wow/dlls/ntdll/ntdll.so $W/wine-build-wow/dlls/ntdll/aarch64-windows/ntdll.dll \
  $W/dxvk-arm64/build.arm64/src/dxgi/dxgi.dll $W/dxvk-arm64/build.arm64/src/d3d11/d3d11.dll
STOCK_PROTON_DIR="$HOME/.local/share/Steam/steamapps/common/Proton 11.0 (ARM64)" scripts/install-proton.sh
```

`verify.sh` requires 258 patched syscall stubs, an ARM64X hybrid `ntdll.dll`, and PE machine `0xaa64` for both DXVK DLLs. `install-proton.sh` runs it again, copies stock Proton into `~/.local/share/Steam/compatibilitytools.d/Proton-11-ARM64-WoW`, and replaces only these files in the copy:

- `files/lib/wine/aarch64-unix/ntdll.so`
- `files/lib/wine/aarch64-windows/ntdll.dll`
- `files/lib/wine/dxvk/aarch64-windows/dxgi.dll`
- `files/lib/wine/dxvk/aarch64-windows/d3d11.dll`

It also writes the copy's `compatibilitytool.vdf` so Steam lists it. An existing destination is never overwritten; `scripts/uninstall.sh` removes the private copy.

### 6. Steam

Restart Steam, then on the game's entry choose the compatibility tool `Proton-11-ARM64-WoW` and set the launch options:

```
VK_DRIVER_FILES=$HOME/wow-arm64-work/turnip-root/share/vulkan/icd.d/freedreno_icd.aarch64.json LD_LIBRARY_PATH=$HOME/wow-arm64-work/turnip-root/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH} /usr/libexec/armada/armada-game-launch %command% -d3d11
```

The variables select the private Turnip for this game only; never replace the system Mesa or its ICD files. All variables go before the launcher command. Use the normal Blizzard launcher and official files for installing and updating; this project has no updater or account handling.

For a log, add `PROTON_LOG=1 WINEDEBUG=+timestamp,+pid,+tid,+loaddll` in front. `PROTON_LOG=1` on its own enables exception tracing that produces very large logs with this client.

## Uninstall

1. In Steam, set the game back to another compatibility tool and clear its launch options.
2. Remove the private Proton tool:

   ```sh
   scripts/uninstall.sh
   ```

3. Optionally, remove the build files and the two containers:

   ```sh
   rm -rf ~/wow-arm64-work
   distrobox rm -f wow-wine-build wow-mesa-build
   ```

Stock Proton, the game and its prefix are not touched by any of these.
