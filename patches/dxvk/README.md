# DXVK patch notes

These are build fixes only: each adds a standard header that the pinned sources use without including directly, which fails with the LLVM-MinGW 20260922 C++ library. None changes behaviour. They exist because Proton 11.0 ships its ARM64 DXVK as ARM64EC only, so a native ARM64 build of the same commit is needed.

Against DXVK commit `a6764047e587178283fcde4073ae6e1410af594f`:

- `0001-add-missing-utility-includes.patch`: `<utility>` for `std::exchange` in two `d3d11` translation units.
- `0004-dxvk-config-include-algorithm.patch`: `<algorithm>` in `src/util/config/config.cpp`.
- `0005-dxvk-small-vector-include-new.patch`: `<new>` for `std::launder` in `src/util/util_small_vector.h`.

Against dxbc-spirv commit `fe5a4ef1e99357c8b9f57e4cfb1195c3dae9707f`, pinned as DXVK's submodule:

- `0002-dxbc-spirv-add-array-includes.patch`: `<array>` in two `dxbc` translation units.
- `0003-dxbc-spirv-include-new.patch`: `<new>` for `std::launder` in `util/util_small_vector.h`.

All are ordinary unified diffs. `scripts/build-dxvk.sh` applies every patch in this directory, sending those named `*dxbc-spirv*` to the submodule, and skips patches already applied. Review the pinned upstream licenses; DXVK uses zlib/libpng, while dxbc-spirv carries its own license. See `../../licenses/README.md`.
