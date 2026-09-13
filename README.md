# pomo

A task, a timer, and one line in the waybar.

Click the bar. Type what you are about to do. Press enter. The timer is running
and the task exists — there was nothing to set up first, no plan to fill in, no
day to declare. That is the whole app.

Built for Linux — notifications through `notify-send`, a waybar module, Hyprland
keybinds, optional push to your phone.

## The panel

`pomo tui` opens a small floating terminal: the task list, the current timer,
and a prompt that doubles as a filter and as the name of a new task.

```
 idle
 today: 3 pomodoros · 2h15 focus
 ▰▰▰▱  3 of 4 today   ·   󰈸󰈸 5 day streak
────────────────────────────────────────
 task, or a new name > fix auth
   enter start · ctrl-n new · ctrl-d done · ctrl-l length
   ctrl-x delete · ctrl-p pause · ctrl-s stop · ctrl-b break
 ▸ fix the auth bug  (1/3)  45m
   read the issue tracker  (0/1)
```

Typing searches. It never creates anything — creating a task is its own step,
so a search that matches nothing simply matches nothing.

Every action is a button along the bottom — two rows — and they are
clickable, not decoration: `fzf` reports which word the mouse hit and the panel
runs the same action the key printed on it would have.

| key | what it does |
|---|---|
| `enter` on a row | start that task at its own focus length |
| `ctrl-t` | pick its focus length — the choice sticks to the task, then starts |
| `ctrl-b` | rest, at a length you pick |
| `ctrl-n` | new task — name, pomodoros, focus length, each its own small prompt |
| `ctrl-d` | tick the selected task |
| `ctrl-x` | delete it |
| `ctrl-p` | pause / resume |
| `ctrl-s` | stop |
| `esc` | close, change nothing |

Needs `fzf`. `pomo menu` is the same set of actions as a walker list, for when
you would rather not open a window.

## On the bar

On Omarchy Quattro (4.x) the bar is the shell, and pomo has a plugin for it:
[omarchy-pomo](https://github.com/Pyasma/omarchy-pomo). One flame on the bar
with the streak's day count written on it, the timer's arc drawn round it,
and the popup with the timer, the goal and the task list under a click.
`docs/hyprland-binds.lua` has the keys.

```
omarchy plugin add https://github.com/Pyasma/omarchy-pomo.git
omarchy plugin enable io.github.pyasma.pomo --section right
```

On Omarchy 3.x, or any waybar setup, `docs/waybar-module.jsonc` — left-click opens the panel, right-click starts or
pauses without opening anything, middle-click stops.

The module is a single clock glyph, exactly as wide as the tray icons beside
it. Its hand sweeps clockwise as the phase runs out — filled while a timer
runs, outline when nothing does — so the bar shows progress without spending a
character on digits. The minutes, the task and today's totals live in the
tooltip; `BAR_TIME=1` in `config.env` prints the minutes next to the clock if
you want the number back. `docs/hyprland-binds.conf` has `Super+Alt+P` (start/pause),
`Super+Alt+M` (panel), and the rule that keeps the panel floating.

Either way `pomo` tells the bar the moment something changes — a signal to
waybar, an IPC call to the shell — so the glyph never waits for a poll.

## The streak

`GOAL` in `config.env` is how many pomodoros make a day count. Clear it and
the day is green; consecutive green days are your streak, and the streak is
on fire — one flame from the first day, two from three, three from seven, and
the colour climbs from ember to white-hot as the run gets longer. Both numbers
are computed from the log, so there is nothing to roll over and nothing to
keep in sync. Today not being done yet does not break the run; a day you
never clear does.

## Tasks and timer, from the shell

```
pomo new "write report"             # add it and start the timer, one step
pomo new "deep work" -m 50          # 50-minute focus blocks
pomo add "call bank" -d "today 16:30"
pomo add "write report" -e 4        # 4 estimated pomodoros, not started
pomo                                # list tasks
pomo start [id] [-m MIN] | pause | resume | toggle | stop | skip
pomo break [-m MIN]
pomo len <id> <MIN|default>
pomo done [id] | rm <id> | use <id>
pomo status | report
```

## Planned days, if you want them

There is a second layer that turns pomo into a checklist for a planned day: a
fixed number of sessions, each with a minute budget and a focus length, read
from `~/.config/pomo/sessions.conf`. It is off unless you ask for it.

```
SESSIONS=1        # in ~/.config/pomo/config.env
```

Then `pomo s` prints the checklist, `pomo s start` runs the next unfinished
session, `pomo streak` counts the days you cleared all of them, and the waybar
shows `S2 1/4` instead of the task name. `pomo s edit` changes the plan;
`systemctl --user enable --now pomo-tick.timer` rolls the day over at midnight
and warns when a session runs past its budget.

With `SESSIONS=0` none of that runs and none of it is read — no session file is
touched, no streak is counted, nothing rolls over.

## Getting it on your phone

Set `NTFY_TOPIC` in `~/.config/pomo/config.env` to a long random string,
subscribe to the same string in the [ntfy](https://ntfy.sh) app, and every
urgent alert lands on your phone. The topic name is the only secret, so keep it
private.

## Install

```
git clone https://github.com/Pyasma/pomo
cd pomo
./install.sh
```

Needs `bash`, `jq`, `fzf`, `curl`, `notify-send`, and a systemd user session.
Optional extras live in `docs/`: `hyprland-binds.lua` (Quattro),
`waybar-module.jsonc` and `hyprland-binds.conf` (3.x).
Full reference: [`docs/README.md`](docs/README.md).

## License

MIT
