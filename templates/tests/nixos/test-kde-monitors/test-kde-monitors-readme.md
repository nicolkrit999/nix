# test-kde-monitors

Guards the declarative Plasma monitor layout (`programs.kde.monitors`, `modules/nixos/programs/de-wm/kde/kde-main.nix`): the generated `kscreen-doctor` plan, the validating assertions and the user oneshot service.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-kde-monitors`.

From repo root: `bash templates/tests/nixos/test-kde-monitors/check-nixos-kde-monitors.sh`. From inside the directory: `bash check-nixos-kde-monitors.sh`.

Eval only, no builds. `heavy-a` CI group, 4 minute cap (`test.conf`).

## How it works

`01-scenario-kde-monitors.nix` builds twins of the minimal fixture host (`lib/fixture-host.nix`, from scratch, only KDE and the monitor list set) and compares the rendered `xdg.configFile."kde-monitors/plan"` line for line with an independent prediction written in the scenario. Assertion twins each break exactly one rule and the failing `programs.kde.monitors:` messages are read from `config.assertions`. The real laptop and desktop are only read (monitor values, plan, service presence).

## Checks

| Check | Expected |
|-------|----------|
| plan: rotated source + mirror replica + disabled + fallback | plan equals the prediction (`mirror.none` for non-mirrored, `mirror.<SRC>` for the replica, `disable` line, no `*` line) |
| plan: prediction spelled out | the three exact lines |
| plan/service: option default (empty) and fallback only | no plan file, no service |
| plan: controls | wrong rotation, dropped mirror, missing disable line, absent plan are each detected |
| assert: valid twins | no monitors assertion fails |
| assert: duplicate names, self-mirror, undeclared source, source that mirrors, bad chars in mirror and in output, scale 0 | the matching assertion fails (exactly one where the rule is isolated) |
| assert: control | reader sees nothing on a valid twin and something on a bad one |
| service | oneshot, `is-kde-session` ExecCondition, WantedBy graphical-session.target; absent with KDE off; control: checker flags a missing service |
| real laptop | eDP-1 3200x2000@120, plan equals prediction, no assertion fails |
| real desktop | plan equals prediction, `HDMI-A-1` mirrors `DP-1`, no assertion fails |
