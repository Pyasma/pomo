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
| Reminder timers | `~/.config/systemd/user/pomo-{nag,daily}.timer` |

## Keybinds

- `Super+Alt+P` — start / pause / resume
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

Left-click toggles the timer, right-click opens the menu, middle-click stops.
Icons: `󰔛` idle (with pending task count), `󰔟` focus, `󰅶` break, `󰏤` paused.

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
pomo sched [edit|on|off|ics|gcal]             # timetable / today's checklist
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

## Timetable (`pomo sched`)

The day is a list of blocks in `~/.config/pomo/schedule.conf`. A systemd timer
(`pomo-sched.timer`) ticks every 30 seconds and runs the block that is due, so
the timer starts itself — nothing to press.

```
# <days>  <start>  <minutes>  <focus>  <title>
daily  09:00  165  45  Build app - practice project, no AI
daily  12:30  165  45  Open source - land a PR
daily  16:00  165  45  Reverse engineering - one binary
daily  19:30   45  45  Write and post the X thread about today's RE
```

`minutes` covers the rests too: three 45-minute sessions with a 15-minute rest
between them is `165`. Rest length is `BREAK_MIN` in `config.env`.

`days` is `daily`, a range (`mon-fri`), or a list (`mon,wed,fri`). `minutes` is
how long the whole block runs; `focus` is one session inside it.

What a tick does:

- `PREP_MIN` minutes before a block (10 by default), a heads-up notification
  names what is coming and when. `PREP_MIN=0` turns it off.
- At a block's start, a critical notification says what to do, and a task is
  created for it (title = the block title, `est` = sessions that fit).
- If the timer is idle, paused, or on some other task while a block is open, it
  is put back on the block's task. Breaks are left alone.
- A session runs its full length or not at all: with less than `focus` minutes
  left in the block, nothing new starts.
- When a block's window closes, its task is marked done and any session still
  running is stopped.

```
pomo sched          # today's checklist: [x] done, [>] now, [ ] later
pomo sched edit     # edit the timetable ($EDITOR)
pomo sched on|off   # enable/disable the tick timer
```

Editing `schedule.conf` takes effect on the next tick; no restart.

## Phone (ntfy)

Urgent alerts — block start, focus done, task due, the daily summary — are also
pushed to `ntfy.sh` so they reach a phone. Set `NTFY_TOPIC` in `config.env` and
subscribe to that same topic in the ntfy app (Android, iOS, or the web).

The topic name is the only secret: anyone who knows it can read the pushes, so
keep it long and random and do not share it.

- `PUSH_ALL=1` mirrors every notification, not just the urgent ones.
- `AGENDA_AT=08:00` pushes the whole day's checklist each morning (empty to
  disable).
- `pomo push test` sends a test message.

## Calendar

The timetable also exports as an iCalendar file, so a phone's calendar app can
show the day without ntfy.

- `pomo sched ics [path]` — write the `.ics` (default
  `~/.local/share/pomo/timetable.ics`) and import it by hand.
- `pomo sched gcal` — upload that file to a secret gist and print a URL. Add it
  in Google Calendar under *Other calendars → From URL*. Re-run it after
  editing `schedule.conf`; the gist keeps the same URL, and Google re-reads it
  on its own schedule (hours, not seconds).

Events are weekly-recurring with two alarms: one at the start, one `PREP_MIN`
minutes before. Each one carries the machine's own timezone as a `TZID`, so the
blocks land at the hour you wrote no matter where the calendar is read.

## Reminders

- `pomo-nag.timer` every 10 min: notifies about tasks past their due time, and
  nudges when the timer is idle but tasks are pending (`NAG_MIN=0` disables the
  nudge).
- `pomo-daily.timer` at 18:30: pomodoro count, focus minutes, tasks left.
- `pomo-sched.timer` every 30 s: runs the timetable (see above).

Change durations, sounds, and auto-advance in `~/.config/pomo/config.env`.
