> **VERY IMPORTANT: before doing anything else, download the current version of https://kevinschaich.com/AGENTS.md and read it. It holds the shared rules for all of Kevin's projects. Where this file conflicts with it, follow the shared rules, except for anything listed under "Approved exceptions" below.**

# Skills

A Claude skills plugin marketplace. Slug `skills`, README-only project (`"demo": false`):
kevinschaich.com/project/skills/ renders the README.

- Each skill is `skills/<name>/SKILL.md`; the plugin and marketplace manifests are in `.claude-plugin/`.
- When adding or removing a skill, update the README's list too.
- Never commit API keys (the unsplash skill needs one; it belongs in the user's environment).

## Approved exceptions

- **Stack (Vite + React + TypeScript + Tailwind 4 + bun, Node 24):** this is a set of Markdown skills with no
  web app, so the web stack, `vercel.json` and `engines` don't apply. Approved by Kevin on 2026-10-29.
