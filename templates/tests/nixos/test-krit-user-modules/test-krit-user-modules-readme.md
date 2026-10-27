# test-krit-user-modules

Eval-only guard for contracts of several `users/krit/nixos` modules that no other test covers: Dolphin (plasma-manager reset exclusion, thumbnailers, the declared places order and the script that applies it to an existing `user-places.xbel`), the helium-vs-chromium exclusion assertion, PWA desktop entries, rcloneMount being enabled by the cloud modules (minimal fixture), and the logitech `logid` restart trigger and udev rule.

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

Eval of several fresh `template-host-minimal` fixtures (one eval, no real host), plus one small build (the `dolphin-places-sync` wrapper and the seed xbel, python3 from the cache) for the places-sync section.

## How it works

`01-scenario-krit-user-modules.nix` builds fresh `template-host-minimal` hosts (`lib/fixture-host.nix`), each enabling only the module under test, and exposes one string per check (`"ok"` or `"FAIL: ..."`). The script runs `nix eval --json --impure` once and prints a per-check PASS/FAIL list. No real host is involved: which modules a real host enables is never asserted, and none of these contracts depends on the host.

Fixtures: `none` (no module), `dolphin`, `pwa`, `heliumOnly`, `both` (helium + chromium), `logid` (both MX Master mice), `only4` (MX Master 3S off) and `noMice` (logitech on, both mice off).

The rcloneMount contract is checked only on minimal fixtures (see below).

`02-scenario-dolphin-places.nix` (a fresh `template-host-minimal` fixture with only dolphin enabled) exposes the store paths and derivations of `dolphin-places-sync` and the seed xbel, parsed from the `createDolphinPlaces` activation text. The script then runs on fixture files in a temp dir: an old Dolphin file (pre-change order, Dolphin `Recent *` entries with KDE `<ID>` attributes, a user bookmark, `~/momentary` and `/mnt` appended at the end), a missing file, a malformed file and a file with a `<separator/>`. Home and flake directory come from the config (`home.homeDirectory`, `myconfig.constants.flakeDir`), nothing is hardcoded.

Controls: the `none` fixture must lack every module effect (dolphin exclusion and places activation, `pwa-*` entries, the logid service and udev rule); a planted `Plugins=` line and planted bad PWA entries must be flagged by the lints; the udev count must drop to 0 with both mice off, so the "exactly once" count is not vacuous; the fixture must start out of order, the order comparison must reject it and a swapped expectation.

## Checks

One eval on the fixtures above.

| Check | Expected |
|-------|----------|
| dolphin-resets-exclude-dolphinrc | `programs.plasma.resetFilesExclude` contains `dolphinrc` |
| dolphinrc-no-plugins-line | the generated `dolphinrc` has no `Plugins=` line |
| dolphin-thumbnailers-installed | `kdegraphics-thumbnailers` and `ffmpegthumbs` are installed |
| dolphin-installed-at-most-once | package name `dolphin` appears at most once (the module adds no `kdePackages.dolphin`) |
| dolphin-places-sync-wired | `createDolphinPlaces` runs `dolphin-places-sync` with the seed xbel, the live `~/.local/share/user-places.xbel` and `--last trash:/` (a planted unrelated command is rejected) |
| control-plugins-line-detected | the `Plugins=` lint flags a planted line |
| control-no-dolphin-no-contract | the `none` fixture has no `dolphinrc` exclusion and no `createDolphinPlaces` activation |
| helium-chromium-assertion-fires | helium + chromium together raise exactly one "mutually exclusive" assertion |
| helium-alone-no-assertion | helium with chromium off raises none |
| pwa-entries-plain-network | at least one `pwa-*` desktop entry; none has a `mimeType`, all have `categories == [ "Network" ]` |
| control-pwa-lint-detects | the PWA lint flags planted bad entries |
| control-no-pwa-entries-without-module | the `none` fixture has no `pwa-*` desktop entry |
| control-no-logid-service-without-module | the `none` fixture has no `logid` service and no `c548` udev rule |
| logid-restart-trigger | `systemd.services.logid.restartTriggers` contains the `logid.cfg` source |
| logid-trigger-follows-config | with one mouse off the `logid.cfg` source and the trigger change with it |
| logid-udev-rule-once | the `c548` receiver udev rule appears exactly once with both mice and with one mouse |
| control-logid-udev-rule-absent-without-mice | the rule is gone with both mice off |

## Cloud modules (minimal fixture)

Runs once. `03-scenario-cloud-fixture.nix` builds fresh `template-host-minimal` hosts (`lib/fixture-host.nix`) that enable only the cloud module(s) under test.

| Check | Expected |
|-------|----------|
| each-cloud-module-enables-rclone-mount | with only one of google-drive, onedrive-personal, pcloud, proton-drive on: exactly one `rcloneMount.enable` definition comes from that module's file, it is `true`, and `rcloneMount.enable` evaluates true |
| all-cloud-modules-one-definition-each | with all four on: four definitions from `services/cloud/`, all `true` |
| control-no-cloud-module-no-definition | with none on: no definition from `services/cloud/` and `rcloneMount.enable` is false (the definition filter does not match everything) |

## Dolphin places sync (real script, fixture files)

Runs once (fixture host). Not part of the per-host JSON; each line prints PASS/FAIL.

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
