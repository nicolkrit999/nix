---
name: xdph-journal-buffered-silent
description: xdg-desktop-portal-hyprland journal goes silent after its init burst; no "[screencopy] New session" lines is NOT proof that no ScreenCast happened (desktop screenshare probes)
metadata:
  type: project
---

On nixos-desktop (xdph 1.4.1, 2026-10-26) the xdph journal shows only the startup burst; a direct
`gdbus ... ScreenCast.CreateSession` probe and the user's real picker use logged nothing, and no boot
since 2026-10-13 ever shows `[screencopy] New session:` although the binary has that string.
Inferred cause: stdout to the journal socket is block-buffered (not confirmed by reading source).

**Why:** cost a wrong first hypothesis ("Vesktop never reaches the portal") in the Vesktop screenshare probe;
the user then confirmed the hyprland-share-picker does appear.

**How to apply:** for screencast diagnosis use `dbus-monitor` on org.freedesktop.portal.ScreenCast +
Request.Response and `pw-dump`/`pw-mon` during a live attempt, not the xdph journal. Desktop has two
AMD GPUs (Navi 31 = card1/renderD128 = aquamarine primary, Raphael iGPU = card0/renderD129); xdph and
Electron both use renderD128, so it is not a cross-GPU dmabuf mismatch by default.
