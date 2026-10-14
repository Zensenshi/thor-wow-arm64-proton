# WoW ARM64 on AYN Thor (ArmadaOS)

Build scripts and patches for running the unmodified World of Warcraft ARM64 client on an AYN Thor under ArmadaOS, through Steam's Proton.

**Unofficial.** Not affiliated with or endorsed by Blizzard Entertainment, Valve or AYN. This repository is source only: it contains no binaries and no Blizzard software or assets. You need your own copy of the game, installed and updated through Blizzard's launcher.

## Status

Tested on an AYN Thor (ArmadaOS `20261010.c3d178c`, Proton `proton-11.0-2e-arm64`) on 2026-10-14. The client launches and holds 60 fps at 720p on low detail. Longer sessions have not been characterized, and a Proton or game update may break it. Exact versions are in [VERSION-PINS](VERSION-PINS).

## What it does

Stock Proton is left untouched. The scripts build three components on your device and install them into a private copy of Proton.

| Component | Why stock fails | Fix |
|---|---|---|
| Wine `ntdll` | The client copies Wine's syscall stubs, and the copies crash. | A small Wine patch so copied stubs keep working. |
| DXVK | Proton 11.0 ships it in a form a native ARM64 game cannot load. | The same DXVK version, built for native ARM64. |
| Mesa Turnip | Mesa 26.2.4 cannot compile one of the game's shaders. | The upstream fix, backported. |

More detail is in [docs/TECHNICAL.md](docs/TECHNICAL.md), and known failure messages are in [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Install

You need Steam with **Proton 11.0 (ARM64)** installed, the game already installed and added to Steam, `distrobox`, several GB of free space and about 40 minutes.

```sh
git clone https://github.com/Zensenshi/thor-wow-arm64-proton.git
cd thor-wow-arm64-proton
./install.sh
```

The script checks the device, creates two build containers (`wow-wine-build` and `wow-mesa-build`), builds the three components under `~/wow-arm64-work`, and installs the private Proton tool. If a step fails, it stops and shows the end of that step's log.

Then, in Steam: restart Steam, set the game's compatibility tool to `Proton-11-ARM64-WoW`, and use these launch options (the script prints them as well):

```
VK_DRIVER_FILES=$HOME/wow-arm64-work/turnip-root/share/vulkan/icd.d/freedreno_icd.aarch64.json LD_LIBRARY_PATH=$HOME/wow-arm64-work/turnip-root/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH} /usr/libexec/armada/armada-game-launch %command% -d3d11
```

`scripts/uninstall.sh` removes the Proton tool; [docs/BUILD.md](docs/BUILD.md#uninstall) also covers removing the build files and containers. To run the steps one at a time, or to see what each does, read [docs/BUILD.md](docs/BUILD.md).

## Other devices

Only the AYN Thor has been tested. Other Snapdragon 8 Gen 2 handhelds should work if they run Linux with Steam for ARM64 and the same Proton build. On an OS other than ArmadaOS, drop `/usr/libexec/armada/armada-game-launch` from the launch options. Reports are welcome.

## License and credits

The scripts and documentation are under the [MIT license](LICENSE). Each patch carries the license of the upstream project it modifies; see [licenses/](licenses/) and [docs/LEGAL.md](docs/LEGAL.md).

Maintained by [@Zensenshi](https://github.com/Zensenshi), with AI assistance from ChatGPT and Claude. Built on Valve's Proton and Wine, DXVK, Mesa Turnip, LLVM-MinGW and ArmadaOS.

Blizzard does not support running the client this way. Use is at your own risk.
