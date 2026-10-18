# test-mango-screenshot-fields

Guards the `mango-screenshot` helper (`modules/nixos/programs/de-wm/mango/mango-binds.nix`): its `jq` filter over `mmsg get all-monitors` (`.monitors[] | select(.active) | .name`) must use field names that the pinned mango really emits. mango renamed IPC keywords before; a renamed JSON field would make the filter return nothing and the screenshot silently capture every output instead of the active one.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-mango-screenshot-fields` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/nixos/test-mango-screenshot-fields/check-nixos-mango-screenshot-fields.sh
```

From inside the directory:

```bash
bash check-nixos-mango-screenshot-fields.sh
```

Needs `jq` (the script re-runs itself under `nix shell` when missing). Builds only the tiny script derivation. `nixos-b` CI group, 5 minute cap (`test.conf`).

## How it works

`01-scenario-mango-screenshot-fields.nix` locates the real `mango-screenshot` store path and `.drv` from the `nixos-desktop` mango binds (same technique as `test-mango-ipc-helpers`) and exposes the pinned `inputs.mango` source path. The check script builds the script, extracts the field names from its jq filter, and verifies each one is emitted by `build_monitor_json` (or is the top-level `monitors` key) in the pinned `src/ipc/ipc.c`. It then runs the real script with stub `mmsg`, `grim`, `wl-copy` and `notify-send` against `fixture-all-monitors.json`, a hand-written two-monitor subset of the JSON mango produces (fake output names `TEST-1`/`TEST-2`; every fixture key is itself verified against `ipc.c`).

Not covered: the live `mmsg` binary; there is no running mango in CI. The ipc.c check is the stand-in for a captured live JSON.

## Checks

| Check | Expected |
|-------|----------|
| script has an all-monitors jq filter | the script text contains `mmsg get all-monitors` |
| build_monitor_json found in the pinned mango ipc.c | the function body is extractable (non-vacuity) |
| every jq field of the script is emitted by the pinned mango | at least 3 fields, each added by `build_monitor_json` or the top-level `monitors` key |
| control: a planted unknown field is rejected | a filter using `.focused` is not accepted |
| fixture top-level key monitors is emitted by mango | `ipc.c` adds `monitors` to the response |
| every fixture monitor key is emitted by build_monitor_json | the fixture cannot drift from mango's real keys |
| fixture: grim is told to capture the active monitor | `grim -o TEST-2` (the fixture's active output) |
| control: renamed active field -> no output pinned | fixture with `active` renamed: `grim` gets no `-o` |
| control: no active monitor -> no output pinned | fixture with all `active=false`: no `-o` |
| control: renamed name field -> no output pinned | fixture with `name` renamed: no `-o` |
