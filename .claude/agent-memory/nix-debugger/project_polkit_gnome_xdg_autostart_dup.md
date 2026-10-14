---
name: polkit-gnome-xdg-autostart-dup
description: polkit_gnome in systemPackages ships an XDG autostart with no OnlyShowIn -> second agent in every session (failed app-polkit...@autostart unit); WM spawns use store paths, so it must not be in systemPackages
metadata:
  type: project
---

`polkit_gnome`'s `etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop` has only `AutostartCondition=GNOME3 unless-session gnome` (OnlyShowIn commented out). Once it is in `environment.systemPackages`, systemd-xdg-autostart-generator starts it in Hyprland (uwsm), niri, KDE, COSMIC; the compositor exec_once/spawn copy wins the race and the autostart unit fails with "An authentication agent already exists for the given subject". Removed from common-configuration-nixos.nix 2026-10-14; hyprland/niri/mango spawn it by `${pkgs.polkit_gnome}` path.

**Why:** test-wm-session-services counts agents from niri spawns/units/HM services only; XDG autostart agents are a blind spot.

**How to apply:** guest spec (XFCE) still gets polkit_gnome from the upstream xfce module - that is intended. If a failing `app-*@autostart` unit name does not match a file in the tree, the live generation predates a rename: check `systemctl --user cat` SourcePath.
