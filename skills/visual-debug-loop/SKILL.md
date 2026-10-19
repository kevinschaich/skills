---
name: "visual-debug-loop"
description: "Debug visual/rendering problems (shaders, WebGPU/WebGL, games, canvas, CSS, charts) by building tools to see, measure and hot-reload them before fixing. Use whenever the user says something looks wrong on screen."
---

# Visual debug loop

When a user describes something that looks wrong on screen, they're describing a perception you can't directly see. The usual failure is to guess at the cause, tweak a constant, glance at one screenshot, and declare it fixed. The user then refreshes and it looks about 5% different. This skill replaces that with a loop: make the problem **visible and measurable** to you, then fix it against that measurement.

The core idea: **spend effort on instruments before spending effort on fixes.** A good debug view or metric usually makes the fix obvious, and it lets you prove the fix worked.

## Keep the user in the loop (applies to every phase)

This loop can run for a long time, and from the outside a silent agent looks identical whether it is lost, building tooling, or re-verifying a fix it already has. The user can't redirect you if they can't see which of those is happening. So narrate the loop as you go, not just at the end. If a message tool that shows text to the user verbatim is available (e.g. `SendUserMessage`), use it for these updates; otherwise write them as short plain text between steps.

**Post a checkpoint at each of these moments** (2–5 lines, no essays):

