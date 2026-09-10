# pomo

Pomodoro timer with task tracking, integrated into Omarchy (Hyprland + waybar + mako).

## Parts

| Piece | Path |
|---|---|
| CLI | `~/.local/bin/pomo` |
| Config | `~/.config/pomo/config.env` |
| Data | `~/.local/share/pomo/{tasks.json,state.json,log.jsonl}` |
| Waybar module | `custom/pomodoro` in `~/.config/waybar/config.jsonc` (signal 11) |
| Keybinds | bottom of `~/.config/hypr/bindings.conf` |
| Sessions | `~/.config/pomo/sessions.conf`, state in `~/.local/share/pomo/sessions.json` |
| Timers | `~/.config/systemd/user/pomo-{nag,daily,tick}.timer` |

## Keybinds

- `Super+Alt+P` — start the next session / pause / resume
- `Super+Alt+Shift+P` — stop
- `Super+Alt+T` — add task (walker prompt: `title | est | due | minutes`)
- `Super+Alt+O` — pick task and start focusing
- `Super+Alt+D` — mark a task done
- `Super+Alt+L` — show the task list as a notification
- `Super+Alt+M` — action menu

## Checking tasks

- `pomo ls` in a terminal — `▸` marks the current task, `(done/est)` is
  pomodoro progress, a trailing `50m` means a custom focus length.
  `pomo ls -a` also shows completed ones.
- `Super+Alt+L` (or menu entry `Show tasks`) — same list as a mako notification,
  no terminal needed.
- Hover the waybar module — the tooltip shows the current task and progress, or
  the pending count and next-up task when idle.
- `Super+Alt+O` — walker list of open tasks; picking one starts focusing on it.
- `pomo report` — pomodoros and focus minutes today, per task, plus last 7 days.

## Waybar

Left-click starts the next session or pauses the running one, right-click opens
the menu, middle-click halts the session.

Icons: `󰔛` idle (next session and how many are done), `󰔟` focus, `󰅶` break,
`󰏤` paused, `󰄬` all three done (with the streak), `󰀦` past the session's budget.

Classes for `style.css`: `idle`, `ready`, `work`, `break`, `long`, `paused`,
`over`, `alldone`.

## CLI

```
pomo add "write quarterly report" -e 4        # 4 estimated pomodoros
pomo add "call bank" -d "today 16:30"         # due time, parsed by `date -d`
pomo add "deep work" -m 50                    # this task focuses in 50m blocks
pomo ls [-a]
pomo start [id] [-m MIN] | pause | resume | toggle | stop | skip
pomo break [-m MIN]                           # start a break of your own length
pomo len <id> <MIN|default>                   # change a task's focus length
pomo done [id] | rm <id> | use <id>
pomo status | report
pomo                                          # today's checklist
pomo s start [n] | stop | skip [n] | edit     # sessions
pomo s add "open the PR" [-s n] [-e N]        # a task inside a session
pomo streak                                   # streak, best, last 14 days
pomo push [test]                              # phone push over ntfy
```

## Custom session lengths

Three levels, most specific wins:

1. **One-off** — `pomo start -m 45`, or the menu entry `Custom focus length`
   (`Super+Alt+M`), which offers 15/25/30/45/50/60/90.
2. **Per task** — `pomo add "deep work" -m 50`, or `pomo len 3 50` afterwards.
   Every `pomo start` on that task uses 50m. `pomo len 3 default` clears it.
   The walker add prompt (`Super+Alt+T`) takes it as a fourth field:
   `title | est | due | minutes`.
3. **Global defaults** — `WORK_MIN`, `BREAK_MIN`, `LONG_MIN`, `CYCLES` in
   `~/.config/pomo/config.env`. No restart needed; the next session picks them up.

Breaks after a work session use `BREAK_MIN`/`LONG_MIN`; `pomo break -m 20`
starts a one-off break of any length. Logged minutes reflect the real session
length, so `pomo report` stays accurate with mixed durations.

## How the timer fires

`pomo start` writes a deadline into `state.json` and schedules a transient
systemd user timer (`pomo-alarm`) that runs `pomo _fire` at the deadline, so the
notification lands even if waybar or the terminal is closed. Work ends
auto-start a break (`AUTO_BREAK=1`); after `CYCLES` work sessions the break is a
long one. Breaks end back to idle unless `AUTO_WORK=1`.

## Sessions (`pomo s`)

The day is a fixed amount of work in `~/.config/pomo/sessions.conf`, split into
sessions you start whenever you are ready. There are no days and no start times.

```
# <minutes>  <focus>  <title>
165  45  Build app - practice project, no AI
165  45  Open source - land a PR
210  45  Reverse engineering + write the X post
```

`minutes` covers the rests too: three 45-minute focus sessions with a 15-minute
rest between them is `165`. Rest length is `BREAK_MIN` in `config.env`.

Rules:

- `pomo s start` takes the next session that is not finished; `pomo s start 3`
  takes that one. Only one session runs at a time.
- A session with no tasks gets one from its own title, with `est` set to the
  number of focus sessions its budget is worth. Add more with `pomo s add`.
- **A session is finished when every task in it is ticked** — by `pomo done`,
  `pomo s done`, `Super+Alt+D`, or the menu. Ticking the last one closes the
  session, stops the timer, and says how many are left today.
- `minutes` is a budget, not a cutoff. Nothing stops when it runs out: the
  waybar module turns amber and one notification says so.
- `pomo s stop` halts a session and keeps its progress; `pomo s skip` writes one
  off on purpose.
- At midnight the day rolls: unfinished sessions are recorded as missed, the
  day's score goes into `log.jsonl`, and the streak — consecutive days where
  every session was finished — is updated. Tasks do not carry over.

```
pomo                # today's checklist: [x] done, [>] running, [~] halted, [ ] not started
pomo s edit         # edit sessions.conf ($EDITOR)
pomo s on|off       # enable/disable pomo-tick.timer
pomo streak         # streak, best, and the last 14 days
```

Editing `sessions.conf` takes effect immediately; no restart.

### Migrating from the timetable

The first run after upgrading converts `schedule.conf` into `sessions.conf`:
each block loses its `days` and `start`, and any block past the third is folded
into the third so the day keeps exactly the same total minutes. The old file is
kept as `schedule.conf.bak`.

## Phone (ntfy)

Urgent alerts — a session finishing, focus done, a session over its budget, a
task due, the daily summary — are also pushed to `ntfy.sh` so they reach a phone. Set `NTFY_TOPIC` in `config.env` and
subscribe to that same topic in the ntfy app (Android, iOS, or the web).

The topic name is the only secret: anyone who knows it can read the pushes, so
keep it long and random and do not share it.

- `PUSH_ALL=1` mirrors every notification, not just the urgent ones.
- `AGENDA_AT=08:00` pushes the whole day's checklist each morning (empty to
  disable).
- `pomo push test` sends a test message.

## Reminders

- `pomo-nag.timer` every 10 min: notifies about tasks past their due time, and
  nudges when nothing is running and sessions are still open (`NAG_MIN=0`
  disables the nudge).
- `pomo-daily.timer` at 18:30: sessions done, focus minutes, streak.
- `pomo-tick.timer` every 30 s: rolls the day at midnight, pushes the morning
  agenda (`AGENDA_AT`), and warns once when a session passes its budget. It
  never starts a session for you.

Change durations, sounds, and auto-advance in `~/.config/pomo/config.env`.
