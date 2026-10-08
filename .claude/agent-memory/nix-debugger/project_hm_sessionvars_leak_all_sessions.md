---
name: hm-sessionvars-leak-all-sessions
description: home.sessionVariables set by one WM module (mango) leak into every SDDM session (COSMIC/GNOME/KDE) via the fish login shell; start-cosmic keeps them with ${VAR:=default}
metadata:
  type: project
---

home.sessionVariables is not per-session. SDDM's wayland-session wrapper, start-cosmic (`$SHELL -l` re-exec) and gnome-session all run a fish login shell, which sources hm-session-vars.fish and overwrites the DM-set XDG_CURRENT_DESKTOP (from the .desktop DesktopNames). start-cosmic then keeps it (`${XDG_CURRENT_DESKTOP:=COSMIC}`). Hyprland/niri/KDE set their own value afterwards, so they look fine, but XDG_SESSION_DESKTOP=mango still leaked into KDE's systemd user env.

Found 2026-10-09: mango-main.nix put XDG_CURRENT_DESKTOP/XDG_SESSION_DESKTOP=mango in home.sessionVariables.

**Why:** a WM module's home.sessionVariables apply to every session the user logs into on that host.
**How to apply:** desktop-identity vars (and GDK_SCALE and similar) belong in the compositor's own env (e.g. mango config env=, Hyprland env), not home.sessionVariables. COSMIC's Open Sans dconf fonts come from its separate DCONF_PROFILE=cosmic db, not from this leak. Related: [[kde-textscale-dconf-leak]]
