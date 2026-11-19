---
name: install-on-claude
description: Install and configure an MCP server, connector or plugin in every Claude on this Mac, end to end — Claude Code and the app's Code tab, the Claude app signed in to claude.ai (Chat, Cowork), and the Claude app on third-party inference (Bedrock, Vertex, Foundry, a gateway) with its managed-configuration rules. Automates everything it can (config files, keychain token, helper script), verifies it, and only as a last resort gives exact menu-by-menu steps. Use for "/install-on-claude", "add this MCP server to Claude", "install this plugin", "set up X in Claude Desktop / Cowork / Claude Code", "why doesn't my MCP server show up", or "it works in Claude Code but not in the app".
---

# /install-on-claude

Get one MCP server or plugin working in **every Claude on this Mac**, with the person doing as little as possible. Do the work yourself, verify it, and stop only for what truly needs their hands (a restart, a browser sign-in, an administrator).

A Mac can hold three different Claudes, each reading a different file, and what works in one is silently ignored by another. Most "it doesn't show up" problems are a server added to the wrong one.

## Rules

- **Never print, log or ask for a secret in chat.** Tokens go in the login keychain; config files hold a path to a helper script, not the token. If the person must supply a token, they type it into Terminal (hidden) or the service's own page.
- **Read before you write.** Keep everything else in a config file. Every edit leaves a copy from before beside it.
- **Automate, then verify, then report.** Try the automatic path even when unsure; a failed attempt costs seconds. Give manual steps only for the part that failed.
- **Manual steps are numbered, one action each**, with the exact menu names and the exact value to type.
- You cannot restart the app you are running in. Finish everything else, then ask for one restart.

## 1. Find out what is being installed

