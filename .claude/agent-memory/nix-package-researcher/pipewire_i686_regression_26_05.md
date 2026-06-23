---
name: pipewire_i686_regression_analysis_26_05
description: Nixpkgs 26.05 openblas i686 regression in pipewire dependencies-which parameters block it
metadata:
  type: reference
---

## Nixpkgs 26.05 Regression: i686-linux in pipewire chain (commit 3426825)

**Root issue:** Two default pipewire features pull in packages with i686-linux dependencies:

### 1. ffadoSupport=true (default)
- ffado → has i686-specific `builder.pl` file
- **Fix:** `ffadoSupport = false`

### 2. libcamera (default: enabled)
- libcamera → pybind11 → numpy → openblas-0.3.33 → **requests i686-linux**
- **Fix:** `libcamera = null` (disable entirely)

### Pipewire override parameters (complete list from 26.05)
[Full list from nix eval]:
- alsa-lib, avahi, bashNonInteractive, bluez, bluezSupport, buildPackages, dbus, docutils, doxygen, elogind, enableSystemd, epoll-shim, fdk_aac, fetchFromGitLab, fetchpatch, ffado, **ffadoSupport**, ffmpeg-headless, fftwFloat, freebsd, glib, graphviz, gst_all_1, ldacBtDecodeSupport, ldacbt, lib, **libcamera**, libcanberra, libdrm, libebur128, libfreeaptx, libinotify-kqueue, libjack2, liblc3, libldac-dec, libmysofa, libopus, libpulseaudio, libselinux, libsndfile, libusb1, libx11, libxcb, libxfixes, lilv, makeFontsConf, meson, modemmanager, ncurses, ninja, nixosTests, **onnxruntime**, **onnxruntimeSupport**, openssl, pkg-config, python3, raopSupport, readline, roc-toolkit, **rocSupport**, sbc, spandsp, stdenv, systemd, testers, udev, valgrind, **vulkan-headers**, **vulkan-loader**, **vulkanSupport**, webrtc-audio-processing, x11Support, zeroconfSupport

### Parameters NOT pulling openblas/i686:
- **rocSupport** (default: false) - roc-toolkit → scons → python3 (no numpy/openblas)
- **vulkanSupport** (default: false) - safe
- **onnxruntimeSupport** (default: false) - has python but no i686-pulling deps in pipewire context
- Other parameters safe by default

### Minimal targeted fix (IMPLEMENTED)
```nix
nixpkgs.overlays = [
  (final: prev: {
    pipewire = prev.pipewire.override {
      ffadoSupport = false;
      libcamera = null;
    };
  })
];
```

**Status:** Both i686-pulling chains are BLOCKED. No additional parameters needed.
