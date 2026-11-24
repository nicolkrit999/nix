# test-gnome-monitors

Guards the declarative GNOME monitor layout (`programs.gnome.monitors`, `modules/nixos/programs/de-wm/gnome/gnome-main.nix`): the generated `/etc/xdg/monitors.xml` (Mutter), the validating assertions, the "incomplete input warns and writes nothing" behavior, the primary fallback and the overlap check.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-gnome-monitors`.

From repo root: `bash templates/tests/nixos/test-gnome-monitors/check-nixos-gnome-monitors.sh`. From inside the directory: `bash check-nixos-gnome-monitors.sh`.

Eval only, no builds. `heavy-a` CI group, 6 minute cap (`test.conf`).

## How it works

`01-scenario-gnome-monitors.nix` builds twins of the minimal fixture host (`lib/fixture-host.nix`, from scratch, only GNOME and the monitor list set) and compares `environment.etc."xdg/monitors.xml".text` character for character with an independent prediction written in the scenario (anchored by a spelled-out literal for one monitor). Assertion and warning twins each break exactly one rule; failing `programs.gnome.monitors:` assertions are read from `config.assertions`, warnings from `config.warnings`. The real desktop is only read (declared layout, generated XML, no assertion or warning). Mirror coverage lives in the fixture twins; the desktop itself does not mirror.

## Checks

| Check | Expected |
|-------|----------|
| xml: one primary monitor | equals the spelled-out literal; the predictor reproduces that literal |
| xml: four rotations + scale + replica + disabled output + fallback | equals the prediction (`normal/left/upside_down/right`, `<layoutmode>logical`, exact refresh formatting) |
| xml: float formatting, transform names | `1.500000`, `59.940000`, `144`, all four rotation names present |
| xml: two configurations | replica and disabled block only in the first, primary once and layoutmode in each |
| xml: two replicas of one source | share one logical monitor with three monitors |
| xml: replica sharing | source takes the replica mode size in the mirrored configuration, its own mode in the plain one |
| xml: absent | no file for empty list, `*` only, GNOME disabled; no file plus one warning when only disabled outputs are declared |
| xml: controls | wrong rotation, dropped mirror, moved primary, changed serial and an absent file are each detected |
| assert: valid twins | no monitors assertion or warning |
| incomplete | missing vendor/product/serial/mode, incomplete replica or disabled output: one warning, no file, no assertion |
| primary | none marked: first enabled non-mirrored output with a warning; several marked: first marked with a warning; flag on a replica ignored |
| overlap | overlapping outputs rejected; scale and 90 degree rotation change the logical rectangle; disabled outputs exempt; exactly adjacent outputs accepted |
| assert: replicas of one source | different sizes rejected, same size accepted |
| assert: mirror/name/scale rules | undeclared mirror source, self mirror, duplicate names, two `*` entries, scale 0, bad characters in an output or mirror name (one combined bad twin, each message must appear) |
| assert: control | reader sees nothing on a valid twin and something on a bad one |
| real desktop | DP-1 primary 4K, DP-2, HDMI-1 disabled without mirror, no DP-3; XML equals the prediction from its own monitors; two configurations with HDMI-1 only in the disabled block of the first; no assertion or warning |
