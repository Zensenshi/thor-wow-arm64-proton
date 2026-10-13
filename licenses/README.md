# Upstream licence references

References only; upstream licence texts are not copied here. Each is in the pinned source the scripts fetch. Review them and preserve their notices before redistributing anything built from this repository.

| Upstream | Pinned at | Licence, as stated in the pinned source |
|---|---|---|
| Valve Wine | `e60892cc2398b0a83c332a2078c7b85e47bdb42b` | LGPL-2.1-or-later (`LICENSE`, `COPYING.LIB`, and the headers of the two files the patch touches). |
| DXVK | `a6764047e587178283fcde4073ae6e1410af594f` | zlib/libpng (`LICENSE`). Its submodules carry their own licences. |
| dxbc-spirv | `fe5a4ef1e99357c8b9f57e4cfb1195c3dae9707f` | MIT (`LICENSE`). |
| Mesa | tag `mesa-26.2.4` | Several licences across the tree (`docs/license.rst`); `src/freedreno/ir3/ir3_sched.c`, the one file patched, is marked `SPDX-License-Identifier: MIT`. |
| LLVM-MinGW | release `20260922` | Used as a build tool only and not redistributed; see the licence files in the release. |

The root MIT licence applies only to this project's own scripts and documentation. Each patch is offered under the licence of the files it modifies. See `../docs/LEGAL.md`.
