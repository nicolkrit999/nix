# Hyprland switches a monitor to HDR when Chrome goes fullscreen

Found 2026-11-16 (Hyprland 0.57.2, desktop, two HDR-capable monitors).

**Symptom:** the YouTube PWA (Chrome `--app`) flips the whole monitor to HDR as soon as the video goes fullscreen, even for SDR video. Windowed it does not. Zen/Firefox never does it (no wp-color-management).

**Cause (traced with `WAYLAND_DEBUG` on Chrome):** since Hyprland PR #16674 (0.57) a fullscreen window's *preferred* image description is the monitor's HDR one (BT.2020 + PQ) when the monitor supports HDR (`Monitor.cpp getAutoHDRImageDescription`). Chrome adopts it, and `render:cm_auto_hdr = 1` (default) then sets the connector to BT2020_RGB + PQ.

**Fix in the repo:** a catch-all `no_auto_hdr` window rule (`hyprland-main.nix`, first entry of `staticWindowRules`). HDR is opt-in: `SUPER+CTRL+SHIFT+H` runs `hypr-hdr-toggle`, which flips the focused monitor (or `$1`) between `cm = srgb` and `cm = hdr` (only `output` + `cm` are sent; Hyprland keeps mode/position/scale). Chrome only sees the HDR display after a restart of the PWA, then YouTube shows the HDR quality label.

**What did NOT work (live-tested):**
- `render:cm_auto_hdr = 0` alone: metadata went SDR but the connector stayed BT2020_RGB, colours looked wrong.
- monitor `supports_hdr = 0` via `hyprctl eval`: no effect.
- `render:cm_enabled = false`: works (needs a new session) but hides the protocol, so YouTube never offers an HDR quality.

**Traps:** leaving HDR live can leave PQ on the connector until relogin (check with `drm_info`, see the HDR gotchas memory). `quirks:prefer_hdr` only makes surfaces prefer HDR more. Upstream PR #16976 (open, not in 0.57.2) adds an opt-in `cm_auto_hdr` mode; re-evaluate the rule when it lands.
