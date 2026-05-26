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

```bash
nix run github:danielefongo/nix-tests -- templates/tests/nixos/conflicting-modules
```

`nix-tests` recurses into all subfolders and runs every `_test.nix` it finds.
