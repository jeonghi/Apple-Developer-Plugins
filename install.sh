#!/usr/bin/env bash
# Cross-runtime installer for the skills in this repo.
#
# Claude Code users do NOT need this — use the marketplace flow instead:
#   /plugin marketplace add jeonghi/Apple-Developer-Plugins
#   /plugin install ios-simulator-browser@apple-developer-plugins
#
# This script is for Codex and Cursor (and a plain Claude ~/.claude/skills install),
# which install skills by placing them in a runtime skills directory. It SYMLINKS each
# skill in this repo into every runtime's skills dir, so editing the repo updates them all.
# Re-run after `git pull` to pick up new skills. Idempotent.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"

# Runtime skills directories (created if missing). cmux is a host, not a runtime —
# any agent inside cmux is covered by whichever of these it uses.
CLAUDE_DIR="$HOME/.claude/skills"
CODEX_DIR="$HOME/.codex/skills"
CURSOR_DIR="$HOME/.cursor/skills-cursor"
AGENTS_DIR="$HOME/.agents/skills"          # cross-runtime alias (Codex/Copilot/Gemini)
CODEX_CONFIG="$HOME/.codex/config.toml"

link() {  # link <target> <linkpath>
  local target="$1" linkpath="$2"
  [ -d "$(dirname "$linkpath")" ] || return 0   # skip runtimes not installed
  ln -sfn "$target" "$linkpath"
  echo "  linked $linkpath"
}

# Register a skill's SKILL.md in Codex config.toml (Codex needs explicit registration).
register_codex() {
  local skill_md="$1"
  [ -f "$CODEX_CONFIG" ] || return 0
  grep -qF "$skill_md" "$CODEX_CONFIG" && return 0   # already registered
  printf '\n[[skills.config]]\npath = "%s"\nenabled = true\n' "$skill_md" >> "$CODEX_CONFIG"
  echo "  registered in Codex config.toml"
}

for plugin in "$PLUGINS_DIR"/*/; do
  skills_root="$plugin/skills"
  [ -d "$skills_root" ] || continue
  for skill in "$skills_root"/*/; do
    name="$(basename "$skill")"
    skill="${skill%/}"
    echo "Installing skill: $name"
    link "$skill" "$CLAUDE_DIR/$name"
    link "$skill" "$CODEX_DIR/$name"
    link "$skill" "$CURSOR_DIR/$name"
    link "$skill" "$AGENTS_DIR/$name"
    register_codex "$skill/SKILL.md"
  done
done

echo
echo "Done. Restart your agent session to pick up the skills."
echo "Claude Code users can alternatively use: /plugin marketplace add jeonghi/Apple-Developer-Plugins"
