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
# VOLUME  0-100, default 50. Set it in the `volume` file next to this script
#         (survives across sessions, which env vars do not reliably do inside
#         hooks), or override per-run with CLAUDE_SOUND_VOLUME=80.
#
# CLAUDE_SOUND_DEBUG=1 appends every invocation to sounds/events.log - use it to
# find out which hook events actually fire on a given machine.

BASE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOUND_DIR=$BASE/homeworld
LOCK=${TMPDIR:-/tmp}/claude-fleet-sound.lock

# --- volume -----------------------------------------------------------------
VOL=50
[ -f "$BASE/volume" ] && VOL=$(tr -dc '0-9' < "$BASE/volume")
[ -n "${CLAUDE_SOUND_VOLUME:-}" ] && VOL=$(printf '%s' "$CLAUDE_SOUND_VOLUME" | tr -dc '0-9')
[ -z "$VOL" ] && VOL=50
[ "$VOL" -gt 100 ] 2>/dev/null && VOL=100

# --- concurrency ------------------------------------------------------------
# Hooks are async, so two events landing together (a task finishing as the turn
# ends) would start two players at once and talk over each other. First one in
# wins; the rest exit silently rather than queue, since a backlog of stale
# callouts is worse than a missed one.
acquire_lock() {
    if [ -d "$LOCK" ] && [ -n "$(find "$LOCK" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
        rmdir "$LOCK" 2>/dev/null
    fi
    mkdir "$LOCK" 2>/dev/null || return 1
    trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM HUP
    return 0
}

# --- players ----------------------------------------------------------------
win_play() {
    p=$1
    if command -v cygpath >/dev/null 2>&1; then
        p=$(cygpath -w "$p")
    elif command -v wslpath >/dev/null 2>&1; then
        p=$(wslpath -w "$p")
    fi
    p=$(printf '%s' "$p" | sed "s/'/''/g")

    if [ "$VOL" -ge 100 ]; then
        # SoundPlayer is the most reliable path; it has no volume control.
        powershell.exe -NoProfile -Command \
            "(New-Object Media.SoundPlayer '$p').PlaySync()"
        return
    fi

    # MediaPlayer supports Volume. Falls back to SoundPlayer if it cannot load.
    powershell.exe -NoProfile -Command "
try {
    Add-Type -AssemblyName PresentationCore -ErrorAction Stop
    \$m = New-Object System.Windows.Media.MediaPlayer
    \$m.Open([Uri]'$p')
    \$w = 0
    while (-not \$m.NaturalDuration.HasTimeSpan -and \$w -lt 100) { Start-Sleep -Milliseconds 20; \$w++ }
    \$m.Volume = $VOL / 100
    \$m.Play()
    if (\$m.NaturalDuration.HasTimeSpan) {
        Start-Sleep -Milliseconds ([int]\$m.NaturalDuration.TimeSpan.TotalMilliseconds + 200)
    } else { Start-Sleep -Milliseconds 2500 }
    \$m.Stop(); \$m.Close()
} catch {
    (New-Object Media.SoundPlayer '$p').PlaySync()
}"
}

play() {
    f=$1
    [ -f "$f" ] || return 0
    case "$(uname -s)" in
        Darwin)
            afplay -v "$(awk "BEGIN{printf \"%.3f\", $VOL/100}")" "$f"
            ;;
        Linux)
            if command -v paplay >/dev/null 2>&1; then
                paplay --volume="$(( 65536 * VOL / 100 ))" "$f"
            elif command -v ffplay >/dev/null 2>&1; then
                ffplay -nodisp -autoexit -loglevel quiet -volume "$VOL" "$f"
            elif command -v aplay >/dev/null 2>&1; then
                aplay -q "$f"          # no volume control; plays at full
            elif command -v powershell.exe >/dev/null 2>&1; then
                win_play "$f"          # WSL, no native audio
            fi
            ;;
        *)
            win_play "$f"              # MINGW / MSYS / CYGWIN
            ;;
    esac
}

# --- main -------------------------------------------------------------------
name=${1:-done}

# Hook events deliver JSON on stdin, but only the debug log needs it. Reading it
# unconditionally would block until the writer closes the pipe - fine for a hook,
# a hang for anything else that calls this with stdin still open.
payload=""
if [ "${CLAUDE_SOUND_DEBUG:-}" = "1" ] || [ -f "$BASE/debug" ]; then
    [ -t 0 ] || payload=$(cat 2>/dev/null)
fi

if [ "${CLAUDE_SOUND_DEBUG:-}" = "1" ] || [ -f "$BASE/debug" ]; then
    printf '%s\t%s\tvol=%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$name" "$VOL" \
        "$(printf '%s' "$payload" | tr '\n' ' ' | cut -c1-300)" >> "$BASE/events.log"
fi

# Primary sounds live in homeworld/, swappable voice lines in homeworld/alternates/,
# short interface blips in homeworld/ui/
file=$SOUND_DIR/$name.wav
[ -f "$file" ] || file=$SOUND_DIR/alternates/$name.wav
[ -f "$file" ] || file=$SOUND_DIR/ui/$name.wav

# The game reuses one recording for many interface events, so ui/aliases.txt
# maps every other name onto the clip that actually holds the audio.
if [ ! -f "$file" ] && [ -f "$SOUND_DIR/ui/aliases.txt" ]; then
    canon=$(awk -v n="$name" '$1==n {print $2; exit}' "$SOUND_DIR/ui/aliases.txt")
    [ -n "$canon" ] && file=$SOUND_DIR/ui/$canon.wav
fi

# Silent on a missing file so a hook can never break, but say so on stderr -
# hooks discard it, a human running this by hand gets told.
[ -f "$file" ] || echo "claude-sound: no clip named '$name'" >&2

acquire_lock || exit 0          # another callout is already playing
play "$file" >/dev/null 2>&1
exit 0
