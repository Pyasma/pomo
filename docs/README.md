# pomo

A task, a timer, and one line in the waybar. Integrated into Omarchy (Hyprland
+ waybar + mako).

## Parts

| Piece | Path |
|---|---|
| CLI | `~/.local/bin/pomo` |
| Config | `~/.config/pomo/config.env` |
| Data | `~/.local/share/pomo/{tasks.json,state.json,log.jsonl}` |
| Goal | `GOAL` in `config.env` |
| Panel | `pomo tui` — an fzf screen in a floating terminal (`org.omarchy.pomo`) |
| Waybar module | `custom/pomodoro` in `~/.config/waybar/config.jsonc` (signal 11) |
| Keybinds | bottom of `~/.config/hypr/bindings.conf` |
| Sessions | `~/.config/pomo/sessions.conf`, state in `~/.local/share/pomo/sessions.json` |
| Timers | `~/.config/systemd/user/pomo-{nag,daily,tick}.timer` |

## The panel

`pomo tui`, waybar left-click, or `Super+Alt+M`. One fzf screen: the task list,
the current timer above it, and a search box that only ever searches.

| key | what it does |
|---|---|
| `enter` on a row | start that task at its own focus length |
| `ctrl-t` | pick its focus length — it sticks to the task, then starts |
| `ctrl-b` | pick a rest length, then break |
| `ctrl-n` | new task — name, pomodoros, focus length (panel stays open) |
| `ctrl-d` | tick the selected task (panel stays open) |
| `ctrl-x` | delete it |
| `ctrl-p` | pause / resume |
| `ctrl-s` | stop |
| `esc` | close, change nothing |

The bottom of the panel is ten buttons in two justified rows of five, all in the
panel's one accent colour — every action is clickable, so every action looks the
same. Labels are left-aligned inside their cell on purpose: centring them gives
every label a different leading offset and the rows stop lining up. Picking a length and setting a length used to be two separate
actions doing nearly the same thing; they are now one (`ctrl-t`), and the length
you pick becomes the task's own.

The buttons are really clickable: fzf's `click-footer` event reports the word under the
mouse in `FZF_CLICK_FOOTER_WORD`, `pomo _tuiclick` maps that word (or the key
printed on the button) to an fzf action string, and fzf's `transform` binding
runs it. Actions that leave the panel end in `+abort`; the rest reload the list
in place. Adding a button means adding a label and a case arm, nothing else.

The panel paints its own background rather than inheriting the terminal's. A
translucent terminal — ghostty's `background-opacity`, say — cannot be made
opaque by a Hyprland `opacity` rule, because the alpha is in the surface the app
draws; setting fzf's `bg` is what actually fills it.

Every prompt the panel raises — the new-task name, its pomodoro count, its
focus length, the rest length — is the same fzf frame with the
same border and colours, and every one of them shows `esc back · ↵ choose` at
its foot. Escape from a prompt returns to the list rather than closing the
panel, and escaping part-way through creating a task abandons the whole thing
instead of falling back on defaults nobody chose.

A prompt runs inside fzf's `execute`, which cannot tell fzf what to do next, so
it leaves a one-word note in `~/.local/share/pomo/.panel` and a `transform`
binding reads it: `close` if the prompt actually started a timer, nothing
otherwise. The panel clears a stale note on open, so a prompt that died badly
cannot close the next session on sight. They used to be bare `read` calls, which showed the terminal's own
background instead of the panel's and echoed stray escape sequences when a key
like F12 was pressed.

The two length pickers are lists you can also type into, and what you type wins
over what the filter narrowed to — otherwise `4` would silently become the `45`
it matched. Anything from 1 to 600 minutes is accepted.

The window is 980x660 (`docs/hyprland-binds.conf`); the clock in the head draws
with a heavier stroke once the panel is at least 96 columns wide.

The id lives in a hidden first column, so a task called `#7 revisit` cannot be
mistaken for task 7.

## Keybinds

- `Super+Alt+P` — start / pause / resume the timer
- `Super+Alt+M` — the panel

## Checking tasks

- The panel, or `pomo ls` in a terminal — `▸` marks the current task,
  `(done/est)` is pomodoro progress, a trailing `50m` is a custom focus length.
  `pomo ls -a` also shows completed ones.
- Hover the waybar module — the tooltip shows the timer and today's totals.
- `pomo show` — the list as a mako notification, no terminal needed.
- `pomo report` — pomodoros and focus minutes today, per task, plus last 7 days.

## Waybar

Left-click opens the panel, right-click starts or pauses the timer without
opening anything, middle-click stops.

One glyph, no more — it sits among the tray icons without stretching the bar.

The glyph is a clock face from the Nerd Font `clock-time-*` family, picked from
how far the current phase has run: twelve o'clock at the start, sweeping
clockwise to eleven as it ends. Filled while a timer runs, outline when nothing
does, and the phase colour says which timer it is. Everything else — the
minutes, which task, today's totals, the goal and streak — is in the tooltip.

`BAR_TIME=1` in `config.env` appends the minutes (`󱑂 32`) for when you want the
number on the bar as well.

