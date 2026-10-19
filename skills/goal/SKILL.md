---
name: "goal"
description: "Cowork's version of Claude Code's /goal. Turns a batch of prompts or a stated outcome into a checklist of goals and works through them in this chat, without stopping to check in, until each one is verified. Use for \"/goal [condition]\", \"/goal\", \"/goal clear\", \"loop until all N are done\", \"keep going until X\", \"don't stop until\", or any batch of prompts to finish unattended."
---

# /goal

Claude Code's `/goal` doesn't let Claude end its turn until a condition is verified. This skill does the same here in the **main chat**, working the usual way: one checklist of goals, worked through in order, with no extra agents unless they're truly worth it.

The user gave these prompts so they wouldn't have to babysit. Stopping after one goal to ask "want me to do the next?" is the exact failure this skill exists to prevent. Only pause for something irreversible the user didn't ask for.

## Commands
- `/goal <condition>`, "loop until…", or a batch of prompts → **set** (below).
- `/goal` alone → **status**: open, done and blocked goals, from the checklist and `.goal/goals.md`.
- `/goal clear` (or `stop`/`off`/`reset`/`cancel`) → delete the pending watchdog, mark the remaining goals cancelled, reply `Goal cleared.`

## Set
1. **One checklist item per goal.** Each prompt the user gave is one goal, in the order given. A single outcome is one goal. Load the task tools once (`ToolSearch "select:TaskCreate,TaskUpdate,TaskList"`) and `TaskCreate` every goal up front, so the full list shows in the side panel. Give each goal a **done-when check** that can be proven, like a command that exits 0, a file that exists, or a screenshot inspected up close. Use the user's wording, and don't widen the scope.
2. **Write `.goal/goals.md`**: the user's prompts word for word, each goal's check, and its status. Long sessions get compacted, and this file is how you pick up exactly where you left off.
3. **Lock the yardstick.** If tests, checkers, specs or fixtures decide "done", fingerprint them:
   `sha256sum FILES > .goal/fingerprint.sha256`.
   Never edit them, skip them, special-case their inputs or copy their answers. Before marking any goal done, run `sha256sum -c --quiet .goal/fingerprint.sha256`.
4. Say one line, `Goal set: N goals.`, and start goal 1 right away.

## Work loop (the Stop hook)
For each goal, in order:
1. Mark it `in_progress` and do the work the usual way.
2. **Verify it yourself:** run the check, look at the output, run the tamper check.
   - Passes: mark it `completed`, update `goals.md`, and move to the next goal **in the same turn**.
   - Fails: keep fixing. Hard is not impossible.
   - **Blocked:** only when the requirements provably contradict each other, or something outside your control is missing. Quote the conflict, mark it `blocked` in `goals.md`, rename its task `BLOCKED: <goal>` with the reason and mark it `completed` (so the checklist shows nothing left to work on), then move on. One blocked goal must never stop the rest.

**Done and blocked are both final.** The loop ends when every goal is done, blocked or cancelled. A blocked goal is not an open goal: it can't be finished by trying again, only by the user's decision, so it must never keep the loop (or the watchdog) alive.

**The watchdog (arm it at the start, not the end).** Right after `Goal set`, call `send_later` (ToolSearch it first) with `delay_minutes: 1`, `name: "Goal: continue"` and this message: *"Goal check: read .goal/goals.md. If any goal is pending or in progress, re-arm this watchdog and continue with it without asking the user anything. Blocked goals are final, not open. If nothing is pending or in progress, delete any pending 'Goal: continue' watchdogs and end the turn with at most one line; do not repeat the report."* Save its `trigger_id` in `goals.md`, replacing the previous one, so it always holds the newest.
- It **waits while you're working** and is only delivered once your turn ends. So a watchdog that's always pending doesn't disturb work in progress, and it catches any early stop within about a minute.
- **Every time it wakes you,** read `goals.md` first. If a goal is pending or in progress, arm a new watchdog, then continue. If not, don't re-arm.
- **Delete it** when you finish or clear: `list_triggers` and delete every pending `Goal: continue`, not only the saved ID, since a re-arm can leave a spare behind.
- **A wake with nothing open** (a stray watchdog, or a stop hook you don't control) gets one line at most, e.g. `No change: goal N still blocked (needs your call on <decision>). /goal clear to end.` Never resend the report, never recount it, and never reopen a blocked goal just because you were woken. Re-sending the same report on every wake is noise that buries the one decision the user has to make.

You arm it up front because "stopping to ask" is the failure it exists to catch. Relying on remembering to arm it right before stopping would fail in exactly that moment.

## Parallel: only when it's truly safe
The default is **sequential**. Run goals in parallel only if **all** of these hold:
- They touch **separate files**. Where it's a git repo, each one gets `isolation: "worktree"` and is merged back after, so no agent overwrites another's work.
- **Nothing is CPU/GPU-heavy on the user's computer.** Builds, renders, fps or benchmark runs and big test suites stay strictly one at a time. Parallel runs would slow each other down and ruin any performance measurement.
- Each goal is big enough that a new agent is worth it. A fresh agent costs about 50k+ tokens before it does anything.

When those hold, send the independent goals to `Agent` calls in one message. Verify each result yourself when it comes back, then tick its item.

## Finish
Once every goal is done or blocked: run the tamper check one last time, delete every pending watchdog (confirm with `list_triggers`), and only then send **one** summary. List each goal on one line with its status and proof. Then list the blocked goals, with their quoted conflict and the decision the user would need to make. That summary is the end of the loop: when the user answers a blocked goal's decision, treat it as a new `/goal` for that one goal.