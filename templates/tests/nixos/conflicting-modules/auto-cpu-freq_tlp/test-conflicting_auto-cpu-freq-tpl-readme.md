# auto-cpu-freq_tlp

Verifies that `services.tlp` and `services.auto-cpufreq` are mutually exclusive
at eval time — both cannot be enabled in the same host.

Uses [nix-tests](https://github.com/danielefongo/nix-tests) — each `_test.nix`
file evaluates a fake host and asserts on the resulting config (assertions
firing, enable values) without building anything.

## Run all tests

```bash
nix run github:danielefongo/nix-tests -- templates/tests/nixos/conflicting-modules/auto-cpu-freq_tlp
```

Or from inside the directory:

```bash
nix run github:danielefongo/nix-tests -- .
```

## Run a single test file manually

```bash
nix run github:danielefongo/nix-tests -- conflict/01-both-power-services_test.nix
```

## Test categories

| Prefix | What it checks |
|--------|---------------|
| `conflict/` | Assertion must fire when both `tlp` and `auto-cpufreq` are enabled |
| `positive/` | Each one enabled alone — clean eval, correct enable values |
