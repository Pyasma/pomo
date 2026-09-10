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
[[ -f $CONF/sessions.conf ]] || cp "$SRC/sessions.conf.example" "$CONF/sessions.conf"
cp "$SRC/docs/README.md" "$CONF/README.md"
install -m 644 "$SRC"/systemd/pomo-*.{service,timer} "$UNITS/"

systemctl --user daemon-reload
systemctl --user enable --now pomo-nag.timer pomo-daily.timer pomo-tick.timer

cat <<'DONE'

pomo installed.

  pomo                today's three sessions
  pomo s start        start the next one
  pomo s edit         change what the sessions are

Optional:
  - waybar module: docs/waybar-module.jsonc
  - hyprland binds: docs/hyprland-binds.conf
  - phone push:     set NTFY_TOPIC in ~/.config/pomo/config.env
DONE
