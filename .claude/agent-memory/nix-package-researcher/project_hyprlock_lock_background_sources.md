---
name: hyprlock-lock-background-sources
description: Which hyprlock background each host actually shows on the lock screen; hyprlock 0.9.6 per-monitor/stacking semantics
metadata:
  type: project
---

Repo state (modules/nixos/services/hypr/hyprlock.nix): both branches now render wallpaper backgrounds from `myconfig.constants.wallpapers` via `mkBackgrounds`: one `background` block per non-`*` entry with a wallpaperURL (`monitor = targetMonitor`, zindex -2) plus a `monitor = ""` catch-all (the `*` entry, else `constants.fallbackWallpaperURL`; zindex -3). `mkBackgrounds` is a plain list, no blur/dimming.
- catppuccin=false (laptop): `settings.background = mkForce mkBackgrounds` plus own labels/image/input-field.
- catppuccin=true (desktop): `catppuccin.hyprlock` with `useDefaultConfig = false`; `settings.source` = `catppuccinLockConf`, a runCommand copy of catppuccin's hyprlock.conf with its BACKGROUND block stripped (build fails if the theme layout changes), and `background` forced to `mkBackgrounds` (`source` is `lib.mkAfter`). The stripped conf still draws a left PANEL shape at zindex -1.

**Why:** the user's per-monitor lock wallpaper request; the old desktop split (catppuccin conf drawing `$HOME/.config/background`, repo wallpapers inert) was replaced by this.
**How to apply:** read `hypr/hyprlock.conf` from the rendered HM config before touching lock wallpapers; hyprlock version facts below were measured on 0.9.6, re-check after a bump.

hyprlock source facts (v0.9.6, src/renderer/Renderer.cpp:402-425, config/ConfigManager.cpp:271):
- Every output gets a lock surface and renders all matching widgets. Specific per-monitor backgrounds stack with `monitor=""` ones; no override logic.
- `monitor` matches exact port (`DP-1`) or `desc:` as a prefix of `"desc:"+wl_output description`.
- Background zindex defaults to -1; widgets are sorted by zindex and drawn in ascending order (last = on top). Labels/images/shapes default to 0. Equal-zindex order is unstable.
- Unmatched outputs with no catch-all get a cleared transparent-black surface.


