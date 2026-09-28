# Claude Fleet Command Pack

Mainly for the "research complete" notification for when I'm away from my computer. I spent some time going through other sfx but didn't find any I liked more than that. 

obv audio is not mine, it's easy to scrape from the original games, will take down if requested. 


You don't need to clone this to use it, can just take the one audio file and ask your agent to have it fire when a response is done, there's additional tools for previewing the audio, I think some don't work atm, I ended up busy with other things.

below is claude:

--------------------------------------------------------

Homeworld Fleet Intelligence callouts and interface sounds as
[Claude Code](https://claude.com/claude-code) hooks. Your terminal tells you a
turn finished — in the voice of the Mothership.

**One hook wired by default**: `Stop`, playing "Research complete." Everything
else ships ready but unwired, because a callout you didn't ask for
mid-conversation is noise. Add what you want from the table below.

## Install

```sh
git clone https://github.com/highbypassfan/claude-fleet-command-pack.git
cd claude-fleet-command-pack
./install.sh
```

Copies the sounds to `~/.claude/sounds/` and merges the hook into
`~/.claude/settings.json` (backing up whatever was there first). Restart Claude
Code, or open `/hooks` once, to load it.

`./install.sh --no-hooks` copies the sounds and prints the hook block to merge
by hand.

## Volume

Everything plays at **50%** by default. Change it by writing a number 0-100 into
the `volume` file next to `claude-sound.sh`:

```sh
echo 75 > ~/.claude/sounds/volume
```

A file rather than an env var, because hooks do not reliably inherit your
shell's environment. `CLAUDE_SOUND_VOLUME=80` still works for a one-off.

At 100 the Windows player uses `SoundPlayer`; below that `MediaPlayer`, which
supports volume and falls back to `SoundPlayer` if it cannot load. macOS uses
`afplay -v`, Linux `paplay --volume` or `ffplay -volume`. `aplay` has no volume
control and always plays full.

## Playing a sound

```sh
~/.claude/sounds/claude-sound.sh done            # a wired name
~/.claude/sounds/claude-sound.sh buildmenuonoff  # any clip in the pack
```

Names resolve against `homeworld/`, then `homeworld/alternates/`, then
`homeworld/ui/`, then `homeworld/ui/aliases.txt`. An unknown name prints to
stderr — hooks discard it, a human running the script by hand gets told.

The game reuses one recording across many interface events, so 48 distinct
clips carry 111 names. `aliases.txt` maps the rest onto the clip that holds the
audio, so any name from the game works.

## Hearing them all

Open `audition.html` (in `~/.claude/sounds/` after install) in a browser. Every
clip in the pack, grouped by what it suits, click to play, arrow keys to move,
space to replay, and a filter box. Each row shows length and a peak-level bar,
which matters because the interface clips range from 8% to 91% of full scale.

## Wiring more events

Add to `hooks` in `~/.claude/settings.json`, substituting the event name and the
sound:

```json
"StopFailure": [
  { "hooks": [ { "type": "command", "command": "\"$HOME/.claude/sounds/claude-sound.sh\" fail", "async": true, "timeout": 10 } ] }
]
```

| Event | Fires when | Suggested sound |
|---|---|---|
| `Stop` **(wired)** | turn finished | `done` — "Research complete." |
| `StopFailure` | turn ended in an error | `fail` — "Hyperspace jump interrupted." |
| `Notification` | Claude surfaces something | `input` — "Construction paused." |
| `PermissionRequest` | before a permission prompt | `confirm` — "Confirm attack on friendly unit." |
| `PermissionDenied` | you rejected a prompt | `denied` — "Order cancelled." |
| `PreCompact` | context about to compact | `compact` — "Marshalling the fleet." |
| `SessionStart` | session opens | `sessionstart` — "Hyperdrive engaged." |
| `SessionEnd` | session closes | `sessionend` — "All construction cancelled." |
| `SubagentStop` | a subagent finishes | `agentdone` — "Ships transferred." |
| `TaskCompleted` | a background task finishes | `agentdone` — "Ships transferred." |

Two worth knowing before you wire them. `Notification` fires whenever Claude
surfaces something, not only when it needs you, so it can talk mid-conversation.
`SubagentStop` and `TaskCompleted` tend to land at the same moment the turn
ends, giving two callouts for one event.

Hooks fire asynchronously, so two can land together. `claude-sound.sh` takes a
lock: the first callout plays, overlapping ones exit silently. Dropped rather
than queued, because a backlog of stale callouts is worse than a missed one.

Not every event fires in every Claude Code build. To see which land on yours,
`touch ~/.claude/sounds/debug` (or `CLAUDE_SOUND_DEBUG=1`) and work normally —
each invocation appends a line to `~/.claude/sounds/events.log`.

## Voice lines

`homeworld/` holds the wired names; `homeworld/alternates/` the rest. To change
what an event plays, copy over the primary:

```sh
cp ~/.claude/sounds/homeworld/alternates/upgrade-complete.wav \
   ~/.claude/sounds/homeworld/done.wav
```

| File | Line |
|---|---|
| `done.wav` | "Research complete." |
| `fail.wav` | "Hyperspace jump interrupted." |
| `input.wav` | "Construction paused." |
| `confirm.wav` | "Confirm attack on friendly unit." |
| `denied.wav` | "Order cancelled." |
| `agentdone.wav` | "Ships transferred." |
| `compact.wav` | "Marshalling the fleet." |
| `sessionstart.wav` | "Hyperdrive engaged." |
| `sessionend.wav` | "All construction cancelled." |

Alternates: `upgrade-complete`, `hyperspace-jump-complete`,
`hyperspace-jump-aborted`, `proximity-alert`, `insufficient-resources`,
`new-research-available`, `construction-stopped`, `weapon-systems-powered-down`,
`waypoint-confirmed`, `production-underway`, `production-confirmed`,
`initiate-production`, `guarding-fleet`, `scout-squadron-complete`,
`probe-complete`, `hyperdrive-engaged`.

Plus three from Homeworld 1 campaign narration — `fleet-command-back-online`,
`this-is-fleet-command`, `she-is-now-fleet-command`. Different voice actor and a
noisier recording than the rest; they sound out of place mid-session.

## Interface sounds

`homeworld/ui/` holds 48 clips from the game's interface — 0.03s to 12s, mostly
blips well under a second. Short enough to use where a spoken line would be too
much, e.g. a click on `PermissionRequest`.

| Clip | Where it's from |
|---|---|
| `buildmenuonoff` | opening/closing the build menu |
| `launchmenuonoff` | the launch manager |
| `sensorsmanagerin` / `sensorsmanagerout` | entering and leaving the sensors manager |
| `uie_commandclick` | issuing a command |
| `mouserollover` | hovering a control |
| `contactfound` / `contactloss` | a contact appearing or dropping |
| `combatdetectedping`, `battlebracketping` | combat alerts |
| `hyperspacepingin` / `hyperspacepingout` | hyperspace events |
| `movementguichimes`, `movementdisc` | the move disc |
| `closedropdownlist`, `collapsepanel`, `enterpopupmenu` | front-end menus |

Levels vary a lot in the originals — 8% to 91% of full scale — so audition
before wiring one, and use the `volume` file to tame the loud ones.

## Platform support

`claude-sound.sh` is POSIX sh and picks a player at runtime:

| Platform | Player |
|---|---|
| macOS | `afplay` |
| Linux | `paplay` → `ffplay` → `aplay` |
| WSL | falls through to `powershell.exe` |
| Windows (Git Bash/MSYS/Cygwin) | `powershell.exe` + `MediaPlayer`/`SoundPlayer` |

Claude Code runs hooks through bash wherever Git Bash is present, which is the
normal Windows install. On a Windows box with **no** Git Bash, hooks run through
PowerShell and the hook command won't resolve — install Git Bash, or swap in a
PowerShell one-liner.

If no player is found the script exits 0 silently, so a hook can never break a
session. Hooks are `async` with a 10s timeout, so a clip never blocks a turn.

## Where the audio came from

Homeworld Remastered ships its audio in Relic SGA v2 archives (`.big`).
`tools/big.py` is a standalone parser for that format — it lists and extracts
any Relic `.big`:

```sh
python tools/big.py ".../HomeworldRM/Data/EnglishSpeech.big"
```

Speech lives in `EnglishSpeech.big` under `sound\speech\allships\fleet\`,
already 44.1 kHz mono PCM, and is shared between Homeworld 1 and 2 Remastered.

Sound effects are different: every one is `.fda`, AIFF-C wrapping "Relic Codec
v1.6", and there are no PCM copies anywhere in the game. Decoding them needs
[vgmstream](https://github.com/vgmstream/vgmstream), which has a Relic decoder:

```sh
vgmstream-cli -o out.wav "sound/sfx/ui/sensorsmanager/buildmenuonoff.fda"
```

The three Homeworld 1 clips were cut from `EnglishSpeechHW1Campaign.big`
narration at clause boundaries, with a 15 ms fade-in, a 60 ms fade-out and a
gentle taper above 9 kHz. Everything else is untouched.

## Licence

`claude-sound.sh`, `install.sh`, `tools/big.py` and this README are MIT licensed —
see [LICENSE](LICENSE).

**The audio is not.**  They are included here for personal, non-commercial use by 
people who own the game. No ownership is claimed and no endorsement is implied. 
If you represent the rights holder and want them gone, open an issue and I'll remove them.

---

Built by [@acheronix](https://x.com/acheronix) on X (and Claude! - A)
