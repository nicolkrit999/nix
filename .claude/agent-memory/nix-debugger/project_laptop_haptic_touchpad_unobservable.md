---
name: laptop-haptic-touchpad-unobservable
description: nixos-laptop Synaptics 06CB:D01A haptic click is firmware-autonomous; kernel/journal show nothing that differs between working and broken boots
metadata:
  type: project
---

On nixos-laptop the haptic click of the touchpad (i2c-VEN_06CB:00, 06CB:D01A, ACPI \_SB_.PC00.I2C4.TPD0, hid-multitouch) runs in the touchpad's own firmware. The HID descriptor's only haptics item is `05 0e 09 01 a1 02 09 23 85 37 ...` (Simple Haptic Controller > Intensity, feature report 0x37, range 0-100). The kernel's hid-haptic code (CONFIG_HID_HAPTIC=y) does NOT take it over: capabilities/ff=0 and PROP=5 (no PRESSUREPAD flag). /dev/hidraw2 is root-only (crw------- root).

On 2026-10-07 the user reported 3 broken boots (-3,-2,-1) and 1 working boot (0). All four ran the same system generation (20261006.b253099, kernel 7.3.0-rc6). After normalising, their kernel logs were identical apart from shutdown lines. Warning-level logs differed only in shutdown/sddm noise. Even the intel_cvs vs hid-multitouch probe order did not line up with the symptom.

**Why:** the journal has no evidence either way, so diffing logs again for this symptom is a waste.
**How to apply:** the useful next steps need root or hardware: read feature report 0x37 through hidraw2 on a working boot and on a broken boot, check the BIOS touchpad/haptic setting, and test a full power-off vs a warm reboot.

**Reading the intensity (do it on a WORKING boot AND on a NON-WORKING boot, then compare):**
1. As root, find the node (number can change between boots): `grep -l 'D01A' /sys/class/hidraw/hidraw*/device/uevent` (was hidraw2 on 2026-10-07).
2. As root, in bash (the user's shell is fish, which has no heredocs: run `bash` first or save to a file), with the node from step 1:
```
python3 -I - /dev/hidraw2 <<'EOF'
import fcntl, os, sys
HIDIOCGFEATURE_2 = 0xC0024807   # _IOC(READ|WRITE,'H',0x07,len=2)
fd = os.open(sys.argv[1], os.O_RDWR)
buf = bytearray([0x37, 0])      # byte0 = report ID, byte1 filled by device
fcntl.ioctl(fd, HIDIOCGFEATURE_2, buf)
print("report id: 0x%02x  intensity: %d (range 0-100)" % (buf[0], buf[1]))
EOF
```
Read-only (never writes the report). Untested as of 2026-10-07 until the user pastes a result.
3. Interpretation: different value or ioctl error on the broken boot = real signal; identical value on both = state not readable this way (matches the Omarchy issue basecamp/omarchy#5303 where the ioctl succeeds but nothing is felt on D01D).

**Results log (append one line per run: date, boot working/broken, cold/warm start, intensity):**
- 2026-10-07, WORKING boot: the 2-byte GET_FEATURE (0xC0024807) on /dev/hidraw2 as root fails with `OSError: [Errno 121] Remote I/O error`, so no intensity was read. The ioctl encoding is accepted (a bad one would give ENOTTY), so the kernel sent the request and the i2c transaction to the touchpad failed. Feature 0x37 may be write-only or need a different length. NOT a usable working/broken discriminator unless a variant (other buffer length) reads successfully on the working boot.
- 2026-10-07, WORKING boot, retry with an 8-byte buffer (0xC0084807): same `Errno 121`. Reading feature 0x37 via hidraw is a DEAD END (probably write-only); do not retry it. BIOS touchpad/haptic setting: user confirmed correct on 2026-10-07 (ruled out). Remaining discriminator: full power-off vs warm reboot over several boots (log each in the results list).

Related: [[dell-xps16-firmware-knobs]], [[journal-clock-skew-desktop]] (the laptop shows the same RTC-offset first>last entry pattern in list-boots).
