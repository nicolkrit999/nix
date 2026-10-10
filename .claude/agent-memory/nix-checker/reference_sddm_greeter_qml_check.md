---
name: sddm-greeter-qml-check
description: How to detect QML errors in an SDDM theme with sddm-greeter-qt6 --test-mode; default output hides them
metadata:
  type: reference
---

`sddm-greeter-qt6 --test-mode --theme <dir>` prints NOTHING for broken QML by default. When `Main.qml` fails to compile (verified with an unknown type, `NotARealType {}`), the greeter silently falls back to the embedded `qrc:/theme/Main.qml`, and a missing theme dir also prints nothing.

To surface errors, run with `QT_FORCE_STDERR_LOGGING=1` and grep for:
`Fallback to embedded`, `is not a type`, `ReferenceError`, `TypeError`, `is not installed`, `.qml:<n>:`, `Cannot assign`, `Failed to load`.

Expected noise on this host (present even on a clean no-background baseline, so not a theme error): `qmlRegisterType requires absolute URLs` (x40), `qt.qml.propertyCache.append ... PopupList` (astronaut only), `Couldn't load pipewire-0.3`, `Failed to open VDPAU backend libvdpau_nvidia.so`, `Socket error: QLocalSocket::connectToServer`.

The greeter does not exit on its own, so `timeout 8` returns rc=124 on a healthy run. That is not a failure.

**Why:** a clean default-mode run looked like a PASS, and only a deliberately broken control theme exposed that the check was blind. Always run a control theme when validating this harness.

**How to apply:** use this forced-logging check for any SDDM theme QML validation. Only the first 8 seconds of the greeter are exercised, so later interactions (login, password entry) are not covered.

