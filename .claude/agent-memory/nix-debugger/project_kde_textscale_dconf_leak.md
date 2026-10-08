---
name: kde-textscale-dconf-leak
description: Logging into Plasma 6.7 makes kde-gtk-config write dconf text-scaling-factor from kcmfonts forceFontDPI; Zen and GTK apps in Hyprland then render 1.25x too big
metadata:
  type: project
---
On nixos-laptop, `~/.config/kcmfonts` has `forceFontDPI=120` (set by hand on 2026-04-14, not in the repo). When the user logged into Plasma 6.7 on 2026-10-08, kde-gtk-config set dconf `/org/gnome/desktop/interface/text-scaling-factor` to 1.25 (it had been 1.0 in btrfs snapshot 472 earlier that day) and wrote xsettingsd `Gdk/UnscaledDPI 122880`. The value stays in dconf, so the Hyprland session reads it through xdg-desktop-portal-gtk, and Zen (Firefox's os-zoom-behavior) shows pages 25% larger while its zoom still says 100%.

**Why:** It looks like a Zen or channel-bump regression (zen 1.22.3b -> 1.23.1b changed at the same time), but the real trigger is the Plasma login.

**How to apply:** When an app suddenly looks too big after a KDE session, first run `dconf read /org/gnome/desktop/interface/text-scaling-factor` and check the mtime of `~/.config/dconf/user`. To read the old value from a snapshot copy, point `DCONF_PROFILE` at a file that contains `user-db:user` and set `XDG_CONFIG_HOME` to the copy's directory.
