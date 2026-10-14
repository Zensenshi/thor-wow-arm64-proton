# Troubleshooting

- `install.sh` stops with `FAILED`: it shows the end of the failing step's log; the full logs are in `~/wow-arm64-work/logs`. Find the matching message below. To start over after a successful install, remove the tool first with `scripts/uninstall.sh`.
- Host check fails: verify ArmadaOS, `uname -m` = `aarch64`, `getconf PAGESIZE` = `4096`.
- Wine build refuses with `No permitted Wine patch`: the patch file is missing or empty; restore `patches/wine/0001-copied-syscall-dispatch.patch`.
- Patch check fails: stop. Do not force a patch or switch revisions.
- Hashes differ from `VERSION-PINS`: expected if your paths, containers or toolchain differ; `scripts/verify.sh` is the real check. A wrong syscall count means the patch was not applied or the source is not the pinned commit.
- `wine: failed to load .../aarch64-windows/ntdll.dll error c00000bb`: the DLL is aarch64-only. Rebuild with `--enable-archs=aarch64,arm64ec`; `scripts/verify.sh` checks for the hybrid sections.
- `ir3_sched.c ... sched_block: Assertion` or `MESA: error: compile failed! (fs...)` right after the swapchain is created: the Turnip in use lacks the scheduler fix, as the system Mesa 26.2.4 does; build the private driver with `patches/mesa` and select it with `VK_DRIVER_FILES`.
- Logs are huge and the device stalls: `PROTON_LOG=1` enables `+seh,+unwind`. Put `WINEDEBUG=+timestamp,+pid,+tid,+loaddll` with the other variables in front of the launcher command.
- DXVK architecture check fails: rebuild with ARM64 Windows cross-toolchain; verifier requires PE machine `0xaa64`.
- Turnip unavailable: check private ICD JSON in `VK_DRIVER_FILES`, library path, and private `LD_LIBRARY_PATH`; do not replace system ICDs.
- Steam omits tool: restart Steam and check that the private folder contains `compatibilitytool.vdf` and the copied `toolmanifest.vdf`.
- Game/launcher issue: verify official files using Blizzard tools. This repository does not handle credentials, game updates, or account/service support.
