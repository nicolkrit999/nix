---
name: jetkvm-edid-firmware-solution
description: EDID firmware injection for JetKVM (DP-3) via kernel params and hardware.firmware
metadata:
  type: project
---

## Summary

JetKVM EDID injection via `drm.edid_firmware=DP-3:edid/1920x1080.bin` is **fully supported** on nixos-unstable and nixos-25.11.

## Kernel Config Status

- **CONFIG_DRM_LOAD_EDID_FIRMWARE=y**: Enabled in both unstable (kernel 6.18.21) and stable/25.11 (kernel 6.12.83)
- The kernel is compiled with built-in EDID firmware blob support
- No custom kernel build needed

## EDID Firmware Location

The `edid-generator` package (nixpkgs attribute: `edid-generator`) provides standard EDID blobs at `/lib/firmware/edid/` including:
- `1920x1080.bin` (128 B)
- `1024x768.bin`, `1280x1024.bin`, `1280x720.bin`, `1600x1200.bin`, `1680x1050.bin`, `2560x1440.bin`, `2880x1800.bin`, `3840x2160.bin`, `800x600.bin`

Store path (unstable): `/nix/store/sm51i661rz49q218rgvg9daaaphmq973-edid-generator-master-2023-11-20/lib/firmware/edid/1920x1080.bin`

## NixOS Configuration Approach

**Correct approach (two-part):**

1. **Add kernel parameter** in `boot.kernelParams`:
   ```nix
   boot.kernelParams = [ "drm.edid_firmware=DP-3:edid/1920x1080.bin" ];
   ```

2. **Stage firmware via hardware.firmware** (required for kernel to find the blob):
   ```nix
   hardware.firmware = [ pkgs.edid-generator ];
   ```

The `hardware.firmware` option (type: list of package) copies firmware files from packages into `/lib/firmware` at build time, making them available to the kernel loader.

## Why Both Are Needed

- `boot.kernelParams` tells the kernel *which* EDID to load (by name)
- `hardware.firmware = [ pkgs.edid-generator ]` copies the actual `.bin` files into the firmware search path
- Without `hardware.firmware`, the kernel will log "drm: Cannot find firmware file edid/1920x1080.bin" and fall back to I2C probe (which fails on JetKVM)

## Testing

After applying both changes:
1. Rebuild: `nixos-rebuild switch` (or `nh os switch` with RTK)
2. Boot with DP-3 connector attached
3. Check dmesg: `dmesg | grep -i "edid\|dp-3"` should show successful load, not "No EDID found"
4. Verify display comes up on boot

## Caveats

- The kernel param uses the **relative path** `edid/1920x1080.bin`, not a full store path
- `hardware.firmware` is the standard NixOS mechanism for exposing firmware blobs; alternative custom approaches (copying to `/etc/firmware`) also work but are non-standard
- The EDID blob is 128 bytes (not per-connector; same blob applies to all connectors)

---

**Resolved:** 2026-06-15  
**Status:** Ready to implement
