# conflicting-modules

Tests that verify mutually exclusive modules produce a build-time assertion
when enabled together (instead of silently breaking).

Each subfolder targets a specific pair (or group) of conflicting modules and
contains its own README, `shared/`, `conflict/`, `positive/` setup.

## Subfolders

| Folder | What it tests |
|--------|---------------|
| [`auto-cpu-freq_tlp/`](auto-cpu-freq_tlp/) | `services.tlp` vs `services.auto-cpufreq` |
| [`sddm-astronaut_sddm-pixie/`](sddm-astronaut_sddm-pixie/) | `services.sddm-astronaut` vs `services.sddm-pixie` |

## Run all conflict tests

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-conflicting-modules` (name as shown by `--list`).

```bash
nix run github:danielefongo/nix-tests -- templates/tests/nixos/conflicting-modules
```

`nix-tests` recurses into all subfolders and runs every `_test.nix` it finds.

**Store independence:** the `stylix-hm.nix` stubs use the inline scheme `templates/tests/lib/scheme-catppuccin-mocha.nix` instead of reading the base16-schemes package. The harness evaluates read-only, so an IFD only works on a warm store (fresh CI legs failed with "base16-schemes ... .drv is not valid"); `run-test.py` runs harness commands with `allow-import-from-derivation = false` so a regression fails locally too.
