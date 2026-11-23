---
name: gnome-lock-needs-gdm-daemon
description: GNOME 51 lock screen unlock goes through the gdm daemon (org.gnome.DisplayManager), not a local PAM call; SDDM-started GNOME has no such daemon. Also why adding gdm-password / sddm u2f is wrong.
metadata:
  type: reference
---

GNOME 51.1 (nixpkgs rev 0bb8272318b4, root input `nixpkgs`) lock-screen unlock is `UnlockDialog` -> `AuthPrompt` in `UNLOCK_ONLY` mode, which sets `reauthenticationOnly=true` (gnome-shell `js/gdm/authPrompt.js:176-182`, `js/ui/unlockDialog.js:878`). `ShellUserVerifier._getUserVerifierProxies` calls `Gdm.Client.open_reauthentication_channel` (libgdm, bus name `org.gnome.DisplayManager`). The ACCESS_DENIED fallback to `get_user_verifier` only runs when `!reauthOnly` (`js/gdm/userVerifier.js:326-338`), so any other error -> `InitError` -> "Authentication error". The PAM service name (`gdm-password`, `js/gdm/authServicesLegacy.js:17`) is passed to the daemon via `call_begin_verification_for_user` (line ~453); gnome-shell never calls PAM itself. No gdm dbus service file ships in the gdm package, so nothing activates the daemon without `services.displayManager.gdm.enable`.

**Why:** Settles the "is gdm-password needed without GDM" question: no. A `gdm-password` PAM file in the repo is never reached.

**How to apply:** Do not add `gdm-password` (or u2f on it) for GNOME lock. nixpkgs `gdm-password` is `substack login` (`display-managers/gdm.nix:511`), and sddm is also `substack login` (`display-managers/sddm.nix` ~371), so `login.u2f` is already inherited by SDDM login; adding `sddm` explicitly would double the pam_u2f rule. Runtime behaviour of GNOME lock on SDDM is source-derived, not live-tested.

Related: [[reference_pam_service_per_lock_screen]]
