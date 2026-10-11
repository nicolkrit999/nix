# Rebuilding from inside a live Hyprland session kicks you to SDDM

**Status: OPEN for the rebuild kick, no dedicated fix applied.** A related,
separate workaround exists: `hyprland-main.nix` sets
`wayland.windowManager.hyprland.systemd.extraCommands` to only
`systemctl --user start hyprland-session.target` (dropping the default
`stop && start`), which cures Hyprland exiting right after login on
home-manager master. It touches the same `stop hyprland-session.target`
mechanism described below, but whether it also stops the kick on
`nh os switch` has not been re-tested.

**Symptom:** every `nixos-rebuild switch` / `nh os switch` run from inside a
live Hyprland session kicks the user back out to SDDM (the login manager -
not Plasma). Workarounds in use: rebuild from another DE/WM, or use
`nh os boot` (boot-only, never touches `/run/current-system/activate`, never
restarts units) instead of `switch`.

This started after this repo switched Hyprland's config to the Lua-based
engine (`configType = "lua"`), but investigation concluded the Lua switch is
**not** the actual cause - it's a coincidental timing marker.

## Root cause (as far as narrowed down)

- Hyprland has no separate flake input in this repo; it comes from the pinned
  `nixpkgs` package via `programs.hyprland.enable`. "Hyprland version" here =
  whatever the `nixpkgs` lock rev currently provides.
- This repo's own Lua config switch (`modules/nixos/programs/de-wm/hyprland/hyprland-main.nix`)
  happened 2026-06-01 - too early to be the direct trigger for a regression
  that started later.
- `programs.hyprland.withUWSM = true` and `systemd.variables = ["--all"]`
  have been unchanged since 2026-03-20, untouched near the regression window.
- What actually lines up in time: `nixpkgs` bumps around 2026-08-21 and
  2026-09-04, which likely pulled in a newer, Lua-capable Hyprland build.
- Best-matching upstream bug for the exact symptom (clean/graceful kick to
  SDDM, not a crash): **hyprwm/Hyprland#15688** - Home Manager's
  `wayland.windowManager.hyprland.systemd.enable` activation runs
  `systemctl --user stop hyprland-session.target && start hyprland-session.target`
  on every rebuild (triggered by `home-manager-krit.service` reactivating),
  which cascades via `BindsTo=`/`PropagatesStopTo=` and SIGTERMs the actual
  compositor unit without it coming back. This looks like a preexisting
  Home Manager/uwsm systemd dependency-graph flaw that just started biting
  around the same time as the Lua rollout, not something Lua caused.
- Related upstream issues: Vladimir-csp/uwsm#215, uwsm#216 (proposes a fix
  using `StopPropagatedFrom=`, not yet merged).

## Next step if this gets revisited

Not yet attempted: guard the teardown units the way `display-manager.service`
is guarded with `X-RestartIfChanged=false`/`X-StopIfChanged=false` (confirmed
absent on all `/etc/systemd/user/` units on this host), or temporarily pin
`nixpkgs` back to a pre-2026-09-04 rev to confirm the Hyprland version bump as
the trigger. A read-only diagnostic
(`SYSTEMD_LOG_LEVEL=debug nixos-rebuild dry-activate`) would show which user
units `switch-to-configuration` intends to restart without actually doing it.
