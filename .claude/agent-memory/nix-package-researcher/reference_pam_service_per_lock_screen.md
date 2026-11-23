---
name: pam-service-per-lock-screen
description: Which PAM service name each lock screen / greeter authenticates against (kde, cosmic-greeter, gdm-password, login for noctalia, caelestia passwd, ryoku-lock, hyprlock) and which nixpkgs/repo flag defines it; for pam_u2f per-service gating
metadata:
  type: reference
---

Verified 2026-11-23 against nixpkgs (root input) plus shell/compositor sources.

- Noctalia v5 lock: `lock_screen.cpp` uses PAM service `"login"` (always defined on NixOS).
- Caelestia lock: QML `PamContext { config: "passwd"; configDirectory: shellPath("assets/pam.d") }`. Uses the shell's bundled `pam.d/passwd` (pam_unix only), NOT /etc/pam.d, so `security.pam.services` has no effect on it.
- Ryoku lock (`nix/modules/ryoku.nix`): own generated `ryoku-lock` and `ryoku-lock-pw` files in the lockscreen assets dir (pam_deny for fingerprint, pam_unix for password). Not /etc/pam.d.
- COSMIC lock: cosmic-greeter `src/locker.rs` uses `"cosmic-greeter"`. Nixpkgs defines it in `desktop-managers/cosmic.nix` (line 162, under `cfg.enable`).
- KDE lock (kscreenlocker): nixpkgs plasma6.nix defines `kde` (and `kde-fingerprint` when fprintd), under `cfg.enable`.
- GNOME lock: gnome-shell 51 `js/gdm/authServicesLegacy.js` uses `gdm-password`. Nixpkgs defines it only in `display-managers/gdm.nix` (under gdm enable). The repo's GNOME module does not enable GDM, so `gdm-password` is absent today.
- hyprlock: repo `services/hypr/hyprlock.nix` defines `hyprlock` when hyprland, niri or mango is enabled.
- Always-present services: `login` (repo common-configuration-nixos sets it), `sudo` (nixpkgs sudo.nix), `polkit-1` (nixpkgs polkit.nix).
- Greeter services: `sddm`, `sddm-greeter`, `sddm-autologin` (nixpkgs sddm.nix); `greetd`; `plasmalogin`; `gdm-*`.

**Why:** A `security.pam.services.<name>` entry with any option set creates /etc/pam.d/<name>. Gating must reuse the flag that makes the defining module active.
**How to apply:** For pam_u2f per-service enabling, gate each name on the same enable flag its defining module uses (the services list in modules/nixos/services/yubikey-auth.nix).
