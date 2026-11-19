#!/bin/zsh
# Adds or removes one MCP server in every Claude on this Mac: Claude Code (and the app's Code tab), the Claude app
# signed in to claude.ai (Chat, Cowork), and the Claude app on third-party inference (Bedrock, Vertex, Foundry, a
# gateway). Uses only what macOS ships. Safe to run again. Never prints a secret.
#
#   claude-mcp.sh detect
#   claude-mcp.sh secret <name>                      save a token in the login keychain (asked for, hidden; or on stdin)
#   claude-mcp.sh add-http <name> <url> [keychain|oauth|none]   default: keychain if a secret is saved, else oauth
#   claude-mcp.sh add-stdio <name> <command> [args…]            command as a full path
#   claude-mcp.sh remove <name>
set -u
APP="$HOME/Library/Application Support"
DIR="$HOME/.claude-mcp"
say() { print -r -- "$@"; }
[[ $(uname) == Darwin ]] || { say "FAILED not-a-mac: run this on the Mac itself, not in a sandbox or a VM."; exit 3; }
cmd=${1:-detect}; name=${2:-}
lib="$APP/Claude-3p/configLibrary"
applied=$(grep -o '"appliedId"[^,}]*' "$lib/_meta.json" 2>/dev/null | grep -o '[0-9a-f-]\{36\}')
managed=(/Library/Managed\ Preferences/{,$USER/}com.anthropic.claudefordesktop.plist(N))
claude=$(whence -p claude || print -r -- "$HOME/.local/bin/claude")

