# Mesa patch notes

`0001-ir3-sched-ignore-baryf-in-different-block.patch` is an unmodified backport of upstream Mesa commit `2f8dc9eaba06770ea50583bef175e41792048ced` ("ir3/sched: don't try to schedule kill after bary.f in different block", Job Noorman, merge request 44620, 2026-09-23). It is not in the `mesa-26.2.4` tag and applies to it with a line offset. The script checks applicability and skips it if already applied.

The bug it fixes: the IR3 scheduler holds back every `kill` until all `bary.f` instructions in the shader are scheduled, including ones in a later block. Such a `kill` can never become ready, so the shader fails to compile. With Mesa 26.2.4 one of the game's fragment shaders hits this right after the swapchain is created: release builds log `MESA: error: compile failed! (fs...)` and crash in `vkCreateGraphicsPipelines`; debug builds stop at the `sched_block` assertion in `ir3_sched.c`.

**Status (2026-10-14):** validated on the device. A release Turnip built from the pristine `mesa-26.2.4` tarball plus this patch (Fedora 44 container, the options in `scripts/build-turnip.sh`) runs the game; it launches, stays open and holds 60 fps, with no Mesa errors in the log.

The touched Mesa source file is MIT-licensed in the pinned tree; preserve its upstream notices. Review Mesa's per-file and component licenses before redistribution. See `../../licenses/README.md`.
