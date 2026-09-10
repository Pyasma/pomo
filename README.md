# pomo

Three sessions a day, started whenever you are ready.

A timetable fails the moment you miss the 09:00 it insists on. `pomo` drops the
clock: the day is a fixed amount of work split into a few sessions, and you
start one whenever you sit down. A session is finished when its tasks are
ticked, not when the hour is up.

Built for Linux — notifications through `notify-send`, an optional waybar
module, optional Hyprland keybinds, optional push to your phone.

## The sessions

`~/.config/pomo/sessions.conf`:

```
# <minutes>  <focus>  <title>
165  45  Build app - practice project, no AI
165  45  Open source - land a PR
210  45  Reverse engineering + write the X post
```

- `minutes` — what the session is worth, rests included. Three 45-minute focus
  sessions with a 15-minute rest between them is `165`. This is a budget, not a
  deadline: run over and the bar turns amber, nothing stops.
- `focus` — one focus session inside it. Rests come from `BREAK_MIN`.

No days, no start times. A session runs when you start it:

```
pomo                # today's checklist
pomo s start        # the next unfinished session
pomo s start 3      # that one
pomo s add "open the PR" -e 2
pomo s done 4       # tick a task
pomo s stop         # halt, keep the progress
pomo s skip 2       # write a session off on purpose
pomo s edit         # change what the sessions are
pomo streak         # streak, best, last 14 days
```

The checklist:

```
Today  ·  1/3 sessions  ·  streak 4d

[x] S1  Build app - practice project, no AI     3/3 focus   2h45 / 2h45
[>] S2  Open source - land a PR                 1/4 focus   0h45 / 2h45
      [x] #4  read the issue tracker            1/1
      [ ] #5  repro the bug                     0/2
      [ ] #6  open the PR                       0/1
[ ] S3  Reverse engineering + write the X post  0/5 focus   0h00 / 3h30
```

A session closes itself the moment its last task is ticked. Sessions you never
finish are written off at midnight, and the streak — days where all three were
done — resets.

`pomo-tick.timer` ticks every 30 seconds. It starts nothing: it rolls the day
over, pushes the morning agenda, and warns once when a session runs past its
budget.

Upgrading from the old timetable: the first run converts `schedule.conf` into
`sessions.conf` on its own, folding any block past the third into the third so
the day keeps the same total minutes. The old file is kept as
`schedule.conf.bak`.

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

**Push (instant).** Set `NTFY_TOPIC` in `~/.config/pomo/config.env` to a long
random string, subscribe to the same string in the [ntfy](https://ntfy.sh) app,
and every urgent alert lands on your phone. The topic name is the only secret,
so keep it private.

**Calendar.** Gone with the clock — there is nothing left to put in a calendar
slot. `AGENDA_AT` pushes the day's checklist each morning instead.

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
