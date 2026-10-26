---
name: vesktop-screenshare-dmabuf-research
description: Vesktop Wayland screenshare EGL_BAD_MATCH / DMA-BUF modifier failures - upstream issue status, workaround evidence, version state as of 2026-10-26
metadata:
  type: project
---

Vesktop screenshare on Wayland (EGL_BAD_MATCH, "DMA-BUF modifier ... renegotiating", AbortError: Invalid capture constraints) has no confirmed root-cause fix upstream as of 2026-10-26.

**Why:** Research on 2026-10-26 found Vencord/Vesktop#1207 (open, Nov 2025) with the maintainer recommending turning Video Hardware Acceleration off; reporters confirmed that fixes it. Vesktop#1375 (opened 2026-10-26) is a separate Vesktop-side bug in src/main/screenShare.ts (empty callback after an already-granted capture) that reproduces on 1.6.8 official AppImage and nixpkgs.

**How to apply:**
- nixpkgs master has vesktop 1.6.8 with electron_44. The root `nixpkgs` lock in /home/krit/nix/flake.lock (rev 02c087f3, 2026-10-18) was 1.6.7 / electron 43 per the user report, so a targeted nixpkgs bump is needed to get 1.6.8; verify the version in that rev before claiming it.
- xdph issues #311 (modifier mismatch, multi-GPU-like), #403 and #434 (DMA-BUF fixation fails and falls back to SHM) are open with no documented fix.
- Re-check Vesktop#1207 and #1375 before recommending new flags.
