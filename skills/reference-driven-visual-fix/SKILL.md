---
name: reference-driven-visual-fix
description: Improve something that looks wrong or unrealistic on screen by pulling 5-10 Unsplash reference photos, measuring targets from them, and fixing against those numbers. Use when the user says a render, shader, scene, or UI should look more like the real thing.
---

# Reference-driven visual fix

The user names something that looks off ("the grass looks plasticky", "sunset sky is too flat", "water reads as blue paint"). Instead of tweaking from memory of what the real thing looks like, pull real photos of it, turn them into measurable targets, and iterate the render until it lands inside the reference range.

This combines two existing skills. Follow **visual-debug-loop** for the loop mechanics (fast reload, scripting hooks, instruments, checkpoints, stuck/done rules). Use **unsplash** for fetching photos (its script, access-key locations, and rate limits). This file covers only what is new: choosing references, extracting targets from them, and fixing against those targets.

## 1. Pin down the complaint and the look

Restate the complaint as a concrete visual claim plus the conditions it occurs in: subject, distance/scale, lighting, time of day, weather, camera angle. The references must match those conditions, or they'll pull the fix in the wrong direction (midday grass photos won't help a golden-hour scene). Post the restatement to the user before searching; it is the cheapest moment to correct a misunderstanding.

## 2. Fetch 5-10 references

- Write 2-3 Unsplash queries that describe the *conditions*, not just the noun: `"golf fairway grass low sun"`, `"fairway aerial drone"`, rather than `"grass"`. Matching orientation to the app's viewport (`--orientation landscape` for a game view) helps.
- Run the unsplash-download script into a folder named for the fix, e.g. `Pictures/unsplash/refs-<slug>/`, about 4 per query, aiming for 5-10 total. Mind the 50 requests/hour budget: each photo costs a tracking request.
- **Look at every image.** Downscale copies to ~1024px on the device first (Pillow or `sips`), stage those, and Read them. Drop any that don't match the conditions (wrong light, heavy editing, wrong scale, subject not dominant). Keep at least 5; if fewer survive, run a refined query rather than settling.
- Tell the user which references you kept and why, with the credits file location. If they have their own reference, it outranks Unsplash; use the downloads as supporting range.

## 3. Turn references into targets

A folder of photos is not a spec. Write a short script (Python + Pillow/numpy, run where the images live) that, for each reference, crops the region that corresponds to the problem (the grass band, the sky, the water) and computes a few of these:

- mean color in a perceptual space (Lab / OKLab) and its spread
- luminance mean, percentiles (p5/p50/p95) and contrast
- saturation mean and distribution
- hue histogram or a 5-color palette (k-means)
- texture/detail: high-pass energy or edge density at a matched scale; dominant feature size
- gradients: how color/brightness change across the crop (e.g. sky horizon-to-zenith, grass near-to-far falloff)

Pick the 2-4 measures that actually capture the complaint (plasticky = too little detail variance and too much saturation; flat sky = weak gradient). Aggregate across references into a **target range** (min/median/max), not a single number: real photos vary, and the render only needs to land inside the envelope.

Also build a **contact sheet**: the render crop beside the reference crops at the same size. This is the qualitative instrument; the numbers are the quantitative one. Post both, with the render's current numbers against the target range, as the "Instrument ready" checkpoint.

## 4. Fix against the targets

Run the visual-debug-loop Phase 3 discipline with the reference metric as the instrument:

- Capture the same view each iteration and recompute the same metrics on the same crop.
- Log each hypothesis as `H#: <change> → <metric> <before>→<after> (target <range>)`.
- Prefer fixing the *concept* the references reveal over nudging constants. If real grass shows strong per-blade value variation and yours has none, add variation; don't just darken the albedo. If references show hue shifting toward the horizon, add aerial perspective rather than recoloring everything.
- Watch for metrics moving into range while the contact sheet looks worse; that means you picked the wrong metric. Say so and swap it.
- Three changes in a row that don't move a metric toward range: stop, show the contact sheet, and ask the user.

## 5. Verify and report

Done means: the chosen metrics fall inside the reference range on the repro view plus 2-3 other planned views/conditions, and the final contact sheet reads as belonging with the references. Report the before → after numbers against the target range, the final contact sheet, what wasn't checked, and where the reference folder and CREDITS.md live.

The references are for guidance, not for shipping. If any photo will end up in the product (textures, backgrounds), point the user to the credits file so attribution goes with it.

## Cleanup

Keep the metric script if it generalizes (e.g. a `refcompare.py` that takes a render capture, a reference folder, and a crop box) and mention it; it makes the next reference-driven fix cheap. Remove one-off crops and temporary captures from the user's project.