if [[ $cmd == detect ]]; then
  [[ -x $claude ]] && say "claude-code: yes ($claude)" || say "claude-code: no CLI found (~/.claude.json is still read by the Code tab)"
  [[ -d $APP/Claude ]] && say "claude-app: yes ($APP/Claude/claude_desktop_config.json)" || say "claude-app: no"
  if [[ -d $APP/Claude-3p ]]; then
    say "claude-3p: yes (applied configuration: ${${applied:+$lib/$applied.json}:-none})"
    (( $#managed )) && say "claude-3p-managed: yes ($managed[1]): only an administrator can add servers"
  else
    say "claude-3p: no"
  fi
  exit 0
fi
[[ $name =~ '^[A-Za-z0-9][A-Za-z0-9_-]*$' ]] || { say "FAILED name: use letters, digits, - and _ for the server's name."; exit 1; }
helper="$DIR/$name"

if [[ $cmd == secret ]]; then
  if [[ -t 0 ]]; then
    /usr/bin/security add-generic-password -U -s claude-mcp -a "$name" -l "Claude MCP: $name" -w
  else
    IFS= read -r value && /usr/bin/security add-generic-password -U -s claude-mcp -a "$name" -l "Claude MCP: $name" -w "$value"
  fi && say "OK secret: saved in the login keychain (service claude-mcp, account $name)." || { say "FAILED keychain"; exit 4; }
  exit 0
fi

# One JSON file changed (a copy from before kept beside it, permissions kept), or with FILE unset the entry printed.
JXA='ObjC.import("Foundation");
const env = (k) => ObjC.unwrap($.NSProcessInfo.processInfo.environment.objectForKey(k));
const [file, target, mode, name, url, auth, helper, command] = ["FILE", "TARGET", "MODE", "NAME", "URL", "AUTH", "HELPER", "CMD"].map(env);
const args = JSON.parse(env("ARGS") || "[]");
const entry = url
  ? target == "3p"
    ? { name, transport: "http", url, ...(auth == "keychain" ? { headersHelper: helper } : auth == "oauth" ? { oauth: true } : {}) }
    : target == "app"
      ? { command: helper, args: ["stdio"] }
      : { type: "http", url, ...(auth == "keychain" ? { headersHelper: helper } : {}) }
  : target == "3p" ? { name, transport: "stdio", command, args } : { command, args };
if (!file) JSON.stringify(entry);
else {
  const had = $.NSString.stringWithContentsOfFileEncodingError(file, 4, null);
  const o = had.isNil() || !had.js.trim() ? {} : JSON.parse(had.js);
  if (target == "3p") {
    o.managedMcpServers = (o.managedMcpServers || []).filter((s) => s.name != name && (!url || s.url != url));
    if (mode == "add") o.managedMcpServers.push(entry);
  } else if (mode == "add") (o.mcpServers ||= {})[name] = entry;
  else if (o.mcpServers) delete o.mcpServers[name];
  if (!$(JSON.stringify(o, null, 2) + "\n").writeToFileAtomicallyEncodingError(file, true, 4, null)) throw "not written";
  "";
}'
jxa() { # jxa <target> [file]
  local perms=600
  [[ -n ${2:-} && -f $2 ]] && { perms=$(stat -f %Lp "$2"); cp -p "$2" "$2.before-claude-mcp"; }
  TARGET="$1" FILE="${2:-}" MODE="$mode" NAME="$name" URL="$url" AUTH="$auth" HELPER="$helper" CMD="$command" ARGS="$args" \
    osascript -l JavaScript -e "$JXA" | grep . ; [[ ${pipestatus[1]} == 0 ]] && { [[ -z ${2:-} ]] || chmod "$perms" "$2"; }
}

mode=add; url=; auth=; command=; args='[]'; failed=0
case $cmd in
  add-http)
    url=${3:?url}; auth=${4:-}
    [[ $url == https://* ]] || say "WARN url: Claude on third-party inference only connects to https addresses."
    has=$(/usr/bin/security find-generic-password -s claude-mcp -a "$name" -w >/dev/null 2>&1 && print yes)
    [[ -n $auth ]] || auth=${has:+keychain}; [[ -n $auth ]] || auth=oauth
    [[ $auth != keychain || -n $has ]] || { say "FAILED no-secret: run '$0 secret $name' first."; exit 2; }
    # The helper: the sign-in header as JSON, or with "stdio" a local bridge to the remote server (mcp-remote).
    mkdir -p "$DIR" && chmod 700 "$DIR"
    cat >"$helper" <<EOF
#!/bin/zsh
# Made by claude-mcp.sh for the MCP server "$name" ($url). The token stays in the login keychain.
token=\$(/usr/bin/security find-generic-password -s claude-mcp -a '$name' -w 2>/dev/null)
if [[ \${1:-} != stdio ]]; then
  [[ -n \$token ]] && print -r -- "{\"Authorization\":\"Bearer \$token\"}" || print -r -- "{}"
  exit
fi
export PATH="/opt/homebrew/bin:/usr/local/bin:\$PATH"
exec npx -y mcp-remote '$url' \${token:+--header} \${token:+"Authorization: Bearer \$token"}
EOF
    chmod 700 "$helper" ;;
  add-stdio)
    command=${3:?command}; shift 3
    [[ $command == /* && -x $command ]] || { say "FAILED command: give the full path of a program that exists ($command)."; exit 1; }
    args=$(print -rl -- "$@" | osascript -l JavaScript -e 'ObjC.import("Foundation"); const d = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile; JSON.stringify(ObjC.unwrap($.NSString.alloc.initWithDataEncoding(d, 4)).split("\n").filter(Boolean))') ;;
  remove) mode=remove; rm -f "$helper" ;;
  *) say "FAILED usage: detect | secret <name> | add-http <name> <url> [keychain|oauth|none] | add-stdio <name> <command> [args…] | remove <name>"; exit 1 ;;
esac

# Claude Code and the Code tab (signed in to claude.ai): a user-scope server.
[[ -f $HOME/.claude.json ]] && cp -p "$HOME/.claude.json" "$HOME/.claude.json.before-claude-mcp"
if [[ -x $claude ]]; then
  "$claude" mcp remove --scope user "$name" >/dev/null 2>&1
  [[ $mode == remove ]] || "$claude" mcp add-json --scope user "$name" "$(jxa code)" >/dev/null 2>&1 || jxa code "$HOME/.claude.json"
else
  jxa code "$HOME/.claude.json"
fi && say "OK claude-code: $mode \"$name\" for every project (~/.claude.json). New sessions see it." || { say "FAILED claude-code"; failed=1; }

# The Claude app signed in to claude.ai (Chat, Cowork): a local server in its config file.
if [[ -d $APP/Claude ]]; then
  jxa app "$APP/Claude/claude_desktop_config.json" && say "OK claude-app: $mode \"$name\" in claude_desktop_config.json. RESTART Claude." || { say "FAILED claude-app"; failed=1; }
  [[ -n $url && $mode == add ]] && ! whence -p npx >/dev/null && [[ ! -x /opt/homebrew/bin/npx && ! -x /usr/local/bin/npx ]] &&
    say "WARN claude-app: its bridge needs Node (npx), which is not installed. If the address is public, add it as a custom connector instead."
else
  say "SKIP claude-app: not on this Mac."
fi

# The Claude app on third-party inference: only servers its configuration names are loaded.
if [[ -d $APP/Claude-3p ]]; then
  if (( $#managed )); then
    say "MANUAL claude-3p-managed: a device profile ($managed[1]) sets the configuration. Send the administrator this managedMcpServers entry: $(jxa 3p)"; failed=1
  elif [[ -n $applied && -f $lib/$applied.json ]] && jxa 3p "$lib/$applied.json"; then
    say "OK claude-3p: $mode \"$name\" in managedMcpServers (configLibrary/$applied.json). RESTART Claude."
  else
    say "MANUAL claude-3p-no-config: no applied configuration in $lib. Add this entry in the configuration window: $(jxa 3p)"; failed=1
  fi
else
  say "SKIP claude-3p: not on this Mac."
fi
say "DONE. Quit Claude completely (Cmd+Q) and open it again."
exit $failed
