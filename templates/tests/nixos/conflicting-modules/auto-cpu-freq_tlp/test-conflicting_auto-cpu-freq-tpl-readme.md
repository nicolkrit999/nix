# auto-cpu-freq_tlp

Verifies that `services.tlp` and `services.auto-cpufreq` are mutually exclusive
at eval time — both cannot be enabled in the same host.

Uses [nix-tests](https://github.com/danielefongo/nix-tests) — each `_test.nix`
file evaluates a fake host and asserts on the resulting config (assertions
firing, enable values) without building anything.

## Run all tests

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-conflicting-modules` (name as shown by `--list`).

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

## Checks

| Scenario | Check | Expected |
|----------|-------|----------|
| C01 both | assertion `services.auto-cpufreq and services.tlp are mutually exclusive` fails | true |
| C01 both | number of failing assertions containing "mutually exclusive" | exactly 1 |
| P01 only tlp | specific mutex assertion fails / any "mutually exclusive" assertion fails | false / false |
| P01 only tlp | `services.tlp.enable` / `programs.auto-cpufreq.enable` | true / false |
| P02 only auto-cpufreq | specific mutex assertion fails / any "mutually exclusive" assertion fails | false / false |
| P02 only auto-cpufreq | `programs.auto-cpufreq.enable` / `services.tlp.enable` | true / false |

The positive "no mutex assertion" checks are only meaningful because C01 proves the
same message text is emitted when both are on. The fake host enables nothing else
(thermald was dropped: it was never asserted).
