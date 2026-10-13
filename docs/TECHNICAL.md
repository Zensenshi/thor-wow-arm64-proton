# Technical notes

Target path: unmodified Windows ARM64 client → private copy of Proton 11 ARM64 → Wine ARM64 Unix/Windows ntdll and ARM64 DXVK → Vulkan through private Mesa Turnip. Host pins: ArmadaOS `20261010.c3d178c`, kernel `7.2.6`, aarch64, 4096-byte pages. Other pins are in `VERSION-PINS`.

The Wine patch stores the syscall dispatcher in reserved ARM64 TEB CPU-specific data and loads it through x18 from generated syscall stubs, avoiding an embedded PC-relative pointer literal. Its compile-time offset assertion is derived from the named `cpu_data` slot. It has been built and launched on the AYN Thor (2026-10-14).

`ntdll.dll` must be an ARM64X hybrid (`--enable-archs=aarch64,arm64ec`), like the stock one. Proton's `steam.exe` and other helpers are x86_64 images that run as ARM64EC and need the ARM64EC half of `ntdll.dll`; an aarch64-only build loads for native ARM64 processes and then stops the launch with `failed to load .../ntdll.dll error c00000bb`. The copied-syscall patch only touches the native aarch64 stubs.

DXVK: Proton 11.0 builds its ARM64 DXVK as ARM64EC only (Proton Experimental adds `-marm64x`), so a native ARM64 process cannot load the stock DLLs in `wine/dxvk/aarch64-windows`. The scripts build the same DXVK commit for native ARM64. Proton's launcher copies `d3d11.dll` and `dxgi.dll` from that directory into the prefix on every launch, so that is where the replacements go, not the Wine builtin directory.

Installer copies stock Proton and replaces only `wine/aarch64-unix/ntdll.so`, `wine/aarch64-windows/ntdll.dll`, `wine/dxvk/aarch64-windows/dxgi.dll`, and `wine/dxvk/aarch64-windows/d3d11.dll` under the private clone's `files/lib` (`files/lib64` on layouts that use it), and writes the clone's `compatibilitytool.vdf`. Private Turnip uses per-process `VK_DRIVER_FILES` and `LD_LIBRARY_PATH`; never overwrite system Mesa/ICDs.

`scripts/verify.sh` checks the new `0x368` syscall tail count and that `ntdll.dll` has the ARM64X hybrid sections. Hashes from the device's start-to-finish script run are in `VERSION-PINS`; they depend on build paths and toolchain.

Turnip: unpatched Mesa 26.2.4 cannot compile one of the game's fragment shaders (release builds log `compile failed` and crash in `vkCreateGraphicsPipelines`; debug builds assert in `ir3_sched.c` `sched_block`), because the scheduler waits for `bary.f` instructions in other blocks before scheduling a `kill`. `patches/mesa` backports the upstream fix, commit `2f8dc9eaba06`. DXVK verification reads the PE COFF machine field and requires `0xaa64`.
