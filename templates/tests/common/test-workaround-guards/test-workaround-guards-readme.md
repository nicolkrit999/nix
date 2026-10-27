# test-workaround-guards

Guards for the momentary workarounds (vicinae gcc15Stdenv override, tgt TDLib pin): each must stay effective, and the test says when one has become removable.

## Run

From the repo root:

```bash
bash templates/tests/common/test-workaround-guards/check-common-workaround-guards.sh
```

From inside the directory:

```bash
bash check-common-workaround-guards.sh
```

## How it works

`01-scenario-workaround-guards.nix` loads the real flake and builds fresh fixtures from `template-host-minimal` through `templates/tests/lib/fixture-host.nix`: one with only vicinae enabled, one with only tgt enabled. The TDLib pin check reads `myconfig.programs.tgt.package` from the plain minimal fixture without enabling tgt. No real host is read. `check-common-workaround-guards.sh` runs `nix eval --raw` per attribute: `ok` is PASS, `FAIL: ...` or an eval error is FAIL. Attributes named `warn-*` are staleness controls comparing the workaround against the plain upstream value; they report WARN (never fail) with the memory file to update when the upstream gap is closed. Effectiveness checks compare against independent sources (`pkgs.stdenv`, plain `legacyPackages`, the locked `tgt` input's `Cargo.lock`). Only the final result is non-zero on FAIL. Runtime about 25 s warm.

## Checks

### vicinae (memory: vicinae-gcc15stdenv-override)

| Check | Expected |
|-------|----------|
| HM package cc version | equals the minimal fixture's own `pkgs.stdenv.cc.version` |
| input-server package cc version | equals the minimal fixture's own `pkgs.stdenv.cc.version` |
| HM and input-server package | same drvPath |
| warn: upstream vicinae cc version | differs from ours, else override removable |

### tgt (memory: project-tgt-tdlib-pin)

| Check | Expected |
|-------|----------|
| `tgt` packages in `environment.systemPackages` of a minimal fixture with only tgt enabled | 1 |
| control: `tgt` packages in `environment.systemPackages` of the minimal fixture with tgt disabled | 0 |
| installed `tgt` drvPath vs `myconfig.programs.tgt.package` | equal |
| `tdlib` versions in `myconfig.programs.tgt.package`'s `buildInputs` (tgt not enabled) | exactly `[ "1.8.61" ]` (the pin) |
| `tdlib-rs` version in the locked `tgt` input's `Cargo.lock` | `1.4.0` (the version the pin was derived for), else FAIL: re-derive the pin |
| warn: `pkgs.tdlib.version` | differs from the pin, else pin removable |
