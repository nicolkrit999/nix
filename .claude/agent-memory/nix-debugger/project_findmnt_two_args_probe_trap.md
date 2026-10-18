---
name: findmnt-two-args-probe-trap
description: `findmnt A B` means source=A AND target=B, so passing two mountpoints prints nothing even when both are mounted; impermanence mounts are systemd.mounts, not fileSystems
metadata:
  type: project
---

`findmnt /var/lib/systemd/rfkill /var/lib/systemd/backlight` prints NOTHING even when both are bind-mounted: two positional args mean `<source> <target>`. Use `findmnt -T <path>` one at a time, or `findmnt -R /`.

**Why:** 2026-10-18 the user's empty findmnt output looked like "impermanence does not mount the new rfkill/backlight dirs". The config was fine: impermanence (this repo's input) emits `systemd.mounts` (var-lib-*.mount, WantedBy local-fs.target, bind,x-gvfs-hide), NOT `fileSystems`, so `config.fileSystems` evaluation shows none of them either.

**How to apply:** check `config.systemd.mounts` (map .where) + the toplevel's `etc/systemd/system/var-lib-*.mount` for persistence questions. Also (unverified): a dir newly added to persistence may not be bind-mounted by `switch` in the running session (activation already creates the /persist dir); state written before the next reboot would land on tmpfs and be lost. Confirm with `findmnt -T` before trusting a post-switch test. Related: [[specialisation-outer-config-binding]].
