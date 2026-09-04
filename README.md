# Claude Fleet Command Pack

Mainly for the "research complete" notification for when I'm away from my computer. This isn't quite finished (I probably will cut some sfx) but I'll upload it now in case people want to fork it.

obv audio is not mine, it's easy to scrape from the original games, will take down if requested. 

below is claude:

--------------------------------------------------------

Homeworld Fleet Intelligence callouts as [Claude Code](https://claude.com/claude-code)
notification sounds. Your terminal tells you a turn finished, a permission prompt
is waiting, or a background task landed — in the voice of the Mothership.

Seven hook events wired, eighteen alternates, one POSIX script, no dependencies.

```
Stop               ->  "Research complete."
Notification       ->  "Construction paused."
PermissionRequest  ->  "Confirm attack on friendly unit."
PreCompact         ->  "Marshalling the fleet."
```

## Install

```sh
git clone https://github.com/highbypassfan/claude-fleet-command-pack.git
cd claude-fleet-command-pack
./install.sh
```

Copies the sounds to `~/.claude/sounds/` and merges the hooks into
`~/.claude/settings.json` (backing up whatever was there first). Restart Claude
Code, or open `/hooks` once, to load the new config.

`./install.sh --no-hooks` copies the sounds and prints the hooks block for you to
merge by hand.

## Wired events

| Hook event | Sound | Line |
|---|---|---|
| `Stop` | `done.wav` | "Research complete." |
| `StopFailure` | `fail.wav` | "Hyperspace jump interrupted." |
| `Notification` | `input.wav` | "Construction paused." |
| `PermissionRequest` | `confirm.wav` | "Confirm attack on friendly unit." |
| `PermissionDenied` | `denied.wav` | "Order cancelled." |
| `PreCompact` | `compact.wav` | "Marshalling the fleet." |
| `SessionEnd` | `sessionend.wav` | "All construction cancelled." |

Hooks fire asynchronously, so two events can land at once — a background task
finishing as the turn ends. `claude-sound.sh` takes a lock: the first callout
plays and any that overlap it exit silently. They are dropped rather than
queued, because a backlog of stale callouts is worse than a missed one.

### Optional: agent completion sounds

`SubagentStop` and `TaskCompleted` are **not** wired by default. Both tend to
fire at the same moment the turn ends, so you get two callouts back to back for
what feels like one event. Add them if you run a lot of long background work and
want it announced separately:

```json
"SubagentStop": [
  { "hooks": [ { "type": "command", "command": "\"$HOME/.claude/sounds/claude-sound.sh\" agentdone", "async": true, "timeout": 10 } ] }
],
"TaskCompleted": [
  { "hooks": [ { "type": "command", "command": "\"$HOME/.claude/sounds/claude-sound.sh\" agentdone", "async": true, "timeout": 10 } ] }
]
```

`agentdone.wav` ("Ships transferred.") ships with the pack. Wire one or the
other, not both — run `CLAUDE_SOUND_DEBUG=1 claude` first to see which actually
fires on your build.

Not every event fires in every Claude Code build. To see which ones land on your
machine, run `CLAUDE_SOUND_DEBUG=1 claude` and work normally — each invocation
appends a timestamped line to `~/.claude/sounds/events.log`.

## Volume

Everything plays at **50%** by default. Change it by writing a number 0-100 into
the `volume` file next to `claude-sound.sh`:

```sh
echo 75 > ~/.claude/sounds/volume
```

A file rather than an env var, because hooks do not reliably inherit your
shell's environment. `CLAUDE_SOUND_VOLUME=80` still works for a one-off.

At 100 the Windows player uses `SoundPlayer`; below that it uses `MediaPlayer`,
which supports volume and falls back to `SoundPlayer` if it cannot load. macOS
uses `afplay -v`, Linux `paplay --volume` or `ffplay -volume`. `aplay` has no
volume control and always plays full.

## Swapping sounds

Hooks reference *names*, not paths. Copy an alternate over a primary:

```sh
cp ~/.claude/sounds/homeworld/alternates/upgrade-complete.wav \
   ~/.claude/sounds/homeworld/done.wav
```

Audition anything first, without touching config:

```sh
~/.claude/sounds/claude-sound.sh hyperspace-jump-complete
```

Bare names resolve against `homeworld/` first, then `homeworld/alternates/`.

## Alternates

| File | Line | Suits |
|---|---|---|
| `upgrade-complete.wav` | "Upgrade complete." | `Stop` |
| `hyperspace-jump-complete.wav` | "Hyperspace jump complete." | `Stop`, more dramatic |
| `proximity-alert.wav` | "Proximity Alert" | `Notification`, more urgent |
| `insufficient-resources.wav` | "Insufficient resources. Production paused." | `Notification` (2.85s — long) |
| `new-research-available.wav` | "New research available." | `Notification` |
| `construction-stopped.wav` | "Construction stopped." | `SessionEnd` |
| `hyperspace-jump-aborted.wav` | "Hyperspace jump aborted." | `StopFailure` |
| `weapon-systems-powered-down.wav` | "Weapon systems powered down." | `PermissionDenied` |
| `waypoint-confirmed.wav` | "Waypoint confirmed." | `PermissionRequest` |
| `production-underway.wav` | "Production underway." | `UserPromptSubmit` |
| `production-confirmed.wav` | "Production confirmed." | `UserPromptSubmit` |
| `initiate-production.wav` | "Initiate production." | `UserPromptSubmit` |
| `guarding-fleet.wav` | "Guarding Fleet" | — |
| `scout-squadron-complete.wav` | "Scout Squadron complete." | `SubagentStop` / `TaskCompleted` |
| `probe-complete.wav` | "probe complete." | `SubagentStop` / `TaskCompleted` |
| `fleet-command-back-online.wav` | "Fleet command back online." | `SessionStart` (not wired) |
| `this-is-fleet-command.wav` | "This is Fleet Command," | `SessionStart` (not wired) |
| `she-is-now-fleet-command.wav` | "She is now Fleet Command." | `SessionStart` (not wired) |

The three Fleet Command clips come from Homeworld 1 campaign narration and use a
different voice actor from everything else here. They sound out of place
mid-session; `SessionStart` fires once in isolation, where the jump doesn't register.

## Platform support

`claude-sound.sh` is POSIX sh and picks a player at runtime:

| Platform | Player |
|---|---|
| macOS | `afplay` |
| Linux | `paplay` → `aplay` → `ffplay` |
| WSL | falls through to `powershell.exe` |
| Windows (Git Bash/MSYS/Cygwin) | `powershell.exe` + `Media.SoundPlayer` |

Claude Code runs hooks through bash wherever Git Bash is present, which is the
normal Windows install. On a Windows box with **no** Git Bash, hooks run through
PowerShell and the hook command won't resolve — install Git Bash, or swap in a
PowerShell one-liner.

If no player is found the script exits 0 silently, so a hook can never break a
session. All hooks are `async` with a 10s timeout, so a 1–2s clip never blocks a turn.

## Where the audio came from

Homeworld Remastered ships its audio in Relic SGA v2 archives (`.big`). The
Fleet Intelligence status bank lives in `EnglishSpeech.big` under
`sound\speech\allships\fleet\`, and is shared between Homeworld 1 and 2 Remastered.

`tools/big.py` is a standalone parser for that format — it lists and extracts
any Relic `.big` archive:

```sh
python tools/big.py "…/HomeworldRM/Data/EnglishSpeech.big"     # list contents
```

The three Fleet Command clips were cut from `EnglishSpeechHW1Campaign.big`
narration at clause boundaries with a 60 ms fade-out. Everything else is
untouched: 44.1 kHz mono 16-bit PCM, straight out of the archive.

## Licence

`claude-sound.sh`, `install.sh`, `tools/big.py` and this README are MIT licensed —
see [LICENSE](LICENSE).

**The audio is not.** The `.wav` files are the property of Gearbox Software /
Relic Entertainment, from Homeworld Remastered Collection. They are included here
for personal, non-commercial use by people who own the game. No ownership is
claimed and no endorsement is implied. If you represent the rights holder and
want them gone, open an issue and I'll remove them.

---

Built by [@acheronix](https://x.com/acheronix) on X.
