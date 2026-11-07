---
name: ovmf-sb-notfound-vm-artifact
description: Clone-installer VM test showed "BdsDxe failed to load ... Not Found" under Secure Boot; it was a harness artifact, not lanzaboote/installer
metadata:
  type: project
---
2026-11-07 (step 9b of the clone installer): with the installer-enrolled keys (PK/KEK/db + MS), OVMF boots the lanzaboote install under ENFORCING Secure Boot on NVMe, SATA and virtio. It reaches plymouth through the UKI. Step 8's "Not Found" could not be reproduced in 11 runs.

**Why:** when the harness put `-device` lines in a different order, the NVMe moved from PCI 03 to PCI 02. The OVMF full-path auto entry (`PCI(dev=03)/NVMe`) then pointed at an empty slot and correctly reported Not Found. pexpect never reads in `boot-installed`, so the serial logs were empty. Only overwritten screenshots existed, and "SB on vs off" was never compared at the same time.

**How to apply:** if a VM boot shows "Not Found" for a Boot#### entry, first diff the PCI slot or device order against the install run and capture serial to `-serial file:` (OVMF BdsDxe lines go to serial). Check enforcement with the unsigned-ISO control ("Access Denied -- rejected probably by Secure Boot"). Use `snapshot=on` on the target disk. Report: ~/momentary/clone-installer/step9b-secureboot-report.md. Related: [[project_laptop_lanzaboote_analysis]].