With `SESSIONS=1` the idle glyph carries the session score, `󰄬` means all of
them are done, and `󰀦` marks one past its budget.

The app's own logo lives in `assets/pomo.svg` and is installed to
`~/.local/share/icons/hicolor/scalable/apps/pomo.svg`, with `pomo.desktop`
pointing `StartupWMClass` at `org.omarchy.pomo` so the floating panel window
carries it too.

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
pomo tui                                      # the panel
pomo new "fix the auth bug" [-m MIN]          # add and start in one step
pomo                                          # list tasks
pomo s start [n] | stop | skip [n] | edit     # sessions (SESSIONS=1)
pomo s add "open the PR" [-s n] [-e N]        # a task inside a session
pomo streak                                   # streak, best, last 14 days
pomo push [test]                              # phone push over ntfy
```

## The shell plugin

`pomo json` prints everything a bar or a popup needs in one object: `phase`,
`label`, `task`, `title`, `total`/`elapsed`/`remaining` seconds, `today`,
`minutes`, `goal`, `streak`, `fire` (the glyphs) and `tier` (0–4, the colour
step), `work_min`, `break_min`, `sessions` (null unless `SESSIONS=1`) and the
active `tasks`. It is one jq per file and takes about 25 ms, so a caller can
poll it once a second while a timer runs.

[omarchy-pomo](https://github.com/Pyasma/omarchy-pomo) is that caller: a
`service` + `bar-widget` plugin for the Omarchy Quattro shell. Its actions are
plain `pomo` commands, and `refresh_bar` pings it back over
`omarchy-shell pomo refresh` after every change.

## The streak

`GOAL` (`config.env`, default 4) is the pomodoros a day needs to count. Today's
count against it and the run of consecutive days that cleared it both show in
the panel head — the bar turns green the moment you clear it — and in the waybar
tooltip. Both are derived from `log.jsonl` on every read, so no timer rolls them
over and nothing can drift out of sync.

`streak_fire <days>` turns the run into flames: `󰈸` for 1–2 days, `󰈸󰈸` from 3,
`󰈸󰈸󰈸` from 7, with the 256-colour code climbing 208 → 214 → 220 → 231 (from
14). The panel, the waybar tooltip, `pomo streak` and the end-of-focus
notification all use it. With `SESSIONS=1` the session streak in
`sessions.json` gets the same flames.

## Custom session lengths

Three levels, most specific wins:

1. **One-off** — `pomo start -m 45`.
2. **Per task** — `pomo new "deep work" -m 50`, `pomo len 3 50` afterwards, or
   `ctrl-l` in the panel. Every `pomo start` on that task uses 50m;
   `pomo len 3 default` clears it.
3. **Global defaults** — `WORK_MIN`, `BREAK_MIN`, `LONG_MIN`, `CYCLES` in
   `~/.config/pomo/config.env`. No restart needed; the next session picks them up.

Breaks after a work session use `BREAK_MIN`/`LONG_MIN`; `pomo break -m 20`
starts a one-off break of any length. Logged minutes reflect the real session
length, so `pomo report` stays accurate with mixed durations.

## Finishing or deleting the task it is timing

A timer belongs to its task. Tick that task or delete it — from the panel, the
CLI, or the walker menu — and the clock stops and resets to zero: the pending
alarm is cancelled, the phase goes back to idle and the waybar clock returns to
its outline face. Only the task actually being timed does this; ticking some
other task leaves a running focus alone.

## How the timer fires

`pomo start` writes a deadline into `state.json` and schedules a transient
systemd user timer (`pomo-alarm`) that runs `pomo _fire` at the deadline, so the
notification lands even if waybar or the terminal is closed. Work ends
auto-start a break (`AUTO_BREAK=1`); after `CYCLES` work sessions the break is a
long one. Breaks end back to idle unless `AUTO_WORK=1`.

## Sessions (`pomo s`) — off by default

A second layer that turns pomo into a checklist for a planned day. Set
`SESSIONS=1` in `config.env` to use it; with `SESSIONS=0` none of it runs and
`sessions.json` is never touched, so the bar shows tasks instead of `S2 1/4`.

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
  takes that one. Only one session runs at a time. `Super+Alt+P` starts the
  next session instead of the current task while `SESSIONS=1`.
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

- `pomo-nag.timer` fires every 10 min but nudges at most every `NAG_MIN`
  minutes of quiet: tasks past their due time always, plus a reminder that
  tasks are open while nothing is running (`NAG_MIN=0` disables the nudge).
- `pomo-daily.timer` at 18:30: focus minutes and pomodoros, or the session
  score and streak with `SESSIONS=1`.
- `pomo-tick.timer` is only for `SESSIONS=1` and is left disabled: it rolls the
  day at midnight, pushes the morning agenda (`AGENDA_AT`), and warns once when
  a session passes its budget. Enable it with
  `systemctl --user enable --now pomo-tick.timer`.

Change durations, sounds, and auto-advance in `~/.config/pomo/config.env`.
