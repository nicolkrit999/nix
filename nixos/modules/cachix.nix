{
  config,
  pkgs,
  lib,
  vars,
  ...
}:

let
# Cachix is forcibly disabled regardless of the host variable
# This allow to have a stable branch where flake.lock can be anything
  cfg = {
    enable = false; 
    push = false;
    name = "";
    publicKey = "";
  };

  # Path to host-specific secrets
  sopsFilePath = ../../hosts/${vars.hostname}/optional/host-sops-nix/${vars.hostname}-secrets-sops.yaml;
  sopsFile = if builtins.pathExists sopsFilePath then sopsFilePath else null;

in
{
  config =
    lib.mkIf (cfg.enable or false) {
      nix.settings = {
        substituters = [ "https://${cfg.name}.cachix.org" ];
        trusted-public-keys = [ cfg.publicKey ];
      };
      environment.systemPackages = [ pkgs.cachix ];
    }
    // lib.mkIf ((cfg.enable or false) && (cfg.push or false) && (sopsFile != null)) {
      sops.secrets."cachix-auth-token" = {
        inherit sopsFile;
        mode = "0440";
        owner = vars.user;
        group = "wheel";
      };

      environment.shellAliases = {
        rebuild-push = "export CACHIX_AUTH_TOKEN=$(cat ${
          config.sops.secrets."cachix-auth-token".path
        }) && sudo nixos-rebuild switch --flake . && nix path-info -r /run/current-system | cachix push ${cfg.name}";
      };

      environment.systemPackages = [ pkgs.cachix ];
    };
}
