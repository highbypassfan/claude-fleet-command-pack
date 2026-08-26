#!/bin/sh
# Install the Fleet Command pack into ~/.claude/sounds and wire up the hooks.
#
#   ./install.sh            copy sounds, then merge hooks into settings.json
#   ./install.sh --no-hooks copy sounds only, print the hooks block to paste
#
# Safe to re-run. Your existing settings are backed up before any change.

set -e

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEST=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/sounds
SETTINGS=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json

mkdir -p "$DEST"
cp -R "$SRC/homeworld" "$DEST/"
cp "$SRC/claude-sound.sh" "$DEST/claude-sound.sh"
cp "$SRC/hooks.json" "$DEST/hooks.json"
cp "$SRC/README.md" "$DEST/README.md"
chmod +x "$DEST/claude-sound.sh"
echo "sounds installed to $DEST"

if [ "$1" = "--no-hooks" ]; then
    echo
    echo "Merge this into $SETTINGS yourself:"
    echo
    cat "$SRC/hooks.json"
    exit 0
fi

# Find a python that actually runs. On Windows, `python3` may resolve to the
# Microsoft Store stub, which exists on PATH but is not an interpreter.
PY=""
for candidate in python3 python py; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c "pass" >/dev/null 2>&1; then
        PY=$candidate
        break
    fi
done

if [ -z "$PY" ]; then
    echo
    echo "No working python found - cannot merge automatically."
    echo "Paste the contents of $SRC/hooks.json into $SETTINGS yourself."
    exit 0
fi

"$PY" - "$SETTINGS" "$SRC/hooks.json" <<'PYEOF'
import json, io, os, shutil, sys

settings_path, hooks_path = sys.argv[1], sys.argv[2]
new_hooks = json.load(io.open(hooks_path, encoding="utf8"))["hooks"]

if os.path.exists(settings_path):
    shutil.copyfile(settings_path, settings_path + ".bak")
    settings = json.load(io.open(settings_path, encoding="utf8"))
    print("backed up existing settings to %s.bak" % settings_path)
else:
    os.makedirs(os.path.dirname(settings_path), exist_ok=True)
    settings = {}

hooks = settings.setdefault("hooks", {})

def ours(group):
    return any("claude-sound.sh" in h.get("command", "") for h in group.get("hooks", []))

for event, groups in new_hooks.items():
    kept = [g for g in hooks.get(event, []) if not ours(g)]   # preserve unrelated hooks
    hooks[event] = kept + groups

io.open(settings_path, "w", encoding="utf8").write(json.dumps(settings, indent=2) + "\n")
print("wired %d hook events into %s" % (len(new_hooks), settings_path))
PYEOF

echo
echo "Done. Restart Claude Code (or open /hooks once) to load the new config."
