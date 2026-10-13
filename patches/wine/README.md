# ARM64 copied-syscall dispatcher patch

`0001-copied-syscall-dispatch.patch` was written for this repository against the pinned Valve Wine source commit in `VERSION-PINS`, from the target behavior and Wine's ARM64 TEB/thread-data definitions. It contains nothing from the earlier binary-only community build described in `docs/LEGAL.md`.

The patch stores the dispatcher pointer in the last reserved ARM64 `cpu_data` slot, initializes that slot for each thread, and has generated syscall stubs load it through x18 (the ARM64 TEB register). This keeps copied syscall stubs from depending on a PC-relative pointer literal embedded in their original image. A compile-time assertion ties the assembly's TEB byte offset to the named slot and the pinned Wine TEB layout. Reserving the final slot also leaves the existing `suspend_pending` layout untouched.

The Wine source at the pinned commit is LGPL-2.1-or-later; the Wine license and the touched-file notices remain applicable. This project's root MIT license does not replace them. See `licenses/README.md` and `docs/LEGAL.md`.

**Validation status (2026-10-14):** built on the AYN Thor at the pinned commit and installed into a private Proton copy; the game launches and stays open with it. The build must be an ARM64X hybrid (`--enable-archs=aarch64,arm64ec`): an aarch64-only `ntdll.dll` carries the same 258 patched stubs but fails to load for Proton's x86_64 helper processes with `c00000bb`. Hashes from the device's script run are in `VERSION-PINS`.
