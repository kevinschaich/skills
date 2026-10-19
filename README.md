# skills

A collection of agent skills I use with Claude for making decisions, finishing long batches of work, and getting games and visuals to look right.

## Skills for deciding and finishing work

- [**fmk**](skills/fmk/SKILL.md): Fuck-marry-kill. Finds the right answer to anything **by elimination**: each round shows 3–8 concrete options, you **kill** the worst, **marry** a base and **steal** one trait, narrowing until you'd put your name on it. User-invoked.
- [**goal**](skills/goal/SKILL.md): Turns a **batch of prompts** or a stated outcome into a **checklist of goals** and works through them without stopping to check in, until **each one is verified**. User-invoked.
- [**spec-audit-loop**](skills/spec-audit-loop/SKILL.md): Builds **numbered steps** from a source spec or proposal, then runs **strict audit-and-fix loops** until every item in the document is met.

## Skills for games and visuals

- [**optimize-perf**](skills/optimize-perf/SKILL.md): Makes one rendering feature of a real-time game (**turf**, **sand**, **trees**, **water**, **shadows**) run at **120 fps** while matching AAA visual quality. User-invoked.
- [**optimize-fidelity**](skills/optimize-fidelity/SKILL.md): Raises one rendering feature of a real-time game to **AAA / Unreal Engine visual quality** while **holding 120 fps**. User-invoked.
- [**visual-debug-loop**](skills/visual-debug-loop/SKILL.md): Debugs visual problems in **shaders**, **WebGPU/WebGL**, **games**, **canvas**, **CSS** and **charts** by building tools to **see**, **measure** and **hot-reload** them before fixing.
- [**reference-driven-visual-fix**](skills/reference-driven-visual-fix/SKILL.md): Makes something look more like the real thing by pulling **5–10 Unsplash reference photos**, **measuring targets** from them and fixing against those numbers.

## Skills for finding images

- [**unsplash**](skills/unsplash/SKILL.md): Downloads **full-resolution**, **free-license** photos from Unsplash for a search term via the official API, with **photographer credits**. Needs an Unsplash Access Key.
- [**google-images**](skills/google-images/SKILL.md): Finds and downloads 5–10 original **4K+ images** (long edge ≥3840px) from a Google Images search.

## Install

```bash
npx skills add kevinschaich/skills
```

## Claude Code plugin

```text
/plugin marketplace add kevinschaich/skills
/plugin install kevinschaich-skills@kevinschaich-skills
```
