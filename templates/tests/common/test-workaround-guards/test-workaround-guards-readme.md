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

`01-scenario-workaround-guards.nix` loads the real flake and evaluates `nixos-desktop`. `check-common-workaround-guards.sh` runs `nix eval --raw` per attribute: `ok` is PASS, `FAIL: ...` or an eval error is FAIL. Attributes named `warn-*` are staleness controls comparing the workaround against the plain upstream value; they report WARN (never fail) with the memory file to update when the upstream gap is closed. Effectiveness checks compare against independent sources (`pkgs.stdenv`, plain `legacyPackages`, the locked `tgt` input's `Cargo.lock`). Only the final result is non-zero on FAIL. Runtime about 25 s warm.

## Checks

### vicinae (memory: vicinae-gcc15stdenv-override)

| Check | Expected |
|-------|----------|
| HM package cc version | equals `pkgs.stdenv.cc.version` |
| input-server package cc version | equals `pkgs.stdenv.cc.version` |
| HM and input-server package | same drvPath |
| warn: upstream vicinae cc version | differs from ours, else override removable |

### tgt (memory: project-tgt-tdlib-pin)

| Check | Expected |
|-------|----------|
| `tgt` packages in nixos-desktop `environment.systemPackages` | 1 |
| `tdlib` versions in the tgt package's `buildInputs` | exactly `[ "1.8.61" ]` (the pin) |
| `tdlib-rs` version in the locked `tgt` input's `Cargo.lock` | `1.4.0` (the version the pin was derived for), else FAIL: re-derive the pin |
| warn: `pkgs.tdlib.version` | differs from the pin, else pin removable |
