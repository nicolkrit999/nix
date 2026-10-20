---
name: greeter-pipewire-usb-audio-race
description: nixos-desktop onboard MSI ALC4080 USB audio (0db0:961e, incl. optical S/PDIF) has no sinks after most boots - sddm greeter's own pipewire grabs the PCMs, krit's lingering wireplumber gets EBUSY and never retries
metadata:
  type: project
---

The MEG X670E ACE onboard audio is NOT HDA: 17:00.6 Ryzen HD Audio reports "no codecs found"; the real codec is a USB Realtek ALC4080-class device (0db0:961e, ALSA card "Audio", UCM `USB-Audio/Realtek/ALC4080-HiFi.conf`, SPDIF = hw:Audio,3, Speaker ,0, Headphones ,1). Don't go hunting HDA pin configs/hdajackretask for S/PDIF.

Symptom (diagnosed 2026-10-21): card profile HiFi lists an `[Out] SPDIF` port and "sinks: 3", but `wpctl status` shows only the card's two sources. Journal: `pipewire: spa.alsa: '_ucm0001.hw:Audio,3': playback open failed: Device or resource busy` + `wireplumber: Failed to create ALSA node ...HiFi__SPDIF__sink: Object activation aborted`. Cause: krit has Linger=yes so his pipewire starts before login; the sddm greeter user (uid 175) also runs a full pipewire+wireplumber in its user manager and holds the USB PCMs when snd-usb-audio registers (~3 s after HDA cards). Greeter pipewire stops at login, PCMs free up, but wireplumber never retries the failed node creation. Hit 4 of the last 6 boots (racy).

**Why:** looks like a missing-hardware/config problem in mixers; actually a session race.
**How to apply:** runtime fix `systemctl --user restart wireplumber` (or profile off->HiFi). Config fix candidate: keep pipewire/wireplumber user units off for system users (sddm), e.g. `unitConfig.ConditionUser = "!@system"` on pipewire/pipewire-pulse sockets+services and wireplumber. Related: [[journal-clock-skew-desktop]] (journal times +2h vs ps).
