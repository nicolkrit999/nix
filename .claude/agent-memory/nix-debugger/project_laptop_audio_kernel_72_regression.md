---
name: laptop-audio-kernel-72-regression
description: nixos-laptop sof_sdw audio died at the linux 7.1.8 -> 7.2.0 bump (gen 307 -> 308); GRUB configurationLimit hides still-bootable older profiles
metadata:
  type: project
---

nixos-laptop (Dell XPS 16 2026, Panther Lake) lost ALL audio at the kernel
7.1.8 -> 7.2.0 bump. Last good boot: 2026-08-19 20:05 CEST on 7.1.8 (gen 307).
First bad boot: 2026-08-21 00:44 CEST on 7.2.0 (gen 308). Every boot since is bad.
Firmware is NOT implicated - sof-firmware 2025.12.2, linux-firmware 20260810 and
alsa-ucm-conf 1.2.16.1 are byte-identical in version across the boundary; the
kernel is the only audio-relevant delta.

**Why:** on 7.2.0 all four `cs35l56` SoundWire amps fail with
`error -EBUSY: Failed to get spk-id-gpios` -> `probe with driver cs35l56 failed
with error -16`, which blocks `snd_soc_register_card()`, so `sof_sdw` never
appears and `/proc/asound/cards` is empty (no HDMI, no speakers, no jack - it is
one shared card). On 7.1.8 the same amps probe fine and load
`cirrus/cs35l57-b2-dsp1-misc-10280dba-spkid0.wmfw`. GPIO/pinctrl init is
identical on both sides, and the
`No SoundWire machine driver found ... / Use SoundWire default machine driver
with function topologies` pair appears on BOTH - it is a red herring, not the
regression.

**How to apply:** treat this as an upstream kernel regression, not a config bug -
do not chase sof-firmware, ucm, or WirePlumber. Pinning
`boot.kernelPackages` back to 7.1.x is the only known-good state.

**Boot-menu vs profile retention trap (generalises beyond audio):** the GRUB
`configurationLimit` (10 here) only limits *menu entries*. Older system profiles
survive in `/nix/var/nix/profiles/system-N-link` well past that. When the user
says "I rolled back to the oldest generation and it was still broken", check
whether the oldest *bootable menu entry* is actually the oldest *retained
profile* - here gens 304-307 (the only 7.1.x ones) existed and were intact but
were invisible in GRUB. Map generations to kernels with:
`for g in /nix/var/nix/profiles/system-*-link; do echo "$g $(readlink -f $g/kernel)"; done`
