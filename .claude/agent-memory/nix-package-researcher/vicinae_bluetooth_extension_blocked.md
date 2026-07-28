---
name: vicinae-bluetooth-extension-still-blocked
description: vicinae extensions flake still excludes bluetooth extension; node-gyp sandbox issue #314 remains OPEN and unfixed upstream
metadata:
  type: reference
  checked_date: 2026-07-28
---

**Status:** STILL BLOCKED - workaround remains necessary.

**Details:**
- Issue: vicinaehq/extensions#314 "[bluetooth] Bluetooth Extension fails to build under nixos-unstable"
- Opened: 2026-07-02
- Status: OPEN (last activity 2026-07-21, no fix in progress)
- Root cause: node-gyp sandbox build failure in dbus-next → usocket native module

**Evidence:**
1. vicinae-extensions flake.nix (main branch) still contains:
   ```
   (lib.flip builtins.removeAttrs [
     # TODO: fails to build due to node-gyp (dbus-next -> usocket native module)
     "bluetooth"
     "dbus"
     "systemd"
   ])
   ```

2. Issue #314 shows node-gyp failure: `gyp ERR! Completion callback never invoked!` when trying to build usocket native module

3. No merged or open PRs addressing the node-gyp sandbox issue for bluetooth extension

**Recommendation:** Keep the workaround active (disable bluetooth extension in hosts/nixos-laptop/default.nix and hosts/nixos-desktop/default.nix). Re-check on next major update cycle.
