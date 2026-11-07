---
name: polish
description: Polish an app or interface until it is genuinely good, against the best products in its category: references first, every state seeded, every page and overlay screenshotted in both themes and at several sizes, critiqued against a fixed checklist, fixed and re-shot until a round finds nothing. Works unattended and answers "are you proud of it?" honestly. Use for "/polish", "do a polish pass", "make it feel native / pro / like Final Cut", "fine-toothed comb", or whenever the user wants UI they'd pay for, not UI that merely works.
---

# Polish

The user wants an interface that would hold up next to the best product in its category, and they will judge it the way a buyer does: every element, every page, every state, at a glance. The usual failure is a single redesign pass, one screenshot per page, a confident summary, and a "want me to fix these?". Then the user has to ask five more times before the real work happens. This skill is that real work, done in one go.

**Work unattended.** Once invoked, do not stop to offer, ask "want me to…?", or report issues you have not fixed. Find, fix and re-check, round after round, until a full round turns up nothing. Stop only for a decision that is genuinely the user's: product scope, a destructive change, or taste with no reference to settle it. The user follows your progress through short checkpoints, not questions.

**Be honest about the bar.** At the end, and whenever asked "are you proud of it?", answer from the evidence: what you looked at, what is still unverified, and what separates it from the reference products. Never claim parity you cannot show. If it is not there yet and the remaining gap is polish, keep going. If the gap is features or user testing, say exactly that.

## 1. Set the bar with references (show them)

- Name the two or three best products in the category (e.g. Final Cut Pro, DaVinci Resolve, Premiere Pro for a video editor; Linear, Things, Figma for productivity; the platform's own apps for anything "native").
- Find real screenshots: web image search (e.g. firecrawl search with `sources: ["images"]`), the vendor's own docs, review sites. Download 3–6 into a scratch folder, look at each, and **send them to the user** (SendUserFile, or an inline link) with one line on what they share.
- Write down the conventions they share before touching code, per area: layout and navigation, headers and toolbars, lists and rows, the core object (e.g. a timeline clip), selection, status, empty states, motion, icons, typography, density. These become your targets.

## 2. Make every state visible

You cannot polish what you cannot see. Before critiquing:

- **Run the real UI with its real theme.** If it renders inside a host (an app frame, an Electron shell, an MCP Apps host), build or reuse a small stand-in that serves the real page with the host's real styling (its CSS variables, fonts, light and dark), and that stubs the host's background services so nothing mutates your test data. Never judge colours that are only fallbacks.
- **Seed one item in every state** the user can meet: empty / brand new, ready to start, in progress (each stage), partly failed, waiting, running, done, failed (each kind), stopped, and any special kind (samples, imports). Use real-looking content (titles, text, pictures, audio), never "test 1". Make the done state have a real artifact (file, video, export).
- **List the matrix** you will look at: every page/tab × every seeded state, plus every overlay (popovers, dialogs, modals, toasts, tooltips, menus), in **dark and light**, at **three sizes** (small laptop, typical, large). Keep a checklist and tick it off.

Pitfalls that cost rounds:
- Your stand-in must serve the **latest** code (sync after every edit) and keep the seeded states (a server restart may reset "running" items: restore them).
- Screenshots of hidden or background tabs can be stale or mid-animation; if something looks faded or half-drawn, re-shoot before "fixing" it, and check computed styles.
- Edit scripts that abort halfway leave earlier edits unapplied: after a failed edit, re-check that each intended change is really in the file.

## 3. Critique against the checklist

For each screenshot, zoom in and go through this list. Write every finding down; fix them all.

**Truth and state**
- Does every status say what is actually happening? No spinner, "Loading…", "Planning…" or progress when nothing runs; no stale picture or data from a previous item.
- Is the one thing the user should do next obvious, and placed where they look (the primary action), with everything else behind a disclosure, popover or menu?
- Do problems lead where the user works (the main page), not only in a side detail?
- Is what is selected or current unmistakable everywhere (item, page, tab, row)? Does a choice the user makes stick, even while something loads?
- Empty states: an icon or picture plus one useful line, never a black box, a blank pane, a fake duration or live-looking controls with nothing to control.

**Feedback patterns** (use the right one)
- Toast for passing status (and errors that stay until dismissed); tooltip for a word or two and keyboard shortcuts; popover for detail on demand; dialog for a blocking question (destructive actions confirm, with a strong destructive button); modal for a separate window. A slow action opens its window at once and fills it.

**Content and copy**
- No raw codes, selectors, stack traces or JSON in the UI: translate to a sentence, keep the raw text in a hover or details.
- No duplicated messages or buttons on the same screen. No boilerplate that buries the useful part.
- Numbers formatted for people (durations in minutes past a minute, sizes in MB, dates localized). Sentence case, consistent capitalization, the domain's own vocabulary (e.g. an editor's "clip", not "frame").

**Craft**
- Icons from one real icon set (the product's own, or e.g. Lucide), never hand-drawn paths.
- The core object looks like the reference category's (e.g. clips flush with hairline seams, picture filling, name strip, bright selection outline), not a generic web card.
- One type scale, consistent spacing, aligned edges, no clipped or overlapping text, long titles truncate gracefully.
- Contrast holds in both themes; semi-transparent theme surfaces have a solid base under them.
- Motion: page and panel changes slide or fade; state changes transition. That means updating elements in place instead of redrawing, so there is something to animate from. Respect reduced motion. No expensive effects (e.g. backdrop blur over live video).
- Keyboard: the category's standard shortcuts work and are shown in tooltips.

**Health**
- No console errors in any state; no request loops or polling for things that cannot exist; nothing that freezes input.

## 4. Fix, re-shoot, repeat

- Fix everything a round found, then re-shoot the same matrix (not just the screens you touched).
- Repeat until a full round finds nothing. Then do one more round only against the references side by side: what does the reference do that this still does not? Fix what is polish; list what is a feature.
- Run the project's own checks and tests after each round; keep them green.

## 5. Checkpoints (keep the user in the loop without asking)

Post 2–4 lines at each: references found (with the images), states seeded, each round's findings and fixes, done. Lead with a status word: `Referencing`, `Seeding`, `Round N`, `Fixed`, `Verifying`, `Done`. Silence for more than ~15 tool calls is a bug.

## 6. Finish honestly

Report: what changed (grouped by area), what you looked at (states × pages × overlays × themes × sizes), what is still unverified (e.g. never seen inside the real host, never used by someone else), and the remaining gap to the references, split into polish you would keep doing and features or decisions that are the user's. Ship it the way the project ships (commit, PR) if that is how the user works.
