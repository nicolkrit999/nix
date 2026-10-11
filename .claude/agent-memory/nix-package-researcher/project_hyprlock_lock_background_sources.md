---
name: hyprlock-lock-background-sources
description: Which hyprlock background each host actually shows on the lock screen; hyprlock 0.9.6 per-monitor/stacking semantics
metadata:
  type: project
---

hyprlock 0.9.6 (locked nixpkgs 39ad350). Lock screen background per host:
- nixos-laptop (catppuccin=false): module renders `background { monitor= path=<'*' entry> }` (switch_swirl.jpg). This is the "always the * fallback" symptom.
- nixos-desktop (catppuccin=true): `services.hyprlock` skips `settings` entirely (`optionalAttrs (!catppuccinEnabled)`), so the repo wallpaper code is inert there. Lock uses catppuccin's hyprlock.conf `background { path = $HOME/.config/background; color = $base }`. No repo module writes ~/.config/background and the file is absent on the live system. Expected solid $base colour (runtime not verified).

**Why:** the user's per-monitor wallpaper request depends on this split; the desktop needs a separate decision.
**How to apply:** before touching lock wallpapers, confirm which branch the host takes (catppuccin flag) and read `hypr/hyprlock.conf` from the rendered HM config.

hyprlock source facts (v0.9.6, src/renderer/Renderer.cpp:402-425, config/ConfigManager.cpp:271):
- Every output gets a lock surface and renders all matching widgets. Specific per-monitor backgrounds stack with `monitor=""` ones; no override logic.
- `monitor` matches exact port (`DP-1`) or `desc:` as a prefix of `"desc:"+wl_output description`.
- Background zindex defaults to -1; widgets are sorted by zindex and drawn in ascending order (last = on top). Labels/images/shapes default to 0. Equal-zindex order is unstable.
- Unmatched outputs with no catch-all get a cleared transparent-black surface.

Links: [[project_hyprlock_lock_background_sources]] is the only memory for this topic.
