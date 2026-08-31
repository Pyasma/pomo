#!/usr/bin/env bash
# Install pomo for the current user.
set -euo pipefail

BIN="$HOME/.local/bin"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/pomo"
UNITS="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for dep in jq curl notify-send systemctl; do
  command -v "$dep" >/dev/null || { echo "missing dependency: $dep" >&2; exit 1; }
done

mkdir -p "$BIN" "$CONF" "$UNITS"
install -m 755 "$SRC/pomo" "$BIN/pomo"
[[ -f $CONF/config.env ]]    || cp "$SRC/config.env.example" "$CONF/config.env"
[[ -f $CONF/schedule.conf ]] || cp "$SRC/schedule.conf.example" "$CONF/schedule.conf"
cp "$SRC/docs/README.md" "$CONF/README.md"
install -m 644 "$SRC"/systemd/pomo-*.{service,timer} "$UNITS/"

systemctl --user daemon-reload
systemctl --user enable --now pomo-nag.timer pomo-daily.timer pomo-sched.timer

cat <<'DONE'

pomo installed.

  pomo sched          today's timetable
  pomo sched edit     change it
  pomo ls             tasks

Optional:
  - waybar module: docs/waybar-module.jsonc
  - hyprland binds: docs/hyprland-binds.conf
  - phone push:     set NTFY_TOPIC in ~/.config/pomo/config.env
  - calendar:       pomo sched ics, then import the file
DONE
