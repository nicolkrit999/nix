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

## Harness (`*_test.nix`) fakes: no IFD

nix-tests evaluates read-only (`nix-instantiate --eval`), so reading a file out of
a built package during eval fails on a fresh CI runner ("... .drv is not valid")
while passing on a machine whose store is warm. Never point a fake at
`${pkgs.<pkg>}/...` for data read at eval time; use an inline value (stylix:
`import <rel>/templates/tests/lib/scheme-catppuccin-mocha.nix`). `run-test.py`
sets `allow-import-from-derivation = false` for harness commands to catch this
locally. Likewise never `readFile (unsafeDiscardStringContext <drv output>)`
in bash scenarios: it only works where the path was already built.

## Tests must not depend on store state

A test has to pass on an empty store (fresh CI runner). Never
`readFile (unsafeDiscardStringContext <output or .drv>)`: outputs are never built
on a fresh store, and Determinate Nix writes `.drv` files asynchronously, so a
context-less `.drv` read races. Keep the context instead: read a `.drv` with
`builtins.appendContext d { ${d} = { path = true; }; }` (waits for the write, builds
nothing), or use the derivation's `.text` attribute. Avoid `readFile` of an
output even with its context kept: Nix realises it AND every store path the
script interpolates (`universal-lock` -> `noctalia`, built from source on CI).
Context-discarding is fine for pure string comparison, not for reads.

Fresh-store check (a green run on the dev machine proves nothing):

```bash
S=$HOME/momentary/fresh-store-<name>; rm -rf "$S"; mkdir -p "$S" "$S-cache"
XDG_CACHE_HOME="$S-cache" NIX_REMOTE="local?root=$S" \
  bash templates/tests/run-tests.sh --only <name>
```

Use a directory outside `/tmp` (4 GB tmpfs); expect substituter downloads.
A CI-like repro must also restrict substituters to CI's set (add
`NIX_CONFIG=$'substituters = https://cache.nixos.org https://catppuccin.cachix.org https://krit-nixos.cachix.org\ntrusted-public-keys = <keys from tests-nixos.yml + cache.nixos.org>'`):
the desktop's NAS/attic and extra cachix caches hide builds that time out in CI.

A harness test that fails with libgit2 `object not found` / `invalid object
specified` while fetching a `github:` input is the upstream tarball-cache race,
not the test: run-test.py's input warm-up (`discover.NIX_TESTS_WARM`) prevents
it. Keep that warm-up when changing how harness commands run
(build-workflows.md §12.9).

## Script conventions

- `check-*.sh` source `templates/tests/lib/evidence.sh` near the top:
  `source "$(dirname "${BASH_SOURCE[0]}")/../../lib/evidence.sh"` (adjust depth).
- Scenario `.nix` exposes results as strings `"ok"` / `"FAIL: ..."`; the script
  runs `nix eval --raw --impure` per attribute and prints a pass/fail table.
- Exit non-zero on any failure; keep tests deterministic.
- Default to no code comments; the readme explains what/why/how.
- Adding, removing or renaming a check (or its control) changes the readme's
  `## Checks` table and possibly the overview row: run the "Docs sync" in `./SKILL.md`.
- Tests read the real current config, so they verify a later fix without a rebuild.
