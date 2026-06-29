#!/usr/bin/env bash
# Open a URL in the environment's in-app browser and optionally capture proof.
#
# Usage:
#   open-in-browser.sh <url> [--shot <screenshot-path>] [--wait-text <text>]
#
# Behavior by environment (see detect-browser.sh):
#   cmux   -> `cmux browser open-split <url>`, optional `wait`, optional `screenshot`.
#   system -> falls back to macOS `open <url>` and prints a notice. When the agent
#             has the claude-in-chrome MCP, it should IGNORE this fallback and use
#             the MCP (navigate + screenshot) instead — a shell script cannot drive MCP.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
URL=""
SHOT=""
WAIT_TEXT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shot) SHOT="$2"; shift 2 ;;
    --wait-text) WAIT_TEXT="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) if [[ -z "$URL" ]]; then URL="$1"; shift; else echo "Unexpected arg: $1" >&2; exit 2; fi ;;
  esac
done

if [[ -z "$URL" ]]; then
  echo "Pass a URL to open." >&2
  exit 2
fi

ADAPTER="$("$SCRIPT_DIR/detect-browser.sh")"

case "$ADAPTER" in
  cmux)
    BIN="${CMUX_BUNDLED_CLI_PATH:-cmux}"
    echo "[adapter=cmux] opening in-app browser split: $URL"
    # open-split prints e.g. "OK surface=surface:48 pane=pane:24 placement=reuse".
    # Every later subcommand (wait/screenshot) REQUIRES that surface handle —
    # without it, cmux treats the subcommand name as the surface and errors.
    OPEN_OUT="$("$BIN" browser open-split "$URL" --focus true)"
    echo "$OPEN_OUT"
    SURFACE="$(printf '%s\n' "$OPEN_OUT" | grep -oE 'surface=[^ ]+' | head -1 | cut -d= -f2)"
    if [[ -z "$SURFACE" ]]; then
      echo "[adapter=cmux] could not parse surface handle; skipping wait/screenshot." >&2
      exit 0
    fi
    # Wait for a known marker before proving a frame (a loaded page != a healthy stream).
    if [[ -n "$WAIT_TEXT" ]]; then
      "$BIN" browser --surface "$SURFACE" wait --text "$WAIT_TEXT" --timeout 30 || true
    else
      "$BIN" browser --surface "$SURFACE" wait --load-state complete --timeout 30 || true
    fi
    if [[ -n "$SHOT" ]]; then
      "$BIN" browser --surface "$SURFACE" screenshot --out "$SHOT"
      echo "[adapter=cmux] proof screenshot: $SHOT"
    fi
    ;;
  system)
    echo "[adapter=system] no cmux in-app browser."
    echo "  If the claude-in-chrome MCP is available, the AGENT should navigate there"
    echo "  (mcp__claude-in-chrome__navigate -> $URL) and screenshot via the MCP instead."
    echo "  Shell fallback (opens the system default browser):"
    open "$URL"
    if [[ -n "$SHOT" ]]; then
      echo "  NOTE: --shot is not supported by the system fallback; capture via the MCP." >&2
    fi
    ;;
  *)
    echo "Unknown adapter: $ADAPTER" >&2
    exit 1
    ;;
esac
