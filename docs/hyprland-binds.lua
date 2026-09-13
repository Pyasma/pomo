-- Omarchy Quattro (4.x) — append to ~/.config/hypr/bindings.lua.
-- The shell plugin (https://github.com/Pyasma/omarchy-pomo) draws the bar
-- glyph and the popup; the terminal panel is still there under a third key.
o.bind("SUPER + ALT + P", "Pomodoro start/pause", "pomo toggle")
o.bind("SUPER + ALT + M", "Pomodoro panel", "omarchy-shell io.github.pyasma.pomo toggle")
o.bind("SUPER + ALT + T", "Pomodoro terminal panel", "omarchy-launch-or-focus-tui pomo tui")

-- The terminal panel is a small floating window, not a tiled one.
o.window("org.omarchy.pomo", { float = true, size = "980 660", center = true, opacity = "1 override 1 override" })
