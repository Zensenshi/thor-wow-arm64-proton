# Upstream licences

The files here are verbatim copies of the licence texts from the pinned upstream sources, included because the patches in this repository are changes to those sources. Preserve them, and the notices in the sources themselves, when redistributing anything built from this repository.

| Upstream | Pinned at | Licence, as stated in the pinned source | Text here |
|---|---|---|---|
| Valve Wine | `e60892cc2398b0a83c332a2078c7b85e47bdb42b` | LGPL-2.1-or-later (`LICENSE`, `COPYING.LIB`, and the headers of the two files the patch touches). | `Wine-LICENSE.txt`, `LGPL-2.1.txt` |
| DXVK | `a6764047e587178283fcde4073ae6e1410af594f` | zlib/libpng (`LICENSE`). Its submodules carry their own licences. | `DXVK-LICENSE.txt` |
| dxbc-spirv | `fe5a4ef1e99357c8b9f57e4cfb1195c3dae9707f` | MIT (`LICENSE`). | `dxbc-spirv-LICENSE.txt` |
| Mesa | tag `mesa-26.2.4` | Several licences across the tree (`docs/license.rst`). The one file patched, `src/freedreno/ir3/ir3_sched.c`, is marked `SPDX-License-Identifier: MIT`, copyright 2014 Rob Clark. | `Mesa-MIT.txt` |
| LLVM-MinGW | release `20260922` | Used as a build tool only and not redistributed; see the licence files in the release. | none |

The root MIT licence applies only to this project's own scripts and documentation. Each patch is offered under the licence of the files it modifies. See `../docs/LEGAL.md`.
