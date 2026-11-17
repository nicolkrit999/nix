# sddm-themes

Verifies that the three SDDM theme modules (`services.sddm-astronaut`, `services.sddm-pixie`,
`services.sddm-qylock`) are mutually exclusive at eval time: the single assertion in
`modules/nixos/services/sddm/sddm-exclusive.nix` fires when two or three of them are enabled in the same host,
and its message lists exactly the enabled ones.

Uses [nix-tests](https://github.com/danielefongo/nix-tests) — each `_test.nix`
file evaluates a fake host and asserts on the resulting config (assertions
firing, theme value) without building anything. Fake hosts (`shared/mk-fake-host.nix`) enable only the theme
modules under test.

## Run all tests

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-conflicting-modules` (name as shown by `--list`).

```bash
nix run github:danielefongo/nix-tests -- templates/tests/nixos/conflicting-modules/sddm-themes
```

Or from inside the directory:

```bash
nix run github:danielefongo/nix-tests -- .
```

## Run a single test file manually

```bash
nix run github:danielefongo/nix-tests -- conflict/04-all-three_test.nix
```

## Test categories

| Prefix | What it checks |
|--------|---------------|
| `conflict/` | Assertion must fire for every pair and for all three theme modules |
| `positive/` | Each module alone and none: assertion silent, correct theme picked |

## Checks

| Scenario | Check | Expected |
|----------|-------|----------|
| C01 astronaut + pixie | failing assertion with `Enabled: services.sddm-astronaut, services.sddm-pixie.` | true |
| C01 | number of failing assertions containing "mutually exclusive" / `Enabled:` names qylock | exactly 1 / false |
| C02 astronaut + qylock | failing assertion with `Enabled: services.sddm-astronaut, services.sddm-qylock.` | true |
| C02 | number of failing "mutually exclusive" assertions / `Enabled:` names pixie | exactly 1 / false |
| C03 pixie + qylock | failing assertion with `Enabled: services.sddm-pixie, services.sddm-qylock.` | true |
| C03 | number of failing "mutually exclusive" assertions / `Enabled:` names astronaut | exactly 1 / false |
| C04 all three | failing assertion with `Enabled: services.sddm-astronaut, services.sddm-pixie, services.sddm-qylock.` | true |
| C04 | number of failing "mutually exclusive" assertions | exactly 1 |
| P01 only astronaut | any "mutually exclusive" assertion fails | false |
| P01 | `services.displayManager.sddm.theme` | `sddm-astronaut-theme` |
| P02 only pixie | any "mutually exclusive" assertion fails | false |
| P02 | `services.displayManager.sddm.theme` | `pixie` |
| P03 only qylock | any "mutually exclusive" assertion fails | false |
| P03 | `services.displayManager.sddm.theme` | `pixel-hollowknight` |
| P04 none | any "mutually exclusive" assertion fails | false |
| P04 | `services.displayManager.sddm.enable` | false |

The positive "no mutex assertion" checks are only meaningful because the conflict scenarios prove the same
message text is emitted when two or three modules are on.
