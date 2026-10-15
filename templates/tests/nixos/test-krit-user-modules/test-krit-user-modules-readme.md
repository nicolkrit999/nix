# test-krit-user-modules

Eval-only guard for contracts of several `users/krit/nixos` modules that no other test covers: Dolphin (plasma-manager reset exclusion, thumbnailers, extra places), the helium-vs-chromium exclusion assertion, PWA desktop entries, rcloneMount being enabled by the cloud modules, and the logitech `logid` restart trigger and udev rule.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-krit-user-modules` (name as shown by `--list`).

From the repo root:

```bash
bash templates/tests/nixos/test-krit-user-modules/check-nixos-krit-user-modules.sh
```

From inside the directory:

```bash
bash check-nixos-krit-user-modules.sh
```

Eval only, no builds: four `extendModules` twins per host (`nixos-desktop`, `nixos-laptop`).

## How it works

`01-scenario-krit-user-modules.nix` reads `HOST_UNDER_TEST`, loads the real flake and exposes one string per check (`"ok"` or `"FAIL: ..."`). The script runs `nix eval --json --impure` once per host and prints a per-check PASS/FAIL list.

Which modules a host enables is never asserted: the twins force the modules under test on or off with `mkForce`, so every check runs the same way on both hosts. Twin `a` has dolphin, pwas, helium and logitech (both MX Master mice) on and chromium off; `both` adds chromium; `only4` turns the MX Master 3S off; `noMice` turns both off.

The rcloneMount check reads `options.myconfig.services.rcloneMount.enable.definitionsWithLocations` of the real host: one `true` definition must come from each enabled `services/cloud/*` module, so a cloud module can no longer be enabled without turning rcloneMount on (the host's own `rcloneMount.enable` is a separate definition and is not counted). If a failure shows an empty file list, the module-system `file` of a denix module no longer contains the module path and the filter needs adapting.

Controls: a planted `Plugins=` line and planted bad PWA entries must be flagged by the lints; the udev count must drop to 0 with both mice off, so the "exactly once" count is not vacuous.

## Checks

Per host.

| Check | Expected |
|-------|----------|
| dolphin-resets-exclude-dolphinrc | `programs.plasma.resetFilesExclude` contains `dolphinrc` |
| dolphinrc-no-plugins-line | the generated `dolphinrc` has no `Plugins=` line |
| dolphin-thumbnailers-installed | `kdegraphics-thumbnailers` and `ffmpegthumbs` are installed |
| dolphin-installed-at-most-once | package name `dolphin` appears at most once (the module adds no `kdePackages.dolphin`) |
| dolphin-places-momentary-and-mnt | `createDolphinPlaces` seeds and appends-if-missing bookmarks for `~/momentary` and `/mnt` |
| control-plugins-line-detected | the `Plugins=` lint flags a planted line |
| helium-chromium-assertion-fires | helium + chromium together raise exactly one "mutually exclusive" assertion |
| helium-alone-no-assertion | helium with chromium off raises none |
| pwa-entries-plain-network | at least one `pwa-*` desktop entry; none has a `mimeType`, all have `categories == [ "Network" ]` |
| control-pwa-lint-detects | the PWA lint flags planted bad entries |
| cloud-modules-enable-rclone-mount | each enabled cloud module defines `rcloneMount.enable = true` (definition count equals enabled cloud modules) |
| logid-restart-trigger | `systemd.services.logid.restartTriggers` contains the `logid.cfg` source |
| logid-trigger-follows-config | with one mouse off the `logid.cfg` source and the trigger change with it |
| logid-udev-rule-once | the `c548` receiver udev rule appears exactly once with both mice and with one mouse |
| control-logid-udev-rule-absent-without-mice | the rule is gone with both mice off |
