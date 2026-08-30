---
name: wallpapers-targetmonitor-literal
description: myconfig.constants.wallpapers targetMonitor must stay a literal connector name (DP-1/eDP-1) - mango bakes it into a flat key=value mango-config.conf that breaks on any "="
metadata:
  type: project
---

`myconfig.constants.wallpapers[].targetMonitor` must always be a **literal
connector name** (`eDP-1`, `DP-1`, `*`). Never a shell substitution, and never a
`desc:`/make-model-serial identity string.

**Why:** `modules/nixos/programs/de-wm/mango/mango-main.nix` maps over
`myconfig.constants.wallpapers` and bakes each `targetMonitor` into an
`exec=sh -c 'awww img -o <targetMonitor> ...'` entry of
`wayland.windowManager.mango.settings`. That renders to `mango-config.conf`,
which mango parses as flat `keyword=value` lines. Any `=` inside the value tears
the line apart and the build aborts with `[ERROR]: Unknown keyword: ...`. A
`$(... jq -r "select(.serial==\"X\")" ...)` resolver is full of `=`. Separately,
`awww`/`mpvpaper` only accept a literal connector via `-o` anyway.

Four other consumers read the same list (hyprland, niri, cosmic, gnome, kde,
hyprlock, stylix-nixos), so there is **no way to split** "mango entries" from
"non-mango entries" - mango reads every element. The whole list is literal or
nothing.

**How to apply:** If asked to make monitor config plug-order independent, do it
in the Hyprland (`desc:<make> <model> <serial>`) and Niri
(`"<make> <model> <serial>"` output keys) blocks only. Mango stays
connector-name-keyed everywhere (`monitors`, `monitorLayouts`, mango-binds
per-monitor layout binds, waybar-mango `mmsg` bars all key on connector name and
would silently desync). Wallpapers stay connector-name-keyed too, which means
wallpaper-to-monitor assignment remains plug-order dependent - that is a known,
accepted limitation, not a bug to fix. See [[flake-check-misses-build-failures]].
