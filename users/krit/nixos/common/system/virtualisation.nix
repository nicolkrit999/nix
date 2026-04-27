{ delib, pkgs, lib, inputs, ... }:
delib.module {
  name = "krit.system.virtualisation";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    let
      # Pinned nixpkgs for winboat — Electron 41.2.0 in newer nixpkgs breaks node-abi.
      # REMOVE THIS (and the flake input) when winboat builds on current nixpkgs again.
      # Last re-test: 2026-04-27 — still broken.
      pkgs-winboat = import inputs.nixpkgs-winboat { system = pkgs.stdenv.hostPlatform.system; };
    in
    {
      virtualisation.docker.enable = true;
      virtualisation.docker.daemon.settings."mtu" = 1450;
      virtualisation.podman = {
        enable = true;
        dockerCompat = false;
      };

      environment.systemPackages = with pkgs; [
        distrobox
      ] ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        pkgs-winboat.winboat # Pinned to older nixpkgs until Electron 41 abi is supported
      ];
    };

  # Distrobox exports binaries to ~/.distrobox-bin
  home.ifEnabled = { ... }: {
    home.sessionPath = [ "$HOME/.distrobox-bin" ];
  };
}
