# Legal and sharing notes

This is not legal advice and does not determine whether a particular setup complies with service terms or law. Review current terms and applicable law before use or publication. Get qualified advice if publishing or using this raises material legal concerns for you.

## What this repository contains

Source only: shell scripts, documentation, and patches against published open-source projects. It contains no binaries of any kind, no Blizzard software, game data, launcher, artwork or credentials, and no files from Valve's Proton.

The scripts download only the pinned open-source sources (Valve Wine, DXVK and its submodules, Mesa) and the LLVM-MinGW toolchain, each from its official repository, and build them on your own device. They make a local copy of the Proton you installed through Steam. They do not download, modify, authenticate against, update or launch any Blizzard software or service; obtain and update the game only through Blizzard's official channels.

## What the built components do

They are parts of the compatibility layer the client runs on: Wine's `ntdll`, DXVK, and Mesa's Vulkan driver. None of the patches reads or alters game memory or game files, automates input, intercepts network traffic, or disables any check in the client. The Wine patch changes how Wine's own system-call stubs locate Wine's dispatcher, so that a copy of a stub behaves like the original, as it does on Windows.

Blizzard does not support running its clients this way. Nothing here implies Blizzard's approval and no account-safety guarantee is given. Use is at your own risk.

## Provenance and licences

| Material | Origin | Licence |
|---|---|---|
| `patches/wine` | Written for this repository against the pinned Valve Wine commit, from the observed failure and Wine's own ARM64 TEB and thread-data definitions. | LGPL-2.1-or-later, the licence of the Wine files it modifies. |
| `patches/dxvk` | Written for this repository; each adds one standard header include. No functional change. | zlib/libpng (DXVK) and MIT (dxbc-spirv), the licences of the files they modify. |
| `patches/mesa` | Unmodified upstream Mesa commit `2f8dc9eaba06`, with its author and sign-off preserved in the patch header. | MIT, as marked in the file it modifies. |
| Scripts and documentation | Written for this repository. | MIT; see `LICENSE`. |

An earlier community build with the same purpose as the Wine patch circulated only as a binary download, with no source repository and no stated licence. This project exists so that the source, the licence and the build steps are visible. Nothing from that download, neither its binaries nor its patch, is included in this repository.

Parts of this repository, including the Wine patch, the scripts and the documentation, were drafted with AI assistance. The maintainer built and tested the result on the target device.

The root MIT licence covers only the scripts and documentation. It does not relicense upstream code or the patches derived from it. The upstream licence texts are in `licenses/`; see also `NOTICE.md`.

## If you distribute binaries

This repository deliberately distributes none. If you publish binaries built from it, the upstream obligations become yours: for Wine, the LGPL requires you to offer the corresponding source, including the patch, and to keep the licence and notices; for DXVK, dxbc-spirv and Mesa, keep their copyright and licence notices. Do not publish binaries until you have inventoried every component in them and met each licence.

Names and trademarks are used descriptively; see `NOTICE.md`.
