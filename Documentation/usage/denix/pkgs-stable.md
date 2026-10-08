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

## Limits and risks

The pinned package comes from an older nixpkgs than the rest of the system, which is the point of a pin, but it only stays safe for self-contained packages.

- **Safe:** leaf command-line tools and standalone apps. They bring their own libraries (including their own `glibc`) from the stable set, so nothing collides; the cost is a larger closure.
- **Risky:** anything that shares an interface with the system.
  - OpenGL/Vulkan apps: host drivers built against a newer `glibc` can fail to load in an app linked against an older one.
  - Qt, KDE, GTK, GStreamer, PAM and NSS plugins, and input methods must match the program's own version.
  - Daemons that talk to unstable services over D-Bus or sockets can hit protocol drift.
  - Home-manager writes config for the module's own version of a program; an older pinned program may not understand it.
  - Python environments mixing stable and unstable packages can break on compiled parts.
- **Never pin:** kernel modules or drivers (they must match the running kernel), libraries, desktop frameworks.
- **Overlays:** the repo's overlays apply only to the main `pkgs`, not to `pkgsStable`.
- **Keep the gap small:** a stable pin only receives security backports. Bump `nixpkgs-stable` once per release so it never falls two releases behind, and give every pin a drop condition.

## Updating

`nix flake update nixpkgs-stable` moves only the stable input. Changing which release branch it follows means editing its URL in `flake.nix`; never touch `stateVersion` when doing so.