Ask only what you cannot find out (a README, the service's docs, `claude mcp list`).

| It is | You need |
|---|---|
| A **remote** server (a URL) | The URL of its MCP endpoint; whether it signs in with OAuth, a fixed token/API key, or nothing; whether the address is public or private (a tailnet, a VPN, localhost) |
| A **local** server (a command) | The full path of the program and its arguments; any environment variables; what it must be installed with (Node, Python, a binary) |
| A **plugin** | Its marketplace (a GitHub `owner/repo` or a URL) and its name; whether it brings MCP servers of its own |
| A **desktop extension** (`.mcpb`) | The file. Only the claude.ai app installs these (Settings → Extensions, drag the file in) |

## 2. Find out which Claudes are here

Run `uname`. On `Darwin`, run the script beside this file: `claude-mcp.sh detect`. On `Linux` you are in Cowork's sandbox, which cannot change the Mac: use any tool you have that runs on the Mac itself, else give the person one line to paste into Terminal (Cmd+Space, "Terminal", Return) and ask for its output.

### Where each Claude keeps things (macOS)

| | Claude Code + the Code tab (claude.ai sign-in) | Claude app, claude.ai sign-in (Chat, Cowork) | Claude app, third-party inference ("3P": Chat, Cowork and Code) |
|---|---|---|---|
| **How to tell** | `claude` on the PATH (often `~/.local/bin/claude`) | `~/Library/Application Support/Claude/` exists | `~/Library/Application Support/Claude-3p/` exists; its `claude_desktop_config.json` has `"deploymentMode": "3p"`; model ids look like `us.anthropic.…` |
| **MCP servers live in** | `~/.claude.json` → `mcpServers` (user scope, every project). A project's own: `.mcp.json` at its root | `~/Library/Application Support/Claude/claude_desktop_config.json` → `mcpServers` | `~/Library/Application Support/Claude-3p/configLibrary/<appliedId>.json` → `managedMcpServers`. `<appliedId>` is in `configLibrary/_meta.json` |
| **Kinds it takes** | Local commands, and remote `http`/`sse`/`ws` with `headers` or `headersHelper` | **Local commands only.** A remote server is either a custom connector (Customize → Connectors → Add → Add custom connector), which connects **from Anthropic's cloud** and so cannot reach a private address, or a local bridge | Remote `http`/`sse` and local `stdio`, **only from this list**. Servers a person adds in `~/.claude.json`, `.mcp.json` or `claude_desktop_config.json` are ignored, in the Code tab too |
| **Entry** | `"name": {"type":"http","url":"…","headersHelper":"/full/path"}` or `"name": {"command":"/full/path","args":[…],"env":{…}}` | `"name": {"command":"/full/path","args":[…],"env":{…}}` | `{"name":"Name","transport":"http","url":"https://…","headersHelper":"/full/path"}` or `{"name":"Name","transport":"stdio","command":"/full/path","args":[…]}`. It reads `transport`, never `type`; an entry without it is dropped |
| **Credentials** | `headersHelper` (a script printing `{"Authorization":"Bearer …"}`), or OAuth in the browser (`/mcp`) | In the bridge or the server's own `env` | `headersHelper` only: static `headers` are for routing, not credentials. OAuth: `"oauth": true` (auto-register) and the person clicks Connect under Customize → Connectors. Local: `env`, or `envHelper` printing a JSON object |
| **Other settings** | `~/.claude/settings.json`: `permissions.allow` (e.g. `"mcp__name__*"`), `enabledPlugins`, `extraKnownMarketplaces`. Skills: `~/.claude/skills/<name>/SKILL.md` | Extensions: Settings → Extensions. Developer list: Settings → Developer | Same file as the server list: `allowedPluginMarketplaces`, `allowedPluginMcpServers`, `deniedPluginMcpServers`, `isLocalDevMcpEnabled`, `isDesktopExtensionEnabled`, `coworkEgressAllowedHosts`, `toolSearchEnabled`, `mcpPersistentAlwaysAllowEnabled` |
| **Set by an administrator** | `/Library/Application Support/ClaudeCode/managed-settings.json` and `managed-mcp.json` | A claude.ai organization's settings | `/Library/Managed Preferences/com.anthropic.claudefordesktop.plist` or `/Library/Managed Preferences/<user>/…plist`. If either sets more than app-behavior keys, the local `configLibrary` is ignored and the configuration window is read-only |
| **Takes effect** | The next session (no restart). `claude mcp get <name>` shows Connected | After quitting (Cmd+Q) and reopening | After quitting and reopening; the app may also offer Relaunch |
| **Logs** | `claude mcp list`, `/mcp`, `claude --debug` | `~/Library/Logs/Claude/main.log`, `mcp*.log` | `~/Library/Logs/Claude-3p/main.log`, `mcp.log`, `custom3p-setup.log` |
| **Tool names** | `mcp__<name>__<tool>` | The server's name in the + menu → Connectors | `mcp__<Name>__<tool>`; listed under Customize → Connectors |

### File permissions (as found; keep them)

| Path | Mode |
|---|---|
| `~/.claude.json`, `~/.claude/settings.json` | `600` |
| `~/Library/Application Support/Claude/claude_desktop_config.json` | `600` |
| `~/Library/Application Support/Claude-3p/` and `configLibrary/` | `700` |
| `configLibrary/_meta.json`, `configLibrary/<id>.json`, `Claude-3p/claude_desktop_config.json`, `developer_settings.json` | `600` |
| A helper script and its folder (`~/.claude-mcp/<name>`) | `700`, owned by the person, full path, no arguments needed |
| The token | Login keychain only: `security add-generic-password -U -s claude-mcp -a <name> -w` (asks, hidden). Read with `security find-generic-password -s claude-mcp -a <name> -w`. An item made by `security` is read by `security` without a prompt |

A file rewritten atomically comes back with default permissions: put the old mode back (`stat -f %Lp` before, `chmod` after). The 3P configuration file also holds the inference credential, so its backup copy keeps mode `600` too (`cp -p`). Never copy `configLibrary` files to another Mac or account: the key in them is encrypted for the account that saved it.

### Tool permissions

- **Claude Code:** each tool asks once; to allow ahead, add `"mcp__<name>__*"` (or single tools) to `permissions.allow` in `~/.claude/settings.json`. Ask before pre-allowing tools that write or send.
- **claude.ai app:** each tool asks; the person picks Always allow. Per-tool Blocked/Ask/Allow under Customize → Connectors → the connector.
- **3P:** the entry's `"toolPolicy": {"read_*": "allow", "*": "ask"}` (values `allow`, `ask`, `blocked`; the strictest matching wildcard wins; an exact name beats a wildcard). `allow` does not pre-approve Claude's own calls in the Code tab. Without a policy the person is asked and may choose Always allow, unless `mcpPersistentAlwaysAllowEnabled` is `false`.

## 3. Install

`claude-mcp.sh` (beside this file) does the three Claudes at once, with backups and permissions kept. Read it before running it.

```
claude-mcp.sh secret <name>                       # only for a fixed token: the person types it, hidden
claude-mcp.sh add-http <name> <url> [keychain|oauth|none]
claude-mcp.sh add-stdio <name> /full/path/to/command [args…]
claude-mcp.sh remove <name>
```

Each line it prints starts `OK`, `SKIP`, `WARN`, `MANUAL` or `FAILED`. `SKIP` is fine. Fix the rest yourself where you can, and run it again (it is safe to repeat).

What it cannot decide for you:

- **A token the service can issue over an API** (as Outpost does over Tailscale): fetch it yourself and pipe it in, `… | claude-mcp.sh secret <name>`, so it is never shown.
- **A remote server in the claude.ai app.** Public address: prefer a custom connector (the person does it: Customize → Connectors → Add → Add custom connector, the URL, then Connect). Private address: the script's bridge (`npx mcp-remote`, needs Node), or if the server answers plain JSON to each POST, a ten-line `curl` loop needs nothing installed.
- **A local server's program.** Install it first (a full path that exists; in 3P, plugins' and people's local servers also need `isLocalDevMcpEnabled` not `false`). Prefer a pinned version over `npx -y pkg@latest`.
- **Environment variables with secrets.** Do not write them into `env`. Wrap the command in a small script that reads the keychain and `exec`s the server (mode `700`), or in 3P use `envHelper`.

### Plugins

- **Claude Code / Code tab (claude.ai):** `claude plugin marketplace add <owner/repo>` then `claude plugin install <plugin>@<marketplace>`; check with `claude plugin list`. This writes `extraKnownMarketplaces` and `enabledPlugins` in `~/.claude/settings.json`.
- **claude.ai app (Cowork):** Customize → Plugins → browse or upload. Not scriptable.
- **3P:** the marketplace must be in `allowedPluginMarketplaces` in the applied configuration: `{"source":"github","repo":"owner/repo","installationPreference":"available"}`. Then the person installs it under Customize → Plugins. If `allowedPluginMcpServers` is set, a plugin's remote server connects only if its URL matches an entry (`{"serverUrl":"https://mcp.example.com/*"}`), and no plugin's local server runs: add the pattern, or add the server to `managedMcpServers` (same URL or name) so your entry is used in its place.

## 4. Verify, restart, prove

1. Before any restart, prove the server itself answers: for a remote one, `curl` its endpoint with the helper's header and a `tools/list` or a harmless tool call; for a local one, pipe an `initialize` message into the command. Never echo the header.
2. `claude mcp get <name>` should say Connected.
3. Re-read each changed file: the entry is there, the rest is intact, the mode is unchanged.
4. Tell the person: "Quit Claude completely with Cmd+Q (running sessions stop), open it again, come back here and say: check <name>."
5. When they return, call one harmless tool from the server (search your tools for its name first). If it is missing, read the logs in the table above before saying anything, and check that the app did not drop the entry.

## 5. Last resort: exact steps for the person

Only for the part that could not be done for them.

**3P app (configuration window):**
1. Menu bar: Help → Troubleshooting → Enable Developer Mode.
2. Menu bar: Developer → Configure Third-Party Inference…
3. Sidebar: Connectors. If every field is greyed out, a device profile manages the app: stop, and send the administrator the JSON entry.
4. Under Managed MCP servers, add a server: Name; Transport `Streamable HTTP` (or `Local command (stdio)`); URL (or Command and Arguments); Headers helper script: the full path. Leave the rest empty.
5. Test this connection, then Apply Changes, then Relaunch now.
6. Customize → Connectors shows it. For an OAuth server, click Connect there.

**claude.ai app:** Claude → Settings… → Developer → Edit Config; add the entry under `mcpServers` in the file that opens; save; Cmd+Q; reopen; Settings → Developer shows it running.

**Claude Code:** `claude mcp add-json --scope user <name> '<entry>'`, then `/mcp` in a session.

**Undo:** `claude-mcp.sh remove <name>`, or put each `.before-claude-mcp` copy back; `security delete-generic-password -s claude-mcp -a <name>`; revoke the token at the service.

## Report

Finish with: which Claudes now have it, what the person still has to do, and what you could not verify.
