# Apple Dev

An iOS development skill bundle for AI coding agents, modeled on the
[openai/plugins](https://github.com/openai/plugins) `build-ios-apps` layout and made
runtime-agnostic across **Claude Code**, **Codex**, and **Cursor**.

## Skills

| Skill | What it does |
| --- | --- |
| [`ios-simulator-browser`](skills/ios-simulator-browser) | Mirror a running iOS Simulator into an in-app browser (cmux / Chrome / your runtime's browser) via `serve-sim` and capture proof frames, or live-iterate SwiftUI previews from importable Swift packages with dylib hot reload — no Xcode Canvas needed. |

More iOS skills (SwiftUI patterns, performance, debugging) can be added under `skills/`.

## Requirements

- macOS with Xcode + iOS Simulator (`xcrun simctl`)
- Node.js (for `serve-sim` and the SwiftUI preview launcher)
- Optional: running inside cmux for the fully-scriptable in-app-browser path

## Manifests

This bundle ships both manifests, pointing at the same `skills/` directory:

- `.claude-plugin/plugin.json` — Claude Code
- `.codex-plugin/plugin.json` — Codex (with `interface` + `assets/` icons + `agents/openai.yaml`)

See the marketplace root [README](../../README.md) for install instructions.
