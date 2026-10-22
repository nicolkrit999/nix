---
name: sddm-label-contrast-probe
description: SDDM pixie/astronaut custom-wallpaper label readability - pixie theme.conf rewrite drops upstream keys; build-time imagemagick luma analysis is cheap; mean luma misleads on busy images
metadata:
  type: project
---

Probe on 2026-10-10 (read-only), for making SDDM labels readable on a custom `background`.

- sddm-pixie.nix always edits the upstream theme.conf in place with `setKey` (replace an existing `key=` line, append a missing one), so upstream keys it does not set (`use24HourClock`, ...) survive. It always writes `accentColor` (stylix base16 accent) and `fontFamily`; with a `background` it also writes `autoColor=false`, `textColor`, `backgroundColor` and a palette accent, which turns the upstream in-QML hue extractor off. Without a background, upstream `autoColor=true` stays and `config.textColor` is whatever upstream ships.
- sddm-astronaut is always the "patched" derivation, because `Font` is always injected. The form column is width/2.5 (center or left). The stylix block auto-enables only when `background` is set.
- Build-time analysis inside the theme derivation works without IFD: `imagemagick` (212.8 MiB closure, cached), `img[0]` handles gif, and `ffmpeg-headless -frames:v 1` handles mp4. A single magick pass takes about 0.5 s. Nix eval of the flake dominates the cost (about 4 s).
- Mean luminance is unreliable on high-variance images (pixie default sd=0.31: dark text fails 3:1 on 65% of pixels, light text on 34%). Use the fraction of failing pixels, and account for pixie's own 0.4/0.6 black overlay.

**How to apply:** start from these findings when implementing smart SDDM label colours. Don't re-probe.

Update 2026-10-22: the pixie readability test's controls patch the BUILT QML with regexes, so any module value change (hint 0.85 -> 1.0) silently breaks a control ("mutation pattern not found"); controls now edit inside the anchored block instead. Trap seen while extending the measure step: in awk `printf "%f", x > y ? a : b` is an OUTPUT REDIRECT to a file named y - parenthesise the ternary. Remaining known low-contrast spots (not fixed, design call): session/user popups on catppuccin-latte (its darkest neutral #4c4f69 is mid-tone, upstream Qt.lighter surfaces lose contrast) and the current user's initial (baseColor on accent) for light/low-contrast accents.
