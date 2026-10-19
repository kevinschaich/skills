---
name: fmk
description: Fuck-marry-kill — find the right answer to anything by elimination. Show 3–8 concrete options per round; the user kills the worst (one word why), marries a base, steals one trait. Start with huge, sprawling swings at the whole thing, then narrow round by round to finer dimensions until they'd put their name on it. Works for design, writing, naming, architecture, APIs, strategy, plans — anything taste-driven. Use for "/fmk", "fuck marry kill", or when the user wants to decide by gut reaction instead of specs.
---

# /fmk

Evolution, not specification. People can't describe what they want, but they know bad when they see it. Show them things, kill what they hate, breed what survives, and learn their taste from the corpses.

## The shape: sprawl, then narrow

Every run moves from wide to narrow:

1. **Sprawl.** The first rounds are huge swings at the *whole* thing — radically different answers to what was asked, not variations of one idea. Different premises, structures, metaphors, tones. If two options could be mistaken for each other, one is wasted.
2. **Narrow.** Once a direction survives, each round zooms in: fewer options, closer together, focused on one dimension at a time. Each round should feel more specific than the last.
3. **Polish.** The last rounds are fine detail on the frozen whole — the things you can't judge until everything else is settled.

Freeze a dimension when the options stop changing much (usually after 3–5 rounds), then move to the next, finer one. Stop when the user would put their name on it.

## Round 0 — pick the dimensions

From the request, list the ~5 dimensions that actually matter, ordered from biggest to finest, as one quick widget. The user picks what matters most and kills what they don't care about; you order the rest so that what constrains comes first. Examples of a wide-to-narrow ladder:

- **Design**: concept → layout → color and type → spacing and proportions → details
- **Writing**: angle → structure → voice → lines → word choice
- **Naming**: territory → name → how it's written
- **Architecture / systems**: overall shape → where state lives → key flows → interfaces
- **Plan / strategy**: bet → sequence → scope cuts → first step

Skip anything already decided (existing specs, a design system, `taste.md`). Don't run a full round in round 0. **Skip round 0 entirely for small things** (a tweet, a name, a single screen) — go straight to sprawling the whole thing and let the narrowing find the dimensions.

## A round

1. **Show, never describe.** Each option is the thing itself, as concrete as it can be: a rendered mockup, the actual paragraph, the name in context, the command and its output. For abstract things (architecture, strategy), one picture and one plain sentence per option: an everyday metaphor and what the user would *notice* living with it. No jargon, no code traces — mechanism goes in the decision log after the freeze.
2. **Options differ on something the user cares about.** Never build a round out of a parameter (how often, which number, which threshold) — pick a sensible value, say it in one line, move on.
3. **One card per option, judged and voted in the same place.** Build the round from `widget-template.html` in this skill's folder: each card holds the full option at a size where it can actually be judged, with F/M/K right under it. Never put options in one place and the vote in another. Never rebuild the widget's controls with innerHTML after load — static markup, one delegated listener.
4. **Show only what's being judged.** Anything extra gets a visible label or stays out. Never quietly alter an option inside its own card.
5. Per option, guess 2–4 likely kill reasons and 1–3 stealable traits as chips, so most answers are taps.
6. One header line above the widget: what died last round (in their words) and what this round changes. Label invented content as placeholder.

### Reading the answer

Format: `K:B cluttered, C boring · M:A · F:D red band`. Also accept loose shorthand (`kb cluttered mc fa sidebar`, or a bare `b cluttered` = kill).

- **Kill** is required; several at once is fine. A kill with no reason is a valid "nah" — don't nag.
- **Marry** is optional. If absent, pick the strongest survivor and say which in one line.
- **Fuck** splices a trait into the next round. A steal can also be a constraint ("2 colors", "no jargon") — apply it to every option next round. "Want to know more" means explore that trait across the whole next round.
- `freeze X` locks the dimension. If only one rival is left and the user marries the other, that's a freeze too — say so (reopenable).
- If a kill word is ambiguous, ask once, one line, at the end of the next message.

## Freezing

Write one short entry to `fmk-log.md` next to the work (or the project's spec): what won, its concrete specifics, and **why it won, derived from the kill reasons**. Then record durable preferences — not project-specific choices — in the taste profile.

A frozen dimension can be reopened if a later one keeps fighting it. Say so and offer.

## Taste profile

Taste lives **outside** the skill, so it keeps growing:

- If `~/.claude/taste.md` is reachable, read it at the start of every run, bias the first round with it, and append to it on each freeze.
- Otherwise use whatever persistent memory the host offers. If there is none, say so plainly, and put the new taste lines in the Wrapped card for the user to keep. Never claim something was saved when it wasn't.
- Taste fades: a line no kill has confirmed in ~5 runs gets marked `(fading)`, then dropped.

## Finish

After the last freeze, make the real thing (the page, the doc, the file, the plan) and check it yourself before showing it. Then end the run with a **Taste Wrapped** card in the work's own look: rounds, freezes, top kill words with counts, what always survived, fastest freeze. Only real counts — never invented stats.

## Voice

Blunt, specific, curse when it's natural. Funny comes from honest specifics, never from bits or puns. Every message: what died, what's next, the widget. The widget does the talking.
