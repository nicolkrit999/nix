---
name: hm-hyprland-uwsm-propagatesstop
description: HM master hyprland-session.target has PropagatesStopTo=graphical-session.target; its default start-hook `stop` kills a uwsm Hyprland session ~2s after login (clean RC 0, no crash, no log)
metadata:
  type: project
---

Symptom: Hyprland under uwsm exits ~2 s after login with RC 0, no coredump, no crash report; journal shows
"Stopped Main service for Hyprland" with NO "Stopping..." line; instance hyprland.log is deleted on clean exit.
"Creating the Error Overlay!" in the journal is a normal startup line, not an error.

Cause (2026-10-08, HM fae6e9e4): HM added `PropagatesStopTo=graphical-session.target` to hyprland-session.target, but
the default `wayland.windowManager.hyprland.systemd.extraCommands` still does `stop` then `start` in the
hyprland.start hook. uwsm's wayland-session@ target BindsTo graphical-session.target, wayland-wm@ BindsTo that -> the
compositor is stopped. Fixed in hyprland-main.nix with `extraCommands = [ "systemctl --user start hyprland-session.target" ];`
(do NOT set systemd.enable=false: waybar-hyprland and swaync hang off hyprland-session.target).

**Why:** cost a full session of "is it the Lua config?" - the config was fine (`Hyprland --verify-config` ok).
**How to apply:** for "WM starts then immediately exits cleanly" under uwsm, check unit Bind/PropagatesStopTo chains
first; reproduce with mimic units in /run/user/1000/systemd/user (Type=notify sleep service). Safe config smoke test:
nested Hyprland in `dbus-run-session` + `kwin_wayland --virtual`, own short XDG_RUNTIME_DIR (socket path <108 chars),
start hooks neutered, `debug.enable_stdout_logs=true` (the file log is buffered/deleted). Related: [[catppuccin-global-enable-gate]].
