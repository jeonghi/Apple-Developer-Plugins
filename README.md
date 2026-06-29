# Apple Developer Plugins

A marketplace of Apple-platform development plugins for AI coding agents, designed to work across
**Claude Code**, **Codex**, and **Cursor** (and any agent hosted in **cmux**). Layout follows the
[openai/plugins](https://github.com/openai/plugins) convention.

## Plugins

| Plugin | Skills | What it does |
| --- | --- | --- |
| [`apple-dev`](plugins/apple-dev) | `ios-simulator-browser` | iOS development bundle — mirror a running Simulator into an in-app browser and capture proof frames, or live-iterate SwiftUI previews from Swift packages with hot reload. |

## Install

### Claude Code (marketplace — one-liner)

```
/plugin marketplace add jeonghi/Apple-Developer-Plugins
/plugin install apple-dev@apple-developer-plugins
```

Update later with `/plugin marketplace update apple-developer-plugins`.

### Codex (marketplace)

Add this repo as a marketplace and install the plugin; the catalog lives at
`.agents/plugins/marketplace.json`.

```
/plugin marketplace add jeonghi/Apple-Developer-Plugins
/plugin install apple-dev
```

### Codex / Cursor / plain `~/.claude/skills` (symlink installer)

If you prefer to install the skills directly (or your runtime doesn't consume the marketplace),
clone and run the installer. It symlinks every skill in every plugin into each runtime's skills
dir (so `git pull` keeps them current) and registers them in Codex's `config.toml`:

```bash
git clone https://github.com/jeonghi/Apple-Developer-Plugins.git
cd Apple-Developer-Plugins
./install.sh
```

Targets it links into when present: `~/.claude/skills`, `~/.codex/skills`,
`~/.cursor/skills-cursor`, `~/.agents/skills`. Restart your agent session afterward.

## Repository layout

```
.
├── .agents/plugins/marketplace.json     # Codex marketplace catalog
├── .claude-plugin/marketplace.json      # Claude Code marketplace catalog
└── plugins/
    └── apple-dev/                         # a plugin bundle (multiple skills)
        ├── .codex-plugin/plugin.json    # Codex manifest (+ interface)
        ├── .claude-plugin/plugin.json   # Claude manifest
        ├── agents/openai.yaml           # Codex agent interface
        ├── assets/                      # icons
        ├── skills/<skill>/SKILL.md      # the skills
        └── README.md
```

Claude and Codex both load a plugin as a directory with a `skills/` folder plus a manifest. Each
plugin here ships **both** manifests pointing at the **same** `skills/`, so the one directory is a
valid plugin in either runtime. Cursor just needs the skill directory on disk, which `install.sh`
provides. cmux is a host, not a runtime: any agent inside it is covered by whichever skills dir it uses.

## License

MIT — see [LICENSE](LICENSE).