1. **Reproduced (or couldn't).** What you captured, the view/pose, and the concrete visual claim you're now testing. Attach or link the capture if you can.
2. **Instrument ready.** What the debug view/metric shows and the baseline number (e.g. "flash count at pose A: 484").
3. **Each hypothesis tested.** One line per hypothesis: `H2: shadow term aliasing → toggled shadows off → flashes 484→470. Not it, reverting.` This is the most important update: it shows whether you're converging.
4. **Root cause found.** What it is, the evidence, and your confidence (low/med/high).
5. **Fix applied.** The change and the metric before → after.
6. **Verification plan and progress.** Which extra views/settings you'll check and roughly how many, then the result.

Also post an update whenever you've gone ~10 minutes or ~15 tool calls without one, even if it's just "still fighting the tooling: headless WebGPU crashes, switching to the browser integration." Silence is the thing to avoid.

Lead every update with a status word so it's legible at a glance: `Exploring` (no confirmed cause yet), `Cause found`, `Fixing`, `Verifying`, `Blocked`. A good update answers "do you know what's wrong yet, and what are you doing right now?"

### Know when you're stuck, and when you're done

- **Stuck:** if three hypotheses in a row don't move the metric, stop and tell the user. Summarize what you've ruled out, what you suspect next, and ask whether they have a hunch or a reference. Their eyes on the actual screen are cheap information you don't have.
- **Done verifying:** verification has a budget. Decide the verification set up front (Phase 4) and stop when it passes. Don't keep re-capturing the same pose, or inventing new edge cases one at a time, after the metric has hit its target on the planned views. If you think more checking is worth it, say so and let the user choose ("Fix holds on 3 views. I can also test in motion at dusk, ~5 min, or hand it to you now"). A verified fix with a clear list of what wasn't checked beats silent over-testing.

## Phase 0 — Make iteration cheap (do this first)

You will test dozens of hypotheses, so every test has to cost seconds, not the full app startup.

- **Measure the startup first.** Instrument the load with timestamps (marks at each stage, plus resource timings) before optimizing. Find where the time actually goes. It is often an animation, repeated rebuilds, or main-thread work, not the network.
- **Build a fast path.** Cache expensive loaded or derived state client-side (e.g. IndexedDB for built data, Cache Storage for network). Add a dev toggle that skips intros and animations and lands straight in the scene. When on, show a progress list of what's really being waited on, with timings.
- **Build a reload button that reloads *everything*.** It should save the current camera/view state, reload all code (page, workers, shaders) through the fast path, and restore the exact view. Optionally add a faster partial swap for the renderer-only modules, e.g. re-import modules with rewritten relative imports as blob URLs. Label clearly what each mode does and doesn't reload. A partial reload that silently misses the code you changed is worse than none.
- **Expose a scripting hook** (e.g. `window.__look(eye, target)`, `window.__reload()`, a frame-capture function) so you can drive the view and capture frames from the browser automation tool without the user touching anything.
- **Use the user's already-running app/browser.** Don't ask them to open windows or manage your tooling. If a headless setup can't render the real thing (e.g. software WebGPU crashes), stop fighting it and use the browser integration against their dev server.

Phase 0 is where agents most often go quiet for a long time. Tell the user when you start it and roughly what you're building, so they know the quiet stretch is tooling, not confusion. If the app is already fast to iterate on, say so and skip ahead.

## Phase 1 — Reproduce and see it

1. Restate the complaint as a concrete, checkable visual claim. For example: "at 30–100 m, individual grass blades read as pale 1–2 px lines on a darker ground." Share this restatement with the user: if you've misunderstood the complaint, this is the cheapest moment to find out.
2. Reproduce the user's exact view (camera, time of day, settings) with your hook. Capture it at native resolution and zoom into the problem region. Compare against any reference image the user gave.
3. If the problem is temporal (flicker, sparkle, shimmer, popping), a still screenshot can't show it. Capture a **frame sequence** while moving the camera in small steps, e.g. a scripted drone flyover.

## Phase 2 — Build instruments that isolate the cause

Be creative. The goal is a view or number where the problem is unmistakable. Ideas:

- **False-color debug modes.** Tint each layer a distinct flat color, e.g. terrain red and grass blades blue. Visible red then means ground showing through. Purple means the layers blend. Mismatched brightness shows up at a glance.
- **Isolate terms.** Output a single shading term (albedo only, diffuse only, specular only, shadow factor, AO, fog, normals) or zero it out. Bisect by toggling terms until the artifact disappears.
- **Distance/LOD bands.** Color by distance ring, LOD level, mip level, or pixel-coverage (e.g. blade width in pixels) to see where a transition or sub-pixel aliasing happens.
- **Numeric metrics from pixels.** Read the canvas into an offscreen 2D canvas and compute things like:
  - flashes: pixels much brighter than the max of their 5×5 neighborhood in the previous and next frames
  - mean color and variance per region: does layer A's average match layer B's?
  - count of pixels above a luminance threshold, or edge contrast in a band
  Log the count per test, so "fixed" means the number went from 484 to 0, not "looks better to me."
- **Side-by-side / A–B captures** of before and after at identical camera poses.
- **Reference comparison.** Sample colors from the user's real-world reference photo and compare against the rendered averages.

Prefer debug modes that can be toggled at runtime (a uniform or debug flag) over temporary code edits. If you do edit code temporarily, revert it and verify the revert.

Keep a running hypothesis log and surface each entry to the user as you test it, per the checkpoint list above.

## Phase 3 — Plan, then fix in small steps

1. Write a short plan: the observed symptom, the measured evidence, the root cause hypothesis, the fix, and how you'll verify it with your instrument. Post this plan to the user before editing; it doubles as the "Cause found" checkpoint.
2. Change one thing at a time. After each change: hot reload, re-run the same capture and metric, and compare against the previous numbers and images.
3. If a change doesn't move the metric, revert it rather than stacking guesses.
4. Check the fix doesn't regress what the user said already looked good. Re-capture those views too.

## Phase 4 — Verify like the user will

- Before verifying, name the verification set: the exact reproduction view, the motion sequence (if temporal), plus two or three other views, times of day or settings, since fixes often only hold for the tested pose. Tell the user this list. That's the budget; finishing it means you're done.
- Run the project's tests.
- Report with evidence: the metric before and after, and the images you looked at. Be explicit about what you verified and what you didn't. "Stills only; I did not verify in motion" is a useful thing to tell the user.

## Anti-patterns to avoid

- Declaring victory from one still frame, or from reasoning about the shader, without looking.
- The opposite: re-verifying a fix that already passed its planned checks, or expanding the test set one case at a time without telling the user.
- Working silently for long stretches. The user can't tell "lost" from "thorough" without updates.
- Tweaking magnitudes (0.25 → 0.1) when the term is conceptually wrong at that scale. At sub-pixel sizes, high-exponent speculars and thin bright details alias no matter the multiplier. Fade or prefilter them.
- Long blind waits and repeated failing tool calls. If the tooling is fighting you, fix the tooling or switch approach, keep individual test calls short, and say what's happening.
- Leaving debug tints, temp archives or instrumentation clutter in the user's project without saying so.

## Cleanup

- If the tools you built to discover this one time thing are disposable/extremely nuanced, remove them from the code base to avoid clutter.
- If the tools you built are helpful for future diagnoses and extensible, give them a helpful name and build them into a "visual debug" menu in the bottom left panel of tools that you can easily access in the future.