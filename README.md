# ArmadaOS AYN Thor WoW ARM64 compatibility project

Source-only build notes and scripts for testing an unmodified Windows ARM64 game client with open-source compatibility components on AYN Thor/ArmadaOS. This independent project is not affiliated with, endorsed by, or sponsored by Blizzard Entertainment, Valve, or AYN. “World of Warcraft”, “Blizzard”, “Battle.net”, “ArmadaOS”, “Proton”, and related marks belong to their owners; names are used only to identify compatibility targets and upstream projects.

**No Blizzard software or assets are distributed.** Obtain/update the game only through official Blizzard channels. This project does not authenticate, download, update, or launch Blizzard services on your behalf.

## Status

Checked on an AYN Thor (ArmadaOS `20261010.c3d178c`, stock Proton `proton-11.0-2e-arm64`) on 2026-10-14: with the three components below built from this repository's patches, the ARM64 client launches, stays open and holds 60 fps at 720p on low detail. That result is from a start-to-finish run of the scripts in a clean work directory on that device. Longer sessions have not been characterised. Pins in `VERSION-PINS` record that one setup, not a guarantee of future compatibility.

## What it changes

Stock Proton is never modified. The scripts make a private copy under `~/.local/share/Steam/compatibilitytools.d/` and replace four files in it; the graphics driver is a private build selected per launch.

| Component | Problem with stock | What this repository does |
|---|---|---|
| Wine `ntdll` | The client copies syscall stubs out of `ntdll.dll`; the stock ARM64 stub depends on a PC-relative literal that the copy loses, and the game crashes on a null jump. | `patches/wine`: independently drafted patch that loads the dispatcher through the TEB instead. Built as an ARM64X hybrid, as Proton requires. |
| DXVK | Proton 11.0 ships its ARM64 DXVK as ARM64EC only, which a native ARM64 process cannot load. | Builds the same DXVK commit for native ARM64 (`patches/dxvk` are build fixes only). |
| Mesa Turnip | Mesa 26.2.4 cannot compile one of the game's fragment shaders. | `patches/mesa`: unmodified backport of the upstream fix. |

See [docs/TECHNICAL.md](docs/TECHNICAL.md) for the details and [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the failure signatures.

## Use

Follow [docs/BUILD.md](docs/BUILD.md) from top to bottom. Review the scripts before running them. Everything is built under `~/wow-arm64-work` (override with `WOW_WORK_DIR`); nothing is installed system-wide and no `sudo` is used on the host.

Running the game this way is not supported by Blizzard and is at your own risk.

## Other devices

Only the AYN Thor has been tested. Nothing in the patches is specific to it, so other Snapdragon 8 Gen 2 handhelds are expected to work if they match the same conditions:

- They run Linux with Steam for ARM64, not Android. The scripts were written for ArmadaOS.
- They use the same Proton build, `proton-11.0-2e-arm64`. The Wine patch is pinned to the matching Wine commit.
- The kernel uses 4096-byte pages, and the graphics driver interface Mesa's default Turnip build expects.

On another OS, drop `/usr/libexec/armada/armada-game-launch` from the launch options. Reports from other devices are welcome.

## Licence

The scripts and documentation are under the MIT licence in [LICENSE](LICENSE). The patches are not: each is offered under the licence of the upstream files it modifies.

| Patches | Licence | Text |
|---|---|---|
| `patches/wine` | LGPL-2.1-or-later | [licenses/LGPL-2.1.txt](licenses/LGPL-2.1.txt), [licenses/Wine-LICENSE.txt](licenses/Wine-LICENSE.txt) |
| `patches/dxvk` (DXVK files) | zlib/libpng | [licenses/DXVK-LICENSE.txt](licenses/DXVK-LICENSE.txt) |
| `patches/dxvk` (dxbc-spirv files) | MIT | [licenses/dxbc-spirv-LICENSE.txt](licenses/dxbc-spirv-LICENSE.txt) |
| `patches/mesa` | MIT | [licenses/Mesa-MIT.txt](licenses/Mesa-MIT.txt) |

For what the repository contains and where each patch comes from, see [docs/LEGAL.md](docs/LEGAL.md) and [NOTICE.md](NOTICE.md).

## Credits

- **Maintainer and author:** [@Zensenshi](https://github.com/Zensenshi)
- **AI assistance:** ChatGPT and Claude helped with research, debugging, and drafting patches and documentation.
- **Upstream projects:** Valve Proton, Valve Wine, DXVK and dxbc-spirv, Mesa Freedreno/Turnip, LLVM-MinGW, and ArmadaOS.

Upstream copyright notices and licences are preserved; see the [licenses/](licenses/) folder.

This project is unofficial. It is not affiliated with or endorsed by Blizzard Entertainment, and no Blizzard software or assets are included.
