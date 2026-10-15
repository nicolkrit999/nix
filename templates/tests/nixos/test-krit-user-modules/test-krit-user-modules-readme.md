# test-krit-user-modules

Eval-only guard for contracts of several `users/krit/nixos` modules that no other test covers: Dolphin (plasma-manager reset exclusion, thumbnailers, the declared places order and the script that applies it to an existing `user-places.xbel`), the helium-vs-chromium exclusion assertion, PWA desktop entries, rcloneMount being enabled by the cloud modules, and the logitech `logid` restart trigger and udev rule.

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

Eval of four `extendModules` twins per host (`nixos-desktop`, `nixos-laptop`), plus one small build (the `dolphin-places-sync` wrapper and the seed xbel, python3 from the cache) for the places-sync section.

## How it works

`01-scenario-krit-user-modules.nix` reads `HOST_UNDER_TEST`, loads the real flake and exposes one string per check (`"ok"` or `"FAIL: ..."`). The script runs `nix eval --json --impure` once per host and prints a per-check PASS/FAIL list.

Which modules a host enables is never asserted: the twins force the modules under test on or off with `mkForce`, so every check runs the same way on both hosts. Twin `a` has dolphin, pwas, helium and logitech (both MX Master mice) on and chromium off; `both` adds chromium; `only4` turns the MX Master 3S off; `noMice` turns both off.

The rcloneMount check reads `options.myconfig.services.rcloneMount.enable.definitionsWithLocations` of the real host: one `true` definition must come from each enabled `services/cloud/*` module, so a cloud module can no longer be enabled without turning rcloneMount on (the host's own `rcloneMount.enable` is a separate definition and is not counted). If a failure shows an empty file list, the module-system `file` of a denix module no longer contains the module path and the filter needs adapting.

`02-scenario-dolphin-places.nix` (desktop only, dolphin forced on) exposes the store paths and derivations of `dolphin-places-sync` and the seed xbel, parsed from the `createDolphinPlaces` activation text. The script then runs on fixture files in a temp dir: an old Dolphin file (pre-change order, Dolphin `Recent *` entries with KDE `<ID>` attributes, a user bookmark, `~/momentary` and `/mnt` appended at the end), a missing file, a malformed file and a file with a `<separator/>`. Home and flake directory come from the config (`home.homeDirectory`, `myconfig.constants.flakeDir`), nothing is hardcoded.

Controls: a planted `Plugins=` line and planted bad PWA entries must be flagged by the lints; the udev count must drop to 0 with both mice off, so the "exactly once" count is not vacuous; the fixture must start out of order, the order comparison must reject it and a swapped expectation.

## Checks

Per host.

| Check | Expected |
|-------|----------|
| dolphin-resets-exclude-dolphinrc | `programs.plasma.resetFilesExclude` contains `dolphinrc` |
| dolphinrc-no-plugins-line | the generated `dolphinrc` has no `Plugins=` line |
| dolphin-thumbnailers-installed | `kdegraphics-thumbnailers` and `ffmpegthumbs` are installed |
| dolphin-installed-at-most-once | package name `dolphin` appears at most once (the module adds no `kdePackages.dolphin`) |
| dolphin-places-sync-wired | `createDolphinPlaces` runs `dolphin-places-sync` with the seed xbel, the live `~/.local/share/user-places.xbel` and `--last trash:/` (a planted unrelated command is rejected) |
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

## Dolphin places sync (real script, fixture files)

Runs once (desktop). Not part of the per-host JSON; each line prints PASS/FAIL.

| Check | Expected |
|-------|----------|
| locate and build | the sync wrapper and the seed xbel are found in the activation text and build |
| precondition | the old-style fixture is not already in the declared order |
| existing file: order | Home, Documents, Pictures, nix (`~/<flakeDir>`), Downloads, momentary, mnt, Network, then the other existing places in their old order (Recent Files, Recent Locations, the user bookmark), Trash last |
| existing file: well-formed, header, KDE attributes, extras | result parses as xbel; Dolphin header metadata, bookmark `<ID>` attributes and the user bookmark with its title are kept |
| existing file: nothing lost, no duplicate, .bak | 12 bookmarks (10 plus Pictures and nix), no duplicate href, the previous file saved as `.bak` |
| second run | exit 0, byte-identical file, `.bak` still holds the original |
| later user bookmark | a bookmark added afterwards lands last before Trash, Trash stays last, managed places stay first |
| missing file | created from the seed in the declared order, mode 644 |
| malformed file | sync fails, file untouched, no `.bak` |
| content between bookmarks | sync fails (it would be lost), file untouched |
| no temp files | no `.user-places.*` temp file is left behind |
| control: order comparison | rejects the unsynced fixture and a swapped expectation (which differs from the real one) |
