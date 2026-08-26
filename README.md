# Claude Fleet Command Pack

Homeworld Fleet Intelligence callouts as [Claude Code](https://claude.com/claude-code)
notification sounds. Your terminal tells you a turn finished, a permission prompt
is waiting, or a background task landed — in the voice of the Mothership.

Ten hook events wired, sixteen alternates, one POSIX script, no dependencies.

```
Stop               ->  "Research complete."
Notification       ->  "Construction paused."
PermissionRequest  ->  "Confirm attack on friendly unit."
TaskCompleted      ->  "Scout Squadron complete."
PreCompact         ->  "Marshalling the fleet."
SessionStart       ->  "Hyperdrive engaged."
```

## Install

```sh
git clone https://github.com/<you>/claude-fleet-command-pack.git
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
| `SubagentStop` | `agentdone.wav` | "Scout Squadron complete." |
| `TaskCompleted` | `agentdone.wav` | "Scout Squadron complete." |
| `PreCompact` | `compact.wav` | "Marshalling the fleet." |
| `SessionStart` | `sessionstart.wav` | "Hyperdrive engaged." |
| `SessionEnd` | `sessionend.wav` | "All construction cancelled." |

`SubagentStop` and `TaskCompleted` share a clip by default. Give them separate
sounds by copying a different file over one of them.

Not every event fires in every Claude Code build. To see which ones land on your
machine, run `CLAUDE_SOUND_DEBUG=1 claude` and work normally — each invocation
appends a timestamped line to `~/.claude/sounds/events.log`.

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
| `fleet-command-back-online.wav` | "Fleet command back online." | `SessionStart` |
| `this-is-fleet-command.wav` | "This is Fleet Command," | `SessionStart` |
| `she-is-now-fleet-command.wav` | "She is now Fleet Command." | `SessionStart` |

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
