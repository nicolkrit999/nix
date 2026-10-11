# sddm-astronaut_sddm-pixie

Verifies that `services.sddm-astronaut` and `services.sddm-pixie` are mutually
exclusive at eval time — both cannot be enabled in the same host.

Uses [nix-tests](https://github.com/danielefongo/nix-tests) — each `_test.nix`
file evaluates a fake host and asserts on the resulting config (assertions
firing, theme value) without building anything.

## Run all tests

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-conflicting-modules` (name as shown by `--list`).

```bash
nix run github:danielefongo/nix-tests -- templates/tests/nixos/conflicting-modules/sddm-astronaut_sddm-pixie
```

Or from inside the directory:

```bash
nix run github:danielefongo/nix-tests -- .
```

## Run a single test file manually

```bash
nix run github:danielefongo/nix-tests -- conflict/01-both-sddm-themes_test.nix
```

## Test categories

| Prefix | What it checks |
|--------|---------------|
| `conflict/` | Assertion must fire when both `sddm-astronaut` and `sddm-pixie` are enabled |
| `positive/` | Each one enabled alone — assertion silent, correct theme picked |

## Checks

| Scenario | Check | Expected |
|----------|-------|----------|
| C01 both | assertion `services.sddm-astronaut and services.sddm-pixie are mutually exclusive` fails | true |
| C01 both | number of failing assertions containing "mutually exclusive" | exactly 1 |
| P01 only astronaut | specific mutex assertion fails / any "mutually exclusive" assertion fails | false / false |
| P01 only astronaut | `services.displayManager.sddm.theme` | `sddm-astronaut-theme` |
| P02 only pixie | specific mutex assertion fails / any "mutually exclusive" assertion fails | false / false |
| P02 only pixie | `services.displayManager.sddm.theme` | `pixie` |

The positive "no mutex assertion" checks are only meaningful because C01 proves the
same message text is emitted when both are on.
