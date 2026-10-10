---
name: base16-base07-not-brightest
description: base16 base07 is NOT guaranteed to be the brightest fg (rose-pine-moon base07=56526e, 2.11:1 vs base00); and over-wallpaper text contrast is set by the wallpaper, not the scheme
metadata:
  type: project
---

Some base16 schemes break the "base05..base07 = increasingly bright foreground" ordering. rose-pine-moon (nixos-laptop): base05 = base06 = e0def4, base07 = 56526e (a dark color, 2.11:1 against base00). Picking "the brightest text" with base07 gives unreadable text.

Probe on 2026-10-10 (hyprlock readability, laptop): the labels are base05 at 0.75 alpha drawn directly on imgur_japan_2.jpg with blur 0. The wallpaper behind the labels has linear luminance around 0.42 to 0.46, so the contrast is about 1.4 to 1.7:1, whatever the scheme. base00 on that same area would be about 7:1. Waybar stays readable only because it draws base01/base00 pills behind base05 text. It does not detect the shade at all.

**Why:** both mistakes look like "pick a better stylix color", but the real fix is to control the backdrop (shape plates, shadows, background brightness/blur).

**How to apply:** for any text drawn over a wallpaper (hyprlock, SDDM, a widget), first measure the wallpaper region with `magick ... -colorspace RGB -crop WxH+X+Y -grayscale Rec709Luminance -format '%[fx:mean]'`. Don't assume base07 is the brightest color. Work out which side is light from the luminance of base00 against base05, not from a fixed index.
