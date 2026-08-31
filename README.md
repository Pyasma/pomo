# pomo

A pomodoro timer that runs your day for you.

Normal pomodoro apps assume you will open them and press start. That is the
part that fails. `pomo` inverts it: you write the day down once, and a systemd
timer starts each block on its own, tells you what you are supposed to be doing,
and puts you back on it when you drift.

Built for Linux — notifications through `notify-send`, an optional waybar
module, optional Hyprland keybinds, optional push to your phone.

## The timetable

`~/.config/pomo/schedule.conf`:

```
# <days>  <start>  <minutes>  <focus>  <title>
daily  09:00  165  45  Build app - practice project, no AI
daily  12:30  165  45  Open source - land a PR
daily  16:00  165  45  Reverse engineering - one binary
daily  19:30   45  45  Write and post the X thread about today's RE
```

- `days` — `daily`, a range (`mon-fri`), or a list (`mon,wed,fri`)
- `minutes` — how long the whole block runs, rests included. Three 45-minute
  sessions with a 15-minute rest between them is `165`; two is `105`.
- `focus` — one focus session inside it. Rests come from `BREAK_MIN`.

`pomo-sched.timer` ticks every 30 seconds and:

- warns you `PREP_MIN` minutes before a block (10 by default), so it never
  arrives cold
- announces a block the moment it opens, and creates a task for it
- starts the focus session — nothing to press
- puts you back on the block's task if the timer is idle, paused, or on
  something else (breaks are left alone)
- runs every session at its full length: if less than `focus` minutes are left
  in the block, it starts nothing rather than a stub
- marks the task done and stops the timer when the block's window closes

```
pomo sched          # today's checklist: [x] done, [>] now, [ ] later
pomo sched edit     # change the timetable
pomo sched on|off   # enable / disable the tick
```

## Tasks and timer

```
pomo add "write report" -e 4        # 4 estimated pomodoros
pomo add "call bank" -d "today 16:30"
pomo add "deep work" -m 50          # this task focuses in 50m blocks
pomo ls [-a]
pomo start [id] [-m MIN] | pause | resume | toggle | stop | skip
pomo break [-m MIN]
pomo len <id> <MIN|default>
pomo done [id] | rm <id> | use <id>
pomo status | report
```

## Getting it on your phone

Two ways, and they work together.

**Push (instant).** Set `NTFY_TOPIC` in `~/.config/pomo/config.env` to a long
random string, subscribe to the same string in the [ntfy](https://ntfy.sh) app,
and every urgent alert lands on your phone. The topic name is the only secret,
so keep it private.

**Calendar (the day at a glance).** `pomo sched ics` writes an `.ics` file you
can import into any calendar. `pomo sched gcal` publishes it as a secret gist
and prints a URL — subscribe to that URL in Google Calendar ("Other calendars"
→ "From URL") and the calendar re-reads it on its own whenever the timetable
changes.

## Install

```
git clone https://github.com/Pyasma/pomo
cd pomo
./install.sh
```

Needs `bash`, `jq`, `curl`, `notify-send`, and a systemd user session.
Optional extras live in `docs/`: `waybar-module.jsonc`, `hyprland-binds.conf`.
Full reference: [`docs/README.md`](docs/README.md).

## License

MIT
