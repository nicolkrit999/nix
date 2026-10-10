---
name: mango-config-value-255-truncation
description: mango 0.18 silently truncates any config value >255 chars (sscanf %255); a long exec_once becomes broken sh -c and never runs, mango -p still passes
metadata:
  type: project
---

mango 0.18 `parse_config_line` uses `sscanf("%255[^=]=%255[^\n]")` and a 512-byte line buffer (src/config/load.c). A value over 255 chars is cut with no error, and `mango -p` (HM validation) passes. An exec_once that inlines long store paths (wallpaperd with three video specs = 321 chars) gets cut mid-quote, `sh -c` exits 2, and nothing is logged anywhere because mango's stderr isn't captured. Symptom: the command "works by hand" but never runs at login, only on mango (Hyprland has no limit, niri uses argv).

**Why:** cost a live-session debug on 2026-10-10. Env, output race and flock were all red herrings.
**How to apply:** for any "mango exec_once never runs" report, first measure line lengths in ~/.config/mango/config.conf (`awk '{print length}'`). The repo now wraps long commands in a writeShellScript, `fitValues` in mango-main.nix throws on >255, and test-wallpaperd-runtime checks every host. Related: [[wallpapers-targetmonitor-literal]].
