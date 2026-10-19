---
name: "optimize-perf"
description: "Make one rendering feature of a real-time game (e.g. turf, sand, trees, water, shadows) run at 120 fps while matching or beating AAA / Unreal Engine visual quality. Invoked as `/optimize-perf TARGET`, e.g. `/optimize-perf turf`. Also use whenever the user says a game feature is too slow, drops frames, misses the fps budget, or asks to add a visual feature without hurting performance."
---

# Optimize perf

`/optimize-perf <target>` is the whole prompt. Work out the rest from this skill and the codebase.

## The goal

Get the target to **AAA / Unreal Engine level on both axes at once**: shipped-game visual quality *and* shipped-game performance. Neither half is optional. A faster version that looks worse is a failure, and so is a better-looking version that misses the fps budget.

- **Performance:** average **>119 fps** (target 120) during gameplay, with the target enabled.
- **Fidelity:** the same as or better than the current version, judged against what a current Unreal title would show at the same distance. If the current version is below that bar, raising it is part of the job.

Measure with the **isolation settings** so the number reflects the target's own cost: all other effects off, dynamic resolution off, fast lighting off, TAUU off. Read the settings back to confirm they took effect.

If the display runs at 120 Hz, fps will sit at the cap and hide how much headroom you have. Use frame time (CPU and GPU ms) to see how far under the budget you are.

## Vocabulary

- **Material**: a lit, shaded surface that responds to the scene's lighting (normals, roughness, height, AO, etc.), as Unreal uses the word. It is not a flat image. A material may sample textures internally, as long as it's still lit per pixel.
- **HQ / LQ**: the high-quality version of a material near the camera and the low-quality version far away. The transition must not visibly pop or seam, including while the camera moves.

## Targets

- **turf**: turf and sand materials: fairway, rough, fringe, green, tee, bunker. HQ within 40 yards of the camera, LQ beyond.
- **Anything else:** infer the scope from the code. State your assumption in your first update and keep going.

## Working method

- **Metrics:** the game's performance monitor (click the FPS graph) already captures extensive metrics. Use what's reachable from the console. If something you need is only visible by opening the menu, add a console API for it. Use the repo's existing camera, gameplay and view tooling rather than building parallel versions.
- **User updates and fast iteration:** if `visual-debug-loop` is available, follow its "Keep the user in the loop" and "Phase 0" sections. Where the repo already has the tooling, use it.
- **Baseline first:** record fps, frame time and close-up captures before changing anything. Then change one thing at a time and keep what measurably helps.
- **Check fidelity close up:** zoom into crops at close range, at the HQ/LQ boundary, and at distance, compared with the baseline at the same views. Full-frame screenshots hide the regressions that matter (aliasing, tiling, blur, seams). Any visible downgrade needs the user's explicit OK.

## Report

Keep it short:

- average fps and frame time, before → after, with the settings you used
- what changed
- before/after crops
- anything you didn't verify

If the target misses 120 fps, say what's left and what you'd try next.