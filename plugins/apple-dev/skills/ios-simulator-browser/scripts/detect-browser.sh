#!/usr/bin/env bash
# Detect which in-app browser adapter is available in the current environment.
# Prints exactly one of: cmux | system
#
# - "cmux"   : running inside a cmux workspace AND its in-app browser is reachable.
#              Drive it with the `cmux browser` CLI (open-split/screenshot/wait/...).
# - "system" : not in cmux. The agent should open the URL with its own runtime browser
#              (Claude Code -> claude-in-chrome MCP; Codex -> Codex in-app browser;
#              Cursor -> its browser tool / browser MCP), falling back to `open <url>`.
#
# Rationale: the cmux path is host-based (CMUX_WORKSPACE_ID) and fully scriptable from
# the shell, so it works for ANY agent hosted in cmux. A runtime's own browser is driven
# by the agent (MCP / in-app), not from a shell script, so this script only distinguishes
# cmux from everything else.
set -euo pipefail

cmux_bin() {
  if [[ -n "${CMUX_BUNDLED_CLI_PATH:-}" && -x "${CMUX_BUNDLED_CLI_PATH}" ]]; then
    printf '%s' "${CMUX_BUNDLED_CLI_PATH}"
    return 0
  fi
  command -v cmux 2>/dev/null || return 1
}

# Inside a cmux workspace? CMUX_WORKSPACE_ID is injected for every cmux pane.
if [[ -n "${CMUX_WORKSPACE_ID:-}" ]]; then
  if bin="$(cmux_bin)"; then
    # Confirm the browser subsystem actually answers over the socket.
    if status="$("$bin" browser status 2>/dev/null)" && [[ "$status" == *enabled* ]]; then
      echo "cmux"
      exit 0
    fi
  fi
fi

echo "system"
