---
name: sddm-label-contrast-probe
description: SDDM pixie/astronaut custom-wallpaper label readability - pixie theme.conf rewrite drops upstream keys; build-time imagemagick luma analysis is cheap; mean luma misleads on busy images
metadata:
  type: project
---

Probe on 2026-10-10 (read-only), for making SDDM labels readable on a custom `background`.

- sddm-pixie.nix only writes its own theme.conf when `themeConfig`/`background` is set, and it writes the WHOLE file. That drops upstream `autoColor=true`, `textColor`, `backgroundColor`, `use24HourClock`, so the upstream in-QML hue extractor turns off and `config.textColor` is undefined. Without overrides, the stylix accent is never applied (upstream #A9C78F is used).
- sddm-astronaut is always the "patched" derivation, because `Font` is always injected. The form column is width/2.5 (center or left). The stylix block auto-enables only when `background` is set.
- Build-time analysis inside the theme derivation works without IFD: `imagemagick` (212.8 MiB closure, cached), `img[0]` handles gif, and `ffmpeg-headless -frames:v 1` handles mp4. A single magick pass takes about 0.5 s. Nix eval of the flake dominates the cost (about 4 s).
- Mean luminance is unreliable on high-variance images (pixie default sd=0.31: dark text fails 3:1 on 65% of pixels, light text on 34%). Use the fraction of failing pixels, and account for pixie's own 0.4/0.6 black overlay.

**How to apply:** start from these findings when implementing smart SDDM label colours. Don't re-probe.
