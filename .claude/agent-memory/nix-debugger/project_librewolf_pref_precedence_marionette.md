---
name: project-librewolf-pref-precedence-marionette
description: LibreWolf mozilla.cfg pref() beats user.js; fix is ~/.librewolf/librewolf.overrides.cfg with a per-profile marker; Marionette recommended prefs fake a captive-portal failure
metadata:
  type: project
---

Order in LibreWolf 157: user.js < mozilla.cfg `pref()` (autoconfig) < `~/.librewolf/librewolf.overrides.cfg` (nsAutoConfig via `autoadmin.global_config_url`, set in omni.ja `defaults/autoconfig/prefcalls.js`, profile-after-change). `lockPref` beats all. HM `programs.librewolf.settings` writes `defaultPref()` there, so it can't beat a `pref()`. The overrides file is install-wide. The module picks per-profile values via `getPref("nixcfg.librewolf.profile")`, a marker pref in each user.js (2026-10-15).

**Why:** the Privacy profile silently lost webgl.disabled, permissions.manager.defaultsUrl, captive-portal-service.enabled and captivedetect.canonicalURL (mozilla.cfg:261/313/867/868).

**How to apply:** any headless Marionette harness must set `remote.prefs.recommended=false`. Otherwise Marionette writes `network.captive-portal-service.enabled=false` into prefs that have no user value. Re-asserting `true` equals Firefox's browser default, so it leaves no user value and looks like a config failure. Path choice: profile dir containing `.librewolf` = `~/.librewolf/librewolf.overrides.cfg`; otherwise the XDG path, if `widget.support-xdg-config` is set.
