#!/usr/bin/env bash
# Install pomo for the current user.
set -euo pipefail

BIN="$HOME/.local/bin"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/pomo"
UNITS="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICONS="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for dep in jq fzf curl notify-send systemctl; do
  command -v "$dep" >/dev/null || { echo "missing dependency: $dep" >&2; exit 1; }
done

mkdir -p "$BIN" "$CONF" "$UNITS" "$APPS" "$ICONS"
install -m 755 "$SRC/pomo" "$BIN/pomo"
[[ -f $CONF/config.env ]]    || cp "$SRC/config.env.example" "$CONF/config.env"
[[ -f $CONF/sessions.conf ]] || cp "$SRC/sessions.conf.example" "$CONF/sessions.conf"
cp "$SRC/docs/README.md" "$CONF/README.md"
install -m 644 "$SRC/pomo.desktop" "$APPS/pomo.desktop"
install -m 644 "$SRC/assets/pomo.svg" "$ICONS/pomo.svg"
install -m 644 "$SRC"/systemd/pomo-*.{service,timer} "$UNITS/"

systemctl --user daemon-reload
systemctl --user enable --now pomo-nag.timer pomo-daily.timer pomo-tick.timer

cat <<'DONE'

pomo installed.

  pomo tui            the panel: pick a task, or type a new name
  pomo new "thing"    add a task and start its timer
  pomo                list tasks
  pomo streak         the goal, and how many days in a row you cleared it

Optional:
  - waybar module:  docs/waybar-module.jsonc  (left-click opens the panel)
  - hyprland binds: docs/hyprland-binds.conf  (includes the float rule)
  - phone push:     set NTFY_TOPIC in ~/.config/pomo/config.env
DONE
