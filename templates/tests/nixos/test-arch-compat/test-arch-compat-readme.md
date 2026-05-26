# test-arch-compat

Checks that every module evaluates cleanly on `aarch64-linux`.

Uses `nix build --dry-run` against `home.activationPackage` — this forces Nix to
resolve the full derivation closure without building anything. Any package that
lacks aarch64 support (via `meta.platforms` or missing flake output) throws at
eval time and is reported.

## Run all tests

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
