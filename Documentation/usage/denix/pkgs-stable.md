# Pinning a package to the stable nixpkgs (`pkgsStable`)

The config tracks `nixos-unstable`. A second, permanent input, `nixpkgs-stable` (`github:nixos/nixpkgs/nixos-26.05` in `flake.nix`), exists so a single package can be pinned to a release branch when unstable breaks it. No package uses it at the moment; the input and the plumbing stay defined on purpose so a pin is a one-line change.

## How it is exposed

- `flake.nix` builds `pkgsStableFor`, an attrset keyed by system, from `inputs.nixpkgs-stable` with `allowUnfree = true`.
- A module added through `extraModules` sets `_module.args.pkgsStable` to the entry matching the host's own `pkgs.stdenv.hostPlatform.system`. It is evaluated lazily, so the stable nixpkgs is only imported when something actually uses `pkgsStable`.
- It is available as a module argument on NixOS, on Darwin, and inside home-manager modules (passed through `home-manager.sharedModules`; standalone home mode defines it directly).
- `pkgsStableFor` is also in `specialArgs` for code that needs another system's set.

## Pinning a package

Take `pkgsStable` as an argument of the outer module function (not inside an `ifEnabled` block, which only receives `cfg`/`myconfig`) and use it instead of `pkgs`:

```nix
{ delib, pkgs, pkgsStable, ... }:
delib.module {
  name = "programs.example";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgsStable.example ];
  };
}
```

A pinned package must be recorded with its reason and the condition for dropping the pin, so it does not stay pinned forever.

## Updating

`nix flake update nixpkgs-stable` moves only the stable input. Changing which release branch it follows means editing its URL in `flake.nix`; never touch `stateVersion` when doing so.
