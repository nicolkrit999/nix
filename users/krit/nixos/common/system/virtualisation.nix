{ delib, pkgs, lib, inputs, ... }:
delib.module {
  name = "krit.system.virtualisation";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    let
      # Pinned nixpkgs for winboat — Electron 41.x in newer nixpkgs breaks node-abi.
      # REMOVE THIS (and the flake input) when winboat builds on current nixpkgs again.
      # Re-tests: 2026-04-27 (41.2.0 broken), 2026-04-27 round 2 (41.3.0 still broken).
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
