# sddm-astronaut_sddm-pixie

Verifies that `services.sddm-astronaut` and `services.sddm-pixie` are mutually
exclusive at eval time — both cannot be enabled in the same host.

Uses [nix-tests](https://github.com/danielefongo/nix-tests) — each `_test.nix`
file evaluates a fake host and asserts on the resulting config (assertions
firing, theme value) without building anything.

## Run all tests

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
