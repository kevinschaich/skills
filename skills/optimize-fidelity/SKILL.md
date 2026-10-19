---
name: "optimize-fidelity"
description: "Raise one rendering feature of a real-time game (e.g. turf, sand, trees, water, shadows) to AAA / Unreal Engine visual quality while holding 120 fps. Invoked as `/optimize-fidelity TARGET`. Also use when a game feature looks fake, flat, cheap or gamey."
---

# Optimize fidelity

`/optimize-fidelity <target>` is the whole prompt. Work out the rest from this skill and the codebase.

## The goal

Get the target to **AAA / Unreal Engine level on both axes at once**: shipped-game visual quality *and* shipped-game performance. This is the mirror of `/optimize-perf`: here fidelity leads and performance is the guard rail. A better-looking version that misses the fps budget is a failure.

- **Fidelity:** indistinguishable from what a current Unreal title would show at the same distance, in stills and in motion. Where real life and Unreal differ, real life wins.
- **Performance:** average **>119 fps** (target 120) during gameplay with everything on. Also state the target's own cost before and after, measured with the **isolation settings**: all other effects off, dynamic resolution off, fast lighting off, TAUU off. Read the settings back to confirm they took effect.

If the display runs at 120 Hz, fps will sit at the cap and hide how much headroom you have. Use frame time (CPU and GPU ms) to see how far under the budget you are.

## Vocabulary

- **Material**: a lit, shaded surface that responds to the scene's lighting (normals, roughness, height, AO, etc.), as Unreal uses the word. It is not a flat image.
- **HQ / LQ**: the high-quality version of a material near the camera and the low-quality version far away. The transition must not visibly pop or seam, including while the camera moves.

## Targets

- **turf**: turf and sand materials: fairway, rough, fringe, green, tee, bunker. HQ within 40 yards of the camera, LQ beyond.
- **Anything else:** infer the scope from the code. State your assumption in your first update and keep going.

## Working method

- **Metrics and tooling:** same as `/optimize-perf`. The game's performance monitor (click the FPS graph) already captures extensive metrics; use what's reachable from the console, and add a console API if something is only visible in the menu. Use the repo's existing camera, gameplay and view tooling rather than building parallel versions.
- **User updates and fast iteration:** if `visual-debug-loop` is available, follow its "Keep the user in the loop" and "Phase 0" sections.
- **Know what AAA looks like:** compare against real references (real photos, and how shipped Unreal-class games render the same thing at the same distances) rather than your memory of them. `reference-driven-visual-fix` covers fetching and measuring photos if it's available. User-supplied references outrank anything you find.
- **Baseline first:** record close-up captures and frame time before changing anything, then keep what measurably helps.
- **Check fidelity close up:** zoom into crops at close range, at the HQ/LQ boundary and at distance, and check in motion for shimmer and pop. Full-frame screenshots hide the problems that separate AAA from not (tiling, aliasing, flat lighting, seams).
- **Don't grade your own work alone:** if subagents are available, show one the before/after crops unlabeled, with the references, and ask which is closer to AAA.

Any visible downgrade elsewhere (another feature, another distance) needs the user's explicit OK.

## Report

Keep it short:

- what changed and why it reads as more AAA
- average fps and frame time, before → after, with the settings you used
- before/after crops next to the references
- anything you didn't verify

If the target still falls short of AAA or of 120 fps, say what's left and what you'd try next.