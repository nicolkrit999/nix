---
name: uwsm-graphical-target-flatpak-block
description: Black screen after SDDM login into hyprland-uwsm = uwsm waiting up to 60s for graphical.target, held back by nix-flatpak's oneshot (Before=graphical.target)
metadata:
  type: project
---

If Hyprland (uwsm session) shows a black screen after login and the journal has no Hyprland lines at all, look for
`uwsm[...]: graphical.target is queued for start, waiting for 60s...` followed by countdown lines (`50`, `30`).
uwsm will not launch the compositor until the system graphical.target is reached.
On nixos-laptop (2026-10-09), `flatpak-managed-install.service` (nix-flatpak, Type=oneshot, TimeoutStart=infinity,
WantedBy+Before=graphical.target) took ~1.5 min installing new .flatpak bundles. That held graphical.target back. The user
pressed the power key before the timeout, twice (clean `Power key pressed short` poweroff, not a crash). The "working" boot
was a Plasma login, which does not wait on graphical.target, so it didn't prove Hyprland worked.

**Why:** the gap between a graphical-looking login and a compositor that never starts is invisible: no coredump, no Hyprland log.
**How to apply:** on any uwsm black screen, grep the system journal for `uwsm[` and `Reached target Graphical Interface`
before chasing GPU or config causes. Also check which session the "good" boot logged into (sddm `Session ... selected`). See [[hm-hyprland-uwsm-propagatesstop]].
