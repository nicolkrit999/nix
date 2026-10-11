# test-flake-outputs

Locks the output shape of `flake.nix`: structural invariants of which hosts land in which `*Configurations`, that pkgsStable is wired to `nixpkgs-stable`, and that the stable pin is consistent between `flake.nix` and `flake.lock`.

## Run

From the repo root:

```bash
bash templates/tests/common/test-flake-outputs/check-common-flake-outputs.sh
```

From inside the directory:

```bash
bash check-common-flake-outputs.sh
```

## How it works

`01-scenario-flake-outputs.nix` loads the real flake (`builtins.getFlake "path:$FLAKE_ROOT"`) and exposes one `check-*` attribute per check, each evaluating to `"ok"` or `"FAIL: ..."`. The test does not pin the host list (that is a host choice); it only asserts structural invariants, iterating whatever hosts exist, so adding or removing a host does not require editing it. Only the darwin and home-only host names are named, to state their placement rule. pkgsStable is probed through `extendModules` with a module reading the `pkgsStable` and `pkgsStableFor` args. `check-common-flake-outputs.sh` runs `nix eval --raw --impure` per attribute, prints PASS/FAIL per check and exits 1 on any failure. NixOS/home checks return `ok` when `nixosConfigurations` is hidden by the Darwin IFD guard.

## Checks

| Check | Expected |
|-------|----------|
| check-nas-not-in-nixos | Nicol-NAS and Krits-MacBook-Pro are not in `nixosConfigurations` |
| check-home-only-placement | Nicol-NAS has a `krit@Nicol-NAS` homeConfiguration and is not in `darwinConfigurations` |
| check-home-covers-nixos | every `nixosConfigurations` host has a `krit@<host>` homeConfiguration |
| check-home-no-darwin | no `krit@<darwin host>` in `homeConfigurations` |
| check-pkgsstable-nixos-hosts | per NixOS host: `pkgsStableFor` has an entry for the host system and `pkgsStable.path` is the `nixpkgs-stable` input (not main nixpkgs) |
| check-pkgsstable-darwin | same for every darwin host |
| check-pkgsstable-home | every homeConfiguration: `pkgsStable.path` is the `nixpkgs-stable` input |
| check-root-fs-single-definition | every NixOS host has exactly one definition of `fileSystems."/"` (no double hardware-configuration/disko import) |
| check-stable-pin-consistent | `nixpkgs-stable.url` ref in `flake.nix` == `original.ref` of the lock node that `root.inputs.nixpkgs-stable` points to (not the node literally named `nixpkgs-stable`, which may be a transitive input), and `nixpkgs-stable.lib.version` starts with that release number |
