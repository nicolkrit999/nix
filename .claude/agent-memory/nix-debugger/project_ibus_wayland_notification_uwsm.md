---
name: ibus-wayland-notification-uwsm
description: "IBus should be called from the desktop session in Wayland" notification = ibus-ui-gtk3 check_wayland() on every panel start; Hyprland exec_once pkill is dead under uwsm (runs before XDG autostart)
metadata:
  type: project
---

On nixos-desktop, ibus comes from nixpkgs gnome.nix (core-os-services: `i18n.inputMethod.enable/type = mkDefault`), enabled via repo modules/nixos/toplevel/gnome.nix. Laptop has inputMethod disabled. The ibus module ships /run/current-system/sw/etc/xdg/autostart/ibus-daemon.desktop (`NotShowIn=GNOME;KDE;`, no --panel) -> systemd-xdg-autostart-generator unit `app-ibus\x2ddaemon@autostart.service` in Hyprland/niri/mango.

The notification is ibus 1.5.34 ui/gtk3/panel.vala `check_wayland()`, called in the Panel constructor: fires once per ibus-ui-gtk3 start when Wayland && no `--enable-wayland-im` && XDG_CURRENT_DESKTOP not GNOME. Deterministic per login, not a race.

The `pkill ibus-daemon` in Hyprland exec_once (hl.on("hyprland.start")) runs ~1s BEFORE uwsm reaches graphical-session.target -> xdg-desktop-autostart.target, so it never kills anything (verified 2026-10-16: polkit-gnome PID 42668 vs ibus-daemon 43430). The KDE kill autostart is also redundant (upstream desktop file already NotShowIn=KDE).

**Why:** future "ibus notification" reports should not re-derive the race theory.
**How to apply:** FIXED 2026-10-16 (47d18cc4, live-verified): modules/nixos/toplevel/gnome.nix ships a user-level `autostart/ibus-daemon.desktop` with `Hidden=true` (same filename shadows the system entry); the pkill and the KDE kill file are gone; regression test nixos-ibus-autostart-hidden. If the popup ever returns, check the override still exists and nothing else autostarts ibus; do not add a pkill. `waylandFrontend = true` was NOT applied (only needed if the GTK/QT_IM_MODULE vars should go). See [[project_ibus_kill_workaround]] (orchestrator memory).
