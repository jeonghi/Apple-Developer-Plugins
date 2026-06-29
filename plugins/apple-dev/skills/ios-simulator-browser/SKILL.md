---
name: ios-simulator-browser
description: Use when you want to watch or interact with a running iOS app or SwiftUI preview inside an in-app browser (cmux, Chrome, or your runtime's browser), capture browser-visible simulator proof, or live-iterate a SwiftUI preview outside Xcode Canvas. Runtime-agnostic — works in Claude Code, Codex, Cursor, and any agent hosted in cmux. Triggers — "시뮬레이터 브라우저로 보기", iOS simulator mirror, serve-sim, SwiftUI preview hot reload, simulator screenshot proof.
---

# iOS Simulator Browser (runtime-agnostic)

## Overview

Mirror a running iOS Simulator into a browser and capture proof frames. The pipeline is
platform-neutral: `xcrun simctl` boots/installs/runs → `serve-sim` mirrors the simulator to a
local URL → **a browser opens that URL and screenshots a frame**. Only the last step depends on
where the agent runs, so it is isolated behind a detected adapter. Works the same in Claude Code,
Codex, Cursor, or any of them hosted inside cmux.

## Browser adapter — the only environment-specific part

`scripts/detect-browser.sh` prints `cmux` or `system`. The split is **host-based, not agent-based**:
cmux is detected via `CMUX_WORKSPACE_ID`, so any agent (Claude/Codex/Cursor) running inside cmux
gets the fully scriptable in-app-browser path. Everything else is `system`, where the **agent**
opens the URL with whatever browser its runtime provides.

| Adapter | When | Open + prove a frame |
| --- | --- | --- |
| **cmux** | inside a cmux workspace, `cmux browser status` = enabled | `scripts/open-in-browser.sh <url> --shot proof.png` (cmux browser open-split → wait → screenshot). Works for ANY agent hosted in cmux. |
| **system → runtime browser** | not in cmux | The **agent** opens the URL with its own browser tool (see per-runtime table) and screenshots there. A shell script cannot drive an agent's MCP/in-app browser. |
| **system → shell fallback** | no agent browser available | `scripts/open-in-browser.sh` runs `open <url>` (system default browser; no automated screenshot). |

### Per-runtime browser tool (when adapter = system)

| Runtime | How the agent opens the URL + captures proof |
| --- | --- |
| **Claude Code** | `mcp__claude-in-chrome__navigate` → `<url>`, then screenshot via the claude-in-chrome MCP. |
| **Codex** | Open the URL in the Codex in-app browser, then capture a browser screenshot. |
| **Cursor** | Use Cursor's browser tool / a browser MCP if configured; else the shell `open` fallback. |
| **any** | Last resort: `open <url>` and tell the user to look at the simulator stream. |

> These browsers are **separate engines** (cmux = WKWebView, Chrome = Blink) and cannot be wired
> to each other. Pick the one your environment exposes — inside cmux use `cmux browser`; otherwise
> use the runtime's own browser. Do not try to point one runtime's browser at another's.

## Workflow A — mirror a running app (any target)

1. Get a Simulator UDID: `xcrun simctl list devices booted` (or boot one explicitly).
2. Build + install + launch the app on that simulator with your normal flow.
3. Start `serve-sim` in **`--detach` daemon mode** pinned to that UDID. Detach is the robust path:
   it spawns a persistent helper (default port 3100) that serves BOTH the preview UI and the MJPEG
   stream, prints a JSON line, and exits — so nothing blocks and nothing dies when your shell moves on.

   ```bash
   SIM="<simulator-udid>"
   npx --yes serve-sim@latest --kill "$SIM" >/dev/null 2>&1 || true   # clear stale daemon (scoped!)
   URL="$(npx --yes serve-sim@latest --detach "$SIM" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')"
   echo "preview: $URL"   # e.g. http://127.0.0.1:3100  (title: "Simulator Preview")
   ```

   > Do NOT use the plain foreground `serve-sim "$SIM"` (port 3200) and then `--kill` it — killing a
   > running serve-sim segfaults it (exit 139) and leaves a blank preview. Use `--detach` and open its `url`.

4. Open that preview URL via the adapter and capture proof:

   ```bash
   scripts/open-in-browser.sh "$URL" --shot proof.png
   ```

   The preview page connects to the stream via JS, so the device view appears a beat after load —
   wait ~3–4s (or `wait --load-state complete` + a short settle) before the screenshot, or the first frame is blank.

   When adapter = system, the agent opens the URL with its runtime browser (table above) and screenshots there.
5. **Verify a real frame rendered** before reporting success — a loaded page is not proof the stream is healthy. Look at `proof.png`.
6. The detached daemon keeps running on its own. When done, stop it with
   `npx --yes serve-sim@latest --kill "$SIM"`. **Never run an unscoped `serve-sim --kill`** — another mirror may own a different simulator.

## Workflow B — SwiftUI preview hot reload (importable Swift Package only)

For previews in an importable Swift Package (NOT an app/extension target — the criterion is
"in a `Package.swift` library", not "multi-target"). `scripts/swiftui-preview-browser.mjs` generates
a disposable host app outside your source tree, launches it, and hot-swaps a dylib on edits without relaunching:

```bash
node scripts/swiftui-preview-browser.mjs \
  /absolute/path/to/Package.swift \
  --package-target "<target>" \
  --device "<simulator-udid>"
```

It prints the selected UDID; then run `serve-sim` for that UDID and open it with the adapter (step 4 above).
Use `--preview-filter <regex[,...]>` to show a subset. Watch mode is on by default.

**Support boundary (do not violate):** only Swift Package-backed `PreviewProvider` / `#Preview`.
Do **not** edit the user's `.xcodeproj` / `.xcworkspace` / `Package.swift` / schemes / build settings to force preview support. Dynamic-library products are unsupported (hot reload replaces only the generated plugin dylib).

## Proof

- Browser/preview QA: capture a screenshot showing the simulator frame (`--shot` in cmux; runtime browser screenshot otherwise).
- Hot-reload QA: report the launcher's `hot reloaded package preview ... in pid ...` line and show the changed frame after an edit (same PID = no relaunch).

## Common mistakes

- **Foreground `serve-sim` + `--kill` → segfault (exit 139), blank preview.** Killing a running serve-sim crashes it. Use `--detach` (daemon, port 3100) and open its JSON `url`; the daemon survives independently.
- **Screenshotting the preview UI immediately → blank frame.** The preview page connects to the stream via JS after load. Wait a few seconds before the proof shot. (The raw `/helper/<UDID>/stream.mjpeg` renders instantly if you only need the bare frame.)
- **Calling `cmux browser wait`/`screenshot` without a surface handle** → cmux treats the subcommand as the surface and errors with "Unsupported browser subcommand". `open-in-browser.sh` parses `surface=...` from `open-split` output and threads it through. Do the same if scripting manually.
- **`wait --text` is best-effort on WKWebView** (intermittent "completion handler no longer reachable") and won't match a video stream anyway — rely on `wait --load-state complete` + a screenshot to confirm the frame.
- **Opening the mirror in a separate browser while inside cmux** — redundant; the cmux in-app browser is what the user sees. Prefer the `cmux` adapter when detected.
- **Trying to point one runtime's browser at another's** — impossible (different engines). See the adapter note.
- **Using Workflow B on a CocoaPods app target** (e.g. an app whose screens live in the app target, RN or not) — needs an importable Swift Package. Extract the view into a local SPM package, or use Workflow A.
