# GRUB 1970 boot clock glitch (nixos-desktop)

**Symptom:** GRUB menu on `nixos-desktop` sometimes briefly shows a bogus date
like `1970-0-1` (day=1, month=0 - the giveaway of a raw/uninitialized CMOS RTC
read) during boot, before the OS loads. A related symptom: a blinking `-`
cursor top-right for ~1 minute *before* GRUB even appears, on every boot.

**Verdict: not a config bug.** Investigated and ruled out:

- `time.hardwareClockInLocalTime = true` is correctly set in
  `hosts/nixos-desktop/system.nix` and `hosts/nixos-laptop/system.nix`,
  matching the live `/etc/adjtime` (`LOCAL`).
- No GRUB theme, `extraConfig`, or plymouth widget anywhere in the repo
  renders a date/clock.
- Boot timing showed the kernel's first journal timestamp ~4h ahead of the
  real time shortly after - consistent with GRUB/firmware reading the CMOS
  RTC once as if UTC (double-applying the local offset) before NTP corrects
  it. The RTC itself is fine once Linux/NTP take over.

This is a firmware/GRUB-level CMOS RTC read quirk (board: MSI MEG X670E ACE,
AM5/X670E, Ryzen 9 7950X3D), likely compounded by AM5 "Memory Context Restore"
not persisting across power cycles - i.e. an aging CMOS battery (from 2023) not
holding NVRAM state. Purely cosmetic, self-corrects, doesn't affect actual
system time or NTP sync.

**Do not conflate with:** `time.hardwareClockInLocalTime = true` also exists
as a dual-boot-Windows fix - that's a separate, correctly-working concern.

**Next step if ever revisited (not attempted, low priority):** replace the
CMOS battery (CR2032), reset BIOS defaults, re-verify Memory Context Restore
is enabled, check RAM is on the board's QVL if EXPO is used. No NixOS/GRUB
option in this repo controls this.
