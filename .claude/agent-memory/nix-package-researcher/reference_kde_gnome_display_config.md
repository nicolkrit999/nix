---
name: kde-gnome-display-config-persistence
description: KWin 6.8 kwinoutputconfig.json schema, kscreen-doctor syntax, Mutter 50.5 monitors.xml schema and DisplayConfig D-Bus apply; no plasma-manager/HM/NixOS option for outputs on either DE
metadata:
  type: reference
---

Locked inputs at research time (2026-10-28): plasma-manager a19a2a02, nixpkgs (repo root `nixpkgs` = nixpkgs_2, rev 31ecbaca) with Plasma/KWin 6.8.1, libkscreen 6.8.1, Mutter 50.5, gnome-shell 50.4.

- No declarative output option exists: plasma-manager has no kscreen/outputs/kwin-output module (only kscreenlocker, kwin effects, startup scripts); nixpkgs plasma6 module only ships kscreen/libkscreen as packages; no HM or NixOS option writes monitors.xml.
- KWin persists to `~/.config/kwinoutputconfig.json` (QStandardPaths ConfigLocation, load via locate, save via plain QFile WriteOnly). Top level is a JSON array of `{"name":"outputs","data":[...]}` and `{"name":"setups","data":[...]}`. No `version` key, no `outputOrder` key.
- outputs[].data keys: edidIdentifier, edidHash, mstPath, connectorName, mode `{flags, basic:{width,height,refreshRate(mHz)}}`, scale, transform (Normal/Rotated90/Rotated180/Rotated270/Flipped*), vrrPolicy (Never/Automatic/Always), plus many colour/HDR keys.
- setups[].data[].outputs[] keys: enabled, outputIndex, priority, position{x,y}, replicationSource. `outputIndex` points into the outputs array.
- Matching (storeConfig/findOutputIndex): edidIdentifier if unique, else edidHash, then mstPath, then connectorName.
- kscreen-doctor (libkscreen src/doctor/doctor.cpp): `output.NAME.mode.WxH@Hz|id`, `.scale.N`, `.rotation.{none,left,right,inverted,flipped,flipped90,flipped180,flipped270}`, `.position.X,Y`, `.priority.1-100`, `.enable`, `.disable`, `.hdr.enable`, `.dpms.on|off`.
- Mutter 50.5 `meta-monitor-config-store.c`: `~/.config/monitors.xml` `<monitors version="2">` with `<configuration>`, `<logicalmonitor>` (x,y,scale,primary,monitor/monitorspec{connector,vendor,product,serial}/mode{width,height,rate}, transform{rotation,flipped}), `<disabled>` block lists disabled outputs (not omitted). Matching is by monitorspec equality (connector+vendor+product+serial). Written only on persistent apply confirmation (DisplayConfig method 2). Method enum: VERIFY=0, TEMPORARY=1, PERSISTENT=2.
- Mutter 50.5 experimental map (meta-settings.c) only has kms-modifiers and autoclose-xwayland. scale-monitor-framebuffer and xwayland-native-scaling are no longer recognised; fractional scaling needs no flag. The gschema still lists them (stale).
- GDM greeter home on NixOS is `/run/gdm/home/gdm-greeter` (gdm.nix). Only pulse tmpfiles exist there; no monitors option.

Why: answering "can outputs be declarative for KDE/GNOME" needs these paths and enums; re-deriving them costs a full kwin/mutter source pull.
How to apply: when a host needs declarative monitor layout, use a seed file (KDE: writable kwinoutputconfig.json via home.activation; GNOME: environment.etc "xdg/monitors.xml" system fallback or a user copy) or a login script; re-verify against the locked versions first since KWin/Mutter formats change between majors.

## Mirroring (verified 2026-11-24 against KDE/kwin and KDE/libkscreen tag v6.8.1)
- Re-check on plasma-manager 2026-11-24: locked a19a2a02 and upstream HEAD both still have no kscreen/outputs/monitor module; open issue #172 "Monitor configuration" unanswered. Only open PR touching display is #657 (per-output virtual desktop, unrelated).
- kwinoutputconfig.json: mirror is `setups[].data[].outputs[].replicationSource`, and its value is the **uuid string** of the source output (the `uuid` key inside that source's `outputs[].data` entry), NOT an index. KWin only keeps it when it differs from the output's own uuid. A replicated output takes effect only if its source is enabled.
- kscreen-doctor: `output.<replica>.mirror.<source>` where `<source>` is the output name OR uuid (libkscreen `Doctor::findOutput`); `output.<replica>.mirror.none` clears it. Applied through KWin, so it persists into kwinoutputconfig.json as a uuid.
- Pitfall: a seed JSON must include a stable `uuid` on the source output, or the replicationSource will not match.
