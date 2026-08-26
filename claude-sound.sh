#!/bin/sh
# Portable notification-sound player for Claude Code hooks.
#
#   claude-sound.sh done                  -> plays homeworld/done.wav
#   claude-sound.sh hyperspace-jump-complete
#                                         -> falls back to homeworld/alternates/
#
# Self-contained: sounds are resolved relative to this script, so the whole
# ~/.claude/sounds/ directory can be copied to another machine as-is.
# Never fails loudly - a missing player must not break the hook.
#
# Set CLAUDE_SOUND_DEBUG=1 to append every invocation to sounds/events.log.
# Useful for confirming which hook events actually fire on a given machine.

BASE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOUND_DIR=$BASE/homeworld

win_play() {
    # Translate the POSIX path for PowerShell (Git Bash / MSYS / Cygwin / WSL)
    p=$1
    if command -v cygpath >/dev/null 2>&1; then
        p=$(cygpath -w "$p")
    elif command -v wslpath >/dev/null 2>&1; then
        p=$(wslpath -w "$p")
    fi
    # Double any single quotes so the PowerShell literal stays intact
    p=$(printf '%s' "$p" | sed "s/'/''/g")
    powershell.exe -NoProfile -Command "(New-Object Media.SoundPlayer '$p').PlaySync()"
}

play() {
    f=$1
    [ -f "$f" ] || return 0
    case "$(uname -s)" in
        Darwin)
            afplay "$f"
            ;;
        Linux)
            if command -v paplay >/dev/null 2>&1; then
                paplay "$f"
            elif command -v aplay >/dev/null 2>&1; then
                aplay -q "$f"
            elif command -v ffplay >/dev/null 2>&1; then
                ffplay -nodisp -autoexit -loglevel quiet "$f"
            elif command -v powershell.exe >/dev/null 2>&1; then
                win_play "$f"          # WSL, no native audio
            fi
            ;;
        *)
            win_play "$f"              # MINGW / MSYS / CYGWIN
            ;;
    esac
}

name=${1:-done}

# Hook events deliver JSON on stdin. Drain it so the caller never blocks on a
# pipe we are not reading, and keep it for the debug log.
payload=""
[ -t 0 ] || payload=$(cat 2>/dev/null)

if [ "${CLAUDE_SOUND_DEBUG:-}" = "1" ]; then
    printf '%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$name" \
        "$(printf '%s' "$payload" | tr '\n' ' ' | cut -c1-200)" >> "$BASE/events.log"
fi

# Primary sounds live in homeworld/, everything swappable in homeworld/alternates/
file=$SOUND_DIR/$name.wav
[ -f "$file" ] || file=$SOUND_DIR/alternates/$name.wav

play "$file" >/dev/null 2>&1
exit 0
