# test-arch-compat

Checks that every module evaluates cleanly on `aarch64-linux`.

Uses `nix build --dry-run` against `home.activationPackage` — this forces Nix to
resolve the full derivation closure without building anything. Any package that
lacks aarch64 support (via `meta.platforms` or missing flake output) throws at
eval time and is reported.

## Run all tests

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-arch-compat` (name as shown by `--list`).

```bash
bash templates/tests/nixos/test-arch-compat/check-nixos-aarch64-compat.sh
```

Or from inside the directory:

```bash
bash check-nixos-aarch64-compat.sh
```

Add `--fast` to skip the 8 specialisation batches and only run the 2 base ones:

```bash
bash check-nixos-aarch64-compat.sh --fast
```

## Run a single batch manually

```bash
nix build --dry-run --no-link --impure \
  --file templates/tests/nixos/test-arch-compat/scenario-auto-cpufreq-sddm-astronaut.nix \
  all-modules-auto-cpufreq-sddm-astronaut
```

Available attributes per scenario file:

**`scenario-auto-cpufreq-sddm-astronaut.nix`**
- `all-modules-auto-cpufreq-sddm-astronaut`
- `specialisation-deep-focus-auto-cpufreq`
- `specialisation-guest-auto-cpufreq`
- `specialisation-safe-mode-auto-cpufreq`
- `specialisation-secure-travel-auto-cpufreq`

**`scenario-tlp-sddm-pixie.nix`**
- `all-modules-tlp-sddm-pixie`
- `specialisation-deep-focus-tlp`
- `specialisation-guest-tlp`
- `specialisation-safe-mode-tlp`
- `specialisation-secure-travel-tlp`

## Value checks

Each scenario also exposes a `checks` attrset (`"ok"` / `"FAIL: ..."`), run by the script
via `nix eval --raw --impure --file <scenario> checks.<name>` for both scenarios. The fake
hosts deliberately enable every module (that is the point of this test); no check asserts
which programs a host enables.

| Check | Expected |
|-------|----------|
| `hostPlatformIsAarch64` | `nixpkgs.hostPlatform` and the HM `activationPackage.system` are `aarch64-linux` (guards against every dry-build being vacuously x86) |
| `x86OnlyPackageIsRejected` | negative control: an `x86_64-linux`-only package fails `tryEval` on aarch64, proving `meta.platforms` is enforced |
| `shellsInertOnAarch64` | with caelestia and noctalia enabled, `myconfig.programs.hyprland.execOnce` has no noctalia/caelestia entry (the `isx86_64` gating works) |
| `specialisationNames` | `deep-focus`, `guest`, `safemode`, `secure-travel` all exist as specialisations (the dry-build attrs rely on these names) |

The former "expected incompatibility" path (`EXPECTED_DIRECT_MODULES`) was dead code and was removed.
