---
name: wallpapers-targetmonitor-literal
description: myconfig.constants.wallpapers targetMonitor must stay a literal connector name (DP-1/eDP-1) - mango bakes it into a flat key=value mango-config.conf that breaks on any "="
metadata:
  type: project
---

`myconfig.constants.wallpapers[].targetMonitor` must always be a **literal
connector name** (`eDP-1`, `DP-1`), `desc:<make> <model> <serial>`, or `*`.
Never a shell substitution (`$(`, backtick).

**Why (current mechanism, re-verified 2026-10-11):** the wallpaper pipeline moved to
`modules/nixos/programs/de-wm/wallpaperd/mk-wallpaperd.nix` + `wallpaperd.sh`. Each
wallpaper becomes an argv spec `<targetMonitor>=<image|video>:<store path>` passed to a
`<wm>-wallpaperd` script. mk-wallpaperd asserts at eval time that no targetMonitor contains
`$(` or a backtick ("must be a connector name, desc:<make model serial> or *") and that
targets are unique ("duplicate targetMonitor"). The old failure (mango baking a
`$(... jq select(.serial=="X") ...)` resolver into `exec=sh -c 'awww img -o ...'` so that any `=` tore the
`mango-config.conf` line apart: `[ERROR]: Unknown keyword`) no longer applies to the
spec itself; mango now launches wallpaperd via a launcher script and `fitValues` in
mango-main.nix caps config values at 255 chars (see [[mango-config-value-255-truncation]]).
The shell-substitution ban stays because the spec is a plain argv string.

The list is consumed by hyprland, niri, mango, cosmic (`output."<target>"`, `*` -> `all`), gnome, kde, hyprlock
and stylix-nixos, so there is still no way to split "mango entries" from "non-mango entries".

**How to apply:** if asked to make monitor config plug-order independent, do it in the Hyprland
(`desc:<make> <model> <serial>`) and Niri (`"<make> <model> <serial>"` output keys) blocks.
Mango stays connector-name-keyed (`monitors`, `monitorLayouts`, per-monitor layout binds, waybar-mango
`mmsg` bars all key on connector name and would silently desync). Wallpaper-to-monitor assignment in mango is
therefore still plug-order dependent: a known, accepted limitation. Hosts today use literal names
(desktop DP-1/DP-2/`*`, laptop eDP-1/`*`). See [[flake-check-misses-build-failures]].
