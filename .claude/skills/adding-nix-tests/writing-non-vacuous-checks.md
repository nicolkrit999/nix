# Writing non-vacuous checks

A check that cannot fail is worse than no check. Before finishing a test, answer
for each check: "what config change would turn this red?"

## What is worth testing

- Conflicting modules (two modules that must not be enabled together).
- Specialisation purpose contracts (what a specialisation forces, e.g. the
  secure-travel lockdown actually lands).
- Host safety values: boot, impermanence, sops wiring, stateVersion freeze.
- Cross-file consistency (two files that must agree: monitor layouts, screenshot
  folder, option names used by a script vs the module).

NOT worth testing: whether a host enables a given program, WM, DE or kernel.
That is a choice, not an invariant.

## Fake hosts

Enable only what the test needs. Extra enabled modules slow evaluation and make
failures unrelated to the property under test. Exception: `test-arch-compat`
enables every module on purpose.

## Controls and negative scenarios

- Control: each assertion about a forced value also FAILs if the base config
  already had that value (`test-spec-contract` does this), so an override that
  changes nothing cannot pass.
- Negative scenario: build a deliberately broken variant (conflict enabled, value
  removed) and assert the check reports FAIL for it. Mutation-style tests such as
  `common/test-test-infra` show the pattern.
- Guard against empty input: if a check iterates over a list (files, options,
  hosts), assert the list is non-empty, otherwise a typo makes it pass over nothing.
- Prefer exact comparisons to substring greps that can match comments.

## Public repo: no secrets

- Never hardcode keys, fingerprints, tokens, host keys. Compare config values with
  each other (e.g. the pin in file A equals the value in file B) or parse the
  value at test time from the real file.
- Never `cat`/`readFile` anything under `/run/secrets`, `~/.config/sops` or
  `secrets/*.yaml`, and never dump whole config subtrees to stderr: whatever a
  test prints lands in CI artifacts and on Discord.

## Script conventions

- `check-*.sh` source `templates/tests/lib/evidence.sh` near the top:
  `source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"` (adjust depth).
- Scenario `.nix` exposes results as strings `"ok"` / `"FAIL: ..."`; the script
  runs `nix eval --raw --impure` per attribute and prints a pass/fail table.
- Exit non-zero on any failure; keep tests deterministic.
- Default to no code comments; the readme explains what/why/how.
- Tests read the real current config, so they verify a later fix without a rebuild.
