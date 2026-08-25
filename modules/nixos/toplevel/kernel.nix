{ delib, pkgs, inputs, ... }:
let
  # Pinned to nixos-26.05 rev 044bfe75bfe4c7bbe043dc17b5e42ea823b84a09
  # (2026-08-12), the last revision where `linuxPackages_latest` resolves to
  # kernel 7.1.8. `nixos-laptop` ONLY - kernel 7.2.0 broke all audio on that
  # host (upstream Kernel Bugzilla #221499). See flake.nix input comment and
  # nix-debugger memory `project_laptop_panther_lake_issues.md` for the full
  # story and the unpin procedure.
  pkgs-laptop-kernel-pin = inputs.nixpkgs-laptop-kernel-pin.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
delib.module {
  name = "kernel";
  nixos.always = { myconfig, ... }: {
    boot.kernelPackages =
      if myconfig.constants.hostname == "nixos-desktop" then
        pkgs.linuxPackages_zen
      else if myconfig.constants.hostname == "nixos-laptop" then
        pkgs-laptop-kernel-pin.linuxPackages_latest
      else if myconfig.constants.hostname == "Krits-MacBook-Pro" then
        pkgs.linuxPackages_latest
      else
        pkgs.linuxPackages;
  };
}
