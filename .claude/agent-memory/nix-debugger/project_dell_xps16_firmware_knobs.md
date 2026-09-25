---
name: dell-xps16-firmware-knobs
description: nixos-laptop (XPS 16 DA16260, BIOS 1.8.2) rejects Linux-side writes to Dell keyboard ALS (als_enabled EINVAL) and dell-wmi-sysman BIOS attrs (EOPNOTSUPP); both services removed 2026-09-25
metadata:
  type: project
---
On nixos-laptop, both units ported from a "same model" config (gossamer's dell-xps-16.nix) failed at runtime and were removed on 2026-09-25; the settings now live in BIOS setup (Keyboard Illumination=Auto, Battery Configuration=Adaptive).

- `als_enabled` write -> EINVAL. Per dell-laptop.c, kstrtoint accepts "1" with or without a newline, so printf vs echo does not matter. EINVAL comes from one of two places: (a) the target mode bit is missing from `kbd_info.modes`. Triggers are active, so the target is KBD_MODE_BIT_TRIGGER_ALS (bit 3), not ALS (bit 2). (b) The SMBIOS call returned an unknown code (dell_smbios_error default). Telling (a) from (b) needs root, and the agent has no sudo.
- dell-wmi-sysman writes -> EOPNOTSUPP, with the kernel logging "admin password must be configured". Authentication/Admin is_enabled=1.

**Why:** a "same model" config can work on one unit and fail on another because of the BIOS setting or firmware revision. If gossamer's BIOS was already on Auto, their write was probably a no-op that returned success.
**How to apply:** don't re-port these units. Open question: to test pure ALS, root runs `echo -keyboard/-touchpad > start_triggers`, then `echo 1 > als_enabled`. dell_laptop autoloads via the DMI ct10 alias, so boot.kernelModules isn't needed.
